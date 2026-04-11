'use strict';

/**
 * transport.js
 *
 * MIDI I/O: port discovery, send, receive.
 * No Electra One protocol knowledge here — just byte transport.
 *
 * Two important fixes vs v1:
 *
 * 1. CoreMIDI -304 (kMIDIClientCreateErr)
 *    Each `new midi.Input()` registers a CoreMIDI client. Creating multiple
 *    instances in quick succession (once for enumeration, once for I/O) exceeds
 *    macOS's per-process budget. Fix: one shared Input/Output pair for the
 *    entire process lifetime, used for both enumeration and communication.
 *
 * 2. SysEx fragmentation → truncated JSON
 *    Large presets arrive in multiple `message` events on macOS CoreMIDI.
 *    node-midi does NOT stitch them for you. Fix: accumulate bytes across
 *    events until we see EOX (0xF7) before classifying.
 */

const midi    = require('midi');
const { classify, SOX, EOX } = require('./protocol');

// ── Shared MIDI client (singleton) ────────────────────────────────────────────

let _input  = null;
let _output = null;

/**
 * Return the shared Input/Output pair, creating it on first call.
 * Reusing these objects avoids registering multiple CoreMIDI clients.
 */
function getShared() {
  if (!_input) {
    _input  = new midi.Input();
    _output = new midi.Output();
    _input.ignoreTypes(false, false, false); // never filter SysEx
  }
  return { input: _input, output: _output };
}

// ── Port enumeration ──────────────────────────────────────────────────────────

/**
 * List all available MIDI port names.
 * Uses the shared MIDI objects — no extra CoreMIDI clients created.
 * @returns {{ inputs: string[], outputs: string[] }}
 */
function listAllPorts() {
  const { input, output } = getShared();
  const inputs  = Array.from({ length: input.getPortCount()  }, (_, i) => input.getPortName(i));
  const outputs = Array.from({ length: output.getPortCount() }, (_, i) => output.getPortName(i));
  return { inputs, outputs };
}

/**
 * Score a port name for likelihood of being the Electra One CTRL port.
 * Higher is better; -1 = not E1.
 * @param {string} name
 * @returns {number}
 */
function scorePort(name) {
  if (!name.includes('Electra')) return -1;
  if (name.includes('CTRL'))     return 3;  // preferred management port
  if (name.includes('PORT 3'))   return 2;  // Linux alias
  if (name.includes('MIDIIN3'))  return 2;  // Windows alias
  return 1;
}

/**
 * Find the best Electra One input and output port indices.
 * @returns {{ inputPort: number, outputPort: number, inputName: string|null, outputName: string|null }}
 */
function findE1Ports() {
  const { inputs, outputs } = listAllPorts();
  const best = (names) =>
    names.reduce((b, name, i) => scorePort(name) > scorePort(names[b] ?? '') ? i : b, -1);

  const inputPort  = best(inputs);
  const outputPort = best(outputs);
  return {
    inputPort,
    outputPort,
    inputName:  inputs[inputPort]   ?? null,
    outputName: outputs[outputPort] ?? null,
  };
}

// ── Port lifecycle ────────────────────────────────────────────────────────────

/**
 * Open the E1 ports, run an async operation, then always close them.
 *
 * @template T
 * @param {(session: { input: midi.Input, output: midi.Output }) => Promise<T>} fn
 * @returns {Promise<T>}
 */
async function withPorts(fn) {
  const { inputPort, outputPort, inputName, outputName } = findE1Ports();
  if (inputPort === -1 || outputPort === -1) {
    throw new Error(
      'Electra One not found — is it plugged in?\n' +
      'Run `e1 ports` to list available MIDI ports.'
    );
  }

  const { input, output } = getShared();

  try {
    input.openPort(inputPort);
    output.openPort(outputPort);
    return await fn({ input, output, inputName, outputName });
  } finally {
    try { input.closePort();  } catch {}
    try { output.closePort(); } catch {}
  }
}

// ── SysEx accumulator ─────────────────────────────────────────────────────────

/**
 * Create a stateful accumulator that reassembles fragmented SysEx messages.
 *
 * CoreMIDI can split large SysEx payloads across multiple `message` events.
 * Each call to feed(bytes) appends to an internal buffer. When EOX (0xF7) is
 * seen, feed returns the complete assembled message and resets. Returns null
 * while still accumulating.
 *
 * @returns {(bytes: number[]) => number[]|null}
 */
function makeSysExAccumulator() {
  let buf = [];
  return function feed(bytes) {
    if (bytes[0] === SOX) {
      buf = [...bytes];           // new message — reset
    } else if (buf.length > 0) {
      buf = buf.concat(bytes);    // continuation fragment
    } else {
      return null;                // non-SysEx with no active buffer — ignore
    }

    if (buf[buf.length - 1] === EOX) {
      const complete = buf;
      buf = [];
      return complete;
    }

    return null; // still accumulating
  };
}

// ── Send and receive ──────────────────────────────────────────────────────────

/**
 * Send a SysEx message and wait for a complete data response.
 * Handles fragmented responses transparently via the accumulator.
 *
 * @param {number[]} msgBytes
 * @param {object}  [opts]
 * @param {number}  [opts.timeoutMs=6000]
 * @returns {Promise<{ resource: number, payload: number[] }>}
 */
function query(msgBytes, { timeoutMs = 6000 } = {}) {
  return withPorts(({ input, output }) =>
    new Promise((resolve, reject) => {
      let settled = false;
      let timer;
      const feed = makeSysExAccumulator();

      const settle = (err, result) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        input.removeAllListeners('message');
        if (err) reject(err); else resolve(result);
      };

      input.on('message', (_dt, msg) => {
        const complete = feed(Array.from(msg));
        if (!complete) return; // still accumulating

        const parsed = classify(complete);
        if (parsed.type === 'data') {
          settle(null, { resource: parsed.resource, payload: parsed.payload });
        }
      });

      timer = setTimeout(
        () => settle(new Error('Timeout — device did not respond')),
        timeoutMs
      );

      output.sendMessage(msgBytes);
    })
  );
}

/**
 * Send a SysEx command and wait for ACK or NACK.
 * Resolves on ACK, rejects on NACK or timeout.
 *
 * @param {number[]} msgBytes
 * @param {object}  [opts]
 * @param {number}  [opts.timeoutMs=6000]
 * @returns {Promise<void>}
 */
function command(msgBytes, { timeoutMs = 6000 } = {}) {
  return withPorts(({ input, output }) =>
    new Promise((resolve, reject) => {
      let settled = false;
      let timer;
      const feed = makeSysExAccumulator();

      const settle = (err) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        input.removeAllListeners('message');
        if (err) reject(err); else resolve();
      };

      input.on('message', (_dt, msg) => {
        const complete = feed(Array.from(msg));
        if (!complete) return;

        const parsed = classify(complete);
        if (parsed.type === 'ack')  settle(null);
        if (parsed.type === 'nack') settle(new Error('NACK — device rejected the command'));
      });

      timer = setTimeout(
        () => settle(new Error('Timeout — no ACK from device')),
        timeoutMs
      );

      output.sendMessage(msgBytes);
    })
  );
}

module.exports = { listAllPorts, findE1Ports, query, command };
