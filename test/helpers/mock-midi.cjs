'use strict';

/**
 * mock-midi.cjs
 *
 * A drop-in replacement for the `midi` package that simulates a USB-attached
 * Electra One, for end-to-end CLI tests with no hardware.
 *
 * Load it with `node --require test/helpers/mock-midi.cjs bin/e1.js …`:
 * it hooks Module._load so any `require('midi')` in the process gets the
 * mock instead of the real CoreMIDI binding.
 *
 * Simulated device behavior (mirrors the real protocol):
 *   - one input/output port pair named "Electra Controller Electra CTRL"
 *   - info request (0x02 0x7F)        → canned DeviceInfo JSON
 *   - preset request (0x02 0x01 b s)  → canned preset for occupied slots,
 *                                       zero-length data response otherwise
 *   - lua request (0x02 0x0C b s)     → canned source for slots with a script
 *   - uploads / slot ops (0x01, 0x05, 0x09, 0x14) → 0x7E status then ACK
 *
 * Configuration via environment variables:
 *   E1_MOCK_SLOTS     JSON: { "0:1": {"name": "Bass", ...preset}, ... }
 *                     (defaults to one preset in bank 0 slot 1)
 *   E1_MOCK_LUA       JSON: { "0:1": "print('hi')" }
 *   E1_MOCK_LOG       path: every SysEx frame the "device" receives is
 *                     appended as a JSON array per line (for asserting on
 *                     exact bytes/opcodes sent by the CLI)
 *   E1_MOCK_FRAGMENT  if set, data responses are delivered split across
 *                     multiple 'message' events (exercises reassembly)
 *   E1_MOCK_SILENT    if set, the device never answers (timeout testing)
 */

const Module = require('module');
const fs = require('fs');

const SOX = 0xF0, EOX = 0xF7;
const MANUFACTURER = [0x00, 0x21, 0x45];

const DEFAULT_INFO = {
  versionText: '3.7.1', versionSeq: 30701, serial: 'MOCK0001',
  hwRevision: '2.4', model: 'mk2', modelNum: 2,
};

const DEFAULT_SLOTS = {
  '0:1': {
    version: 2,
    name: 'Mock Preset',
    projectId: 'mockProject000000000',
    pages: [{ id: 1, name: 'Page 1' }],
    devices: [{ id: 1, name: 'MIDI Device 1', port: 1, channel: 1 }],
    controls: [{
      id: 1, type: 'fader', visible: true, name: 'CC #1', color: 'F49500',
      bounds: [20, 36, 175, 122], pageId: 1, controlSetId: 1,
      inputs: [{ potId: 1, valueId: 'value' }],
      values: [{ id: 'value', message: { type: 'cc7', parameterNumber: 1, deviceId: 1, min: 0, max: 127 } }],
    }],
  },
};

const slots = process.env.E1_MOCK_SLOTS ? JSON.parse(process.env.E1_MOCK_SLOTS) : DEFAULT_SLOTS;
const luaBySlot = process.env.E1_MOCK_LUA ? JSON.parse(process.env.E1_MOCK_LUA) : {};

function logFrame(bytes) {
  if (process.env.E1_MOCK_LOG) {
    fs.appendFileSync(process.env.E1_MOCK_LOG, JSON.stringify(bytes) + '\n');
  }
}

const ascii = (str) => Array.from(Buffer.from(str, 'ascii'));

// ── The virtual device ────────────────────────────────────────────────────────

let messageListener = null; // the Input's 'message' callback

/** Deliver a complete SysEx message to the listener, optionally fragmented. */
function deliver(bytes) {
  if (!messageListener) return;
  const send = (chunk) => setImmediate(() => {
    if (messageListener) messageListener(0, chunk);
  });
  if (process.env.E1_MOCK_FRAGMENT && bytes.length > 8) {
    const mid = Math.floor(bytes.length / 3);
    send(bytes.slice(0, mid));
    send(bytes.slice(mid, mid * 2));
    send(bytes.slice(mid * 2));
  } else {
    send(bytes);
  }
}

const frame = (...body) => [SOX, ...MANUFACTURER, ...body, EOX];
const dataResponse = (resource, payload) => frame(0x01, resource, ...payload);
const status = (code) => frame(0x7E, code);
const ack = () => frame(0x7E, 0x01);

/** Handle one SysEx frame arriving at the "device". */
function handleFrame(bytes) {
  logFrame(bytes);
  if (process.env.E1_MOCK_SILENT) return;

  if (bytes[0] !== SOX || bytes[1] !== 0x00 || bytes[2] !== 0x21 || bytes[3] !== 0x45) return;
  const op = bytes[4];
  const res = bytes[5];

  if (op === 0x02) { // request
    if (res === 0x7F) return deliver(dataResponse(0x7F, ascii(JSON.stringify(DEFAULT_INFO))));
    const key = `${bytes[6]}:${bytes[7]}`;
    if (res === 0x01) {
      const preset = slots[key];
      return deliver(dataResponse(0x01, preset ? ascii(JSON.stringify(preset)) : []));
    }
    if (res === 0x0C) {
      const lua = luaBySlot[key];
      return deliver(dataResponse(0x0C, lua ? ascii(lua) : []));
    }
    return;
  }

  if (op === 0x01 || op === 0x05 || op === 0x09 || op === 0x14) {
    // Upload / clear / switch / select: a 0x05 notification first, then the
    // real ACK — mirrors observed hardware behavior (see lib/protocol.js).
    deliver(status(0x05));
    deliver(ack());
  }
}

// ── midi-compatible classes ───────────────────────────────────────────────────

const PORT_NAME = 'Electra Controller Electra CTRL';

class Input {
  getPortCount() { return 1; }
  getPortName(i) { return i === 0 ? PORT_NAME : ''; }
  ignoreTypes() {}
  openPort() {}
  closePort() { messageListener = null; }
  on(event, cb) { if (event === 'message') messageListener = cb; }
  removeAllListeners(event) { if (!event || event === 'message') messageListener = null; }
}

class Output {
  getPortCount() { return 1; }
  getPortName(i) { return i === 0 ? PORT_NAME : ''; }
  openPort() {}
  closePort() {}
  sendMessage(bytes) { handleFrame(Array.from(bytes)); }
}

// ── require() hook ────────────────────────────────────────────────────────────

const realLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'midi') return { Input, Output };
  return realLoad.apply(this, arguments);
};
