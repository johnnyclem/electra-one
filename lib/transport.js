'use strict';

const midi    = require('midi');
const { classify } = require('./protocol');

function listAllPorts() {
  const inp = new midi.Input();
  const out = new midi.Output();
  const inputs  = Array.from({ length: inp.getPortCount() }, (_, i) => inp.getPortName(i));
  const outputs = Array.from({ length: out.getPortCount() }, (_, i) => out.getPortName(i));
  inp.closePort();
  out.closePort();
  return { inputs, outputs };
}

function scorePort(name) {
  if (!name.includes('Electra')) return -1;
  if (name.includes('CTRL'))     return 3;
  if (name.includes('PORT 3'))   return 2;  // Linux
  if (name.includes('MIDIIN3'))  return 2;  // Windows
  return 1;
}

function findE1Ports() {
  const { inputs, outputs } = listAllPorts();
  const best = (names) =>
    names.reduce((b, name, i) => scorePort(name) > scorePort(names[b] ?? '') ? i : b, -1);
  const inputPort  = best(inputs);
  const outputPort = best(outputs);
  return { inputPort, outputPort, inputName: inputs[inputPort] ?? null, outputName: outputs[outputPort] ?? null };
}

async function withPorts(fn) {
  const { inputPort, outputPort, inputName, outputName } = findE1Ports();
  if (inputPort === -1 || outputPort === -1) {
    throw new Error('Electra One not found. Is it plugged in?\nRun `e1 ports` to see all MIDI ports.');
  }
  const input  = new midi.Input();
  const output = new midi.Output();
  input.ignoreTypes(false, false, false);
  try {
    input.openPort(inputPort);
    output.openPort(outputPort);
    return await fn({ input, output, inputName, outputName });
  } finally {
    try { input.closePort();  } catch {}
    try { output.closePort(); } catch {}
  }
}

function query(msgBytes, { timeoutMs = 6000 } = {}) {
  return withPorts(({ input, output }) =>
    new Promise((resolve, reject) => {
      let settled = false;
      let timer;
      const settle = (err, result) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        if (err) reject(err); else resolve(result);
      };
      input.on('message', (_dt, msg) => {
        const parsed = classify(msg);
        if (parsed.type === 'data') settle(null, { resource: parsed.resource, payload: parsed.payload });
      });
      timer = setTimeout(() => settle(new Error('Timeout — device did not respond')), timeoutMs);
      output.sendMessage(msgBytes);
    })
  );
}

function command(msgBytes, { timeoutMs = 6000 } = {}) {
  return withPorts(({ input, output }) =>
    new Promise((resolve, reject) => {
      let settled = false;
      let timer;
      const settle = (err) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        if (err) reject(err); else resolve();
      };
      input.on('message', (_dt, msg) => {
        const parsed = classify(msg);
        if (parsed.type === 'ack')  settle(null);
        if (parsed.type === 'nack') settle(new Error('NACK — device rejected the command'));
      });
      timer = setTimeout(() => settle(new Error('Timeout — no ACK from device')), timeoutMs);
      output.sendMessage(msgBytes);
    })
  );
}

module.exports = { listAllPorts, findE1Ports, query, command };
