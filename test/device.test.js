'use strict';

const { test, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const proto     = require('../lib/protocol');
const transport = require('../lib/transport');
const device    = require('../lib/device');

// ── Mock transport ───────────────────────────────────────────────────────────
//
// device.js resolves `transport.query`/`.command` at call time, so swapping the
// singleton's methods lets us drive the high-level ops with canned responses and
// assert on exactly what bytes would go out — no MIDI hardware involved.

const realQuery = transport.query;
const realCommand = transport.command;
let calls;

/** Encode an object/string as the byte payload the device would return. */
const payloadOf = (data) =>
  Array.from(Buffer.from(typeof data === 'string' ? data : JSON.stringify(data), 'ascii'));

beforeEach(() => {
  calls = { query: [], command: [] };
  // Default: every query resolves to an empty payload, every command ACKs.
  transport.query = async (msg, opts) => {
    calls.query.push({ msg, opts });
    return { resource: msg[5], payload: [] };
  };
  transport.command = async (msg, opts) => {
    calls.command.push({ msg, opts });
  };
});

afterEach(() => {
  transport.query = realQuery;
  transport.command = realCommand;
});

/** Make queries answer with the given payload (object|string|byte[]). */
function respondWith(data) {
  transport.query = async (msg, opts) => {
    calls.query.push({ msg, opts });
    return { resource: msg[5], payload: Array.isArray(data) ? data : payloadOf(data) };
  };
}

// ── getInfo ──────────────────────────────────────────────────────────────────

test('getInfo sends an info request and decodes the JSON response', async () => {
  respondWith({ model: 'mk2', serial: 'ABC', versionText: '3.7' });
  const info = await device.getInfo();
  assert.deepEqual(calls.query[0].msg, proto.infoRequest());
  assert.equal(info.model, 'mk2');
  assert.equal(info.serial, 'ABC');
});

// ── getPreset ────────────────────────────────────────────────────────────────

test('getPreset (active slot) sends a bare preset request', async () => {
  respondWith({ name: 'P', controls: [] });
  const p = await device.getPreset();
  assert.deepEqual(calls.query[0].msg, proto.presetRequest());
  assert.equal(p.name, 'P');
});

test('getPreset with bank/slot targets that slot', async () => {
  respondWith({ name: 'P', controls: [] });
  await device.getPreset({ bank: 2, slot: 3 });
  assert.deepEqual(calls.query[0].msg, proto.presetRequest(2, 3));
});

test('getPreset throws EmptySlotError on a zero-length payload', async () => {
  // default mock returns an empty payload
  await assert.rejects(() => device.getPreset({ bank: 0, slot: 0 }), (e) => {
    assert.ok(e instanceof device.EmptySlotError);
    assert.equal(e.empty, true);
    return true;
  });
});

// ── parseSlot validation (exercised through getPreset) ───────────────────────

test('bank without slot is rejected', async () => {
  await assert.rejects(() => device.getPreset({ bank: 1 }), /must be used together/);
});

test('slot without bank is rejected', async () => {
  await assert.rejects(() => device.getPreset({ slot: 1 }), /must be used together/);
});

test('out-of-range bank/slot are rejected', async () => {
  // The hardware has 6 banks × 12 slots.
  await assert.rejects(() => device.getPreset({ bank: 6, slot: 0 }), /--bank must be 0–5/);
  await assert.rejects(() => device.getPreset({ bank: 0, slot: 12 }), /--slot must be 0–11/);
  await assert.rejects(() => device.getPreset({ bank: -1, slot: 0 }), /--bank must be 0–5/);
});

test('bank/slot given as numeric strings are parsed', async () => {
  respondWith({ name: 'P', controls: [] });
  await device.getPreset({ bank: '1', slot: '4' });
  assert.deepEqual(calls.query[0].msg, proto.presetRequest(1, 4));
});

// ── putPreset ────────────────────────────────────────────────────────────────

test('putPreset to a specific slot arms it, then uploads', async () => {
  const preset = { name: 'X', controls: [{ id: 1 }] };
  await device.putPreset(preset, { bank: 1, slot: 2 });
  assert.equal(calls.command.length, 2);
  assert.deepEqual(calls.command[0].msg, proto.presetSlotSelect(1, 2), 'arms slot first');
  assert.deepEqual(calls.command[1].msg, proto.presetUpload(JSON.stringify(preset)), 'then uploads');
});

test('putPreset to the active slot uploads without arming', async () => {
  await device.putPreset({ name: 'X', controls: [] });
  assert.equal(calls.command.length, 1);
  assert.equal(calls.command[0].msg[4], proto.OP.UPLOAD);
});

test('putPreset rejects a non-object preset', async () => {
  await assert.rejects(() => device.putPreset('nope'), /preset must be an object/);
  await assert.rejects(() => device.putPreset(null), /preset must be an object/);
});

// ── Lua ──────────────────────────────────────────────────────────────────────

test('getLua returns decoded source text', async () => {
  respondWith('function onReady() end');
  const lua = await device.getLua({ bank: 0, slot: 1 });
  assert.deepEqual(calls.query[0].msg, proto.luaRequest(0, 1));
  assert.equal(lua, 'function onReady() end');
});

test('putLua to a slot arms it, then uploads the source', async () => {
  await device.putLua('print(1)', { bank: 3, slot: 4 });
  assert.deepEqual(calls.command[0].msg, proto.presetSlotSelect(3, 4));
  assert.deepEqual(calls.command[1].msg, proto.luaUpload('print(1)'));
});

test('putLua rejects a non-string script', async () => {
  await assert.rejects(() => device.putLua(123), /luaStr must be a string/);
});

// ── file helpers ─────────────────────────────────────────────────────────────

function tmpDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'e1-test-'));
}

test('pushLuaFromFile reads a file and uploads it', async () => {
  const dir = tmpDir();
  const file = path.join(dir, 's.lua');
  fs.writeFileSync(file, 'print("hi")');
  const src = await device.pushLuaFromFile(file, { bank: 0, slot: 0 });
  assert.equal(src, 'print("hi")');
  assert.deepEqual(calls.command.at(-1).msg, proto.luaUpload('print("hi")'));
});

test('pushLuaFromFile rejects a missing file', async () => {
  await assert.rejects(() => device.pushLuaFromFile('/no/such/file.lua'), /Cannot read file/);
});

test('pushLuaFromFile rejects an empty file', async () => {
  const dir = tmpDir();
  const file = path.join(dir, 'empty.lua');
  fs.writeFileSync(file, '   \n');
  await assert.rejects(() => device.pushLuaFromFile(file), /Lua file is empty/);
});

test('pushPresetFromFile validates JSON structure before sending', async () => {
  const dir = tmpDir();
  const bad = path.join(dir, 'bad.json');
  fs.writeFileSync(bad, '{ not json');
  await assert.rejects(() => device.pushPresetFromFile(bad), /Invalid JSON/);

  const notPreset = path.join(dir, 'x.json');
  fs.writeFileSync(notPreset, '{"foo":1}');
  await assert.rejects(() => device.pushPresetFromFile(notPreset), /does not look like an Electra One preset/);
  assert.equal(calls.command.length, 0, 'nothing sent when validation fails');
});

test('pushPresetFromFile uploads a valid preset file', async () => {
  const dir = tmpDir();
  const file = path.join(dir, 'ok.json');
  const preset = { name: 'Good', controls: [{ id: 1 }] };
  fs.writeFileSync(file, JSON.stringify(preset));
  const out = await device.pushPresetFromFile(file, { bank: 0, slot: 5 });
  assert.equal(out.name, 'Good');
  assert.deepEqual(calls.command[0].msg, proto.presetSlotSelect(0, 5));
});

test('pullPresetToFile writes the preset and derives a safe filename', async () => {
  respondWith({ name: 'My/Cool Preset!', controls: [] });
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);
  try {
    const { outFile } = await device.pullPresetToFile();
    assert.ok(fs.existsSync(outFile));
    assert.match(path.basename(outFile), /^My_Cool_Preset_\.json$/);
    const written = JSON.parse(fs.readFileSync(outFile, 'utf8'));
    assert.equal(written.name, 'My/Cool Preset!');
  } finally {
    process.chdir(cwd);
  }
});

// ── scanSlots ────────────────────────────────────────────────────────────────

test('scanSlots classifies ok / empty / error per slot', async () => {
  // slot 0 → a preset, slot 1 → empty payload, slot 2 → malformed JSON
  transport.query = async (msg) => {
    const slot = msg[7];
    calls.query.push({ msg });
    if (slot === 0) return { resource: 1, payload: payloadOf({ name: 'Bass' }) };
    if (slot === 1) return { resource: 1, payload: [] };
    return { resource: 1, payload: payloadOf('{garbage') };
  };
  const seen = [];
  const results = await device.scanSlots({ bank: 0, slotCount: 3, onSlot: (r) => seen.push(r) });
  assert.equal(results[0].status, 'ok');
  assert.equal(results[0].name, 'Bass');
  assert.equal(results[1].status, 'empty');
  assert.equal(results[2].status, 'error');
  assert.equal(seen.length, 3, 'onSlot fires once per slot');
});

test('scanSlots treats a timeout as an empty slot, not an error', async () => {
  transport.query = async () => { throw new transport.TimeoutError(); };
  const [r] = await device.scanSlots({ bank: 0, slotCount: 1 });
  assert.equal(r.status, 'empty');
});

test('scanSlots stops early when isCancelled reports true', async () => {
  let queried = 0;
  transport.query = async () => {
    queried++;
    return { resource: 1, payload: payloadOf({ name: 'P' }) };
  };
  const results = await device.scanSlots({
    bank: 0,
    slotCount: 12,
    isCancelled: () => queried >= 2,
  });
  assert.equal(queried, 2, 'no further slots queried after cancellation');
  assert.equal(results.length, 2, 'partial results returned');
});

test('scanSlots names an unnamed preset "(unnamed)"', async () => {
  respondWith({ controls: [] }); // no name key
  const [r] = await device.scanSlots({ bank: 0, slotCount: 1 });
  assert.equal(r.status, 'ok');
  assert.equal(r.name, '(unnamed)');
});

// ── backupBank ───────────────────────────────────────────────────────────────

test('backupBank saves occupied slots and skips empties', async () => {
  transport.query = async (msg) => {
    const slot = msg[7];
    return { resource: 1, payload: slot < 2 ? payloadOf({ name: `P${slot}`, controls: [] }) : [] };
  };
  const dir = tmpDir();
  const outDir = path.join(dir, 'backup');
  const res = await device.backupBank({ bank: 0, slotCount: 4, outDir });
  assert.equal(res.saved, 2);
  assert.equal(res.skipped, 2);
  const files = fs.readdirSync(outDir).sort();
  assert.equal(files.length, 2);
  assert.match(files[0], /^b0_s00_P0\.json$/);
});

// ── switchSlot / clearSlot ───────────────────────────────────────────────────

test('switchSlot sends the switch-and-load command (op 0x09), not the arm command', async () => {
  await device.switchSlot(1, 2);
  assert.deepEqual(calls.command[0].msg, proto.presetSlotSwitch(1, 2));
  assert.equal(calls.command[0].msg[4], 0x09);
});

test('clearSlot sends the remove command', async () => {
  await device.clearSlot(2, 3);
  assert.deepEqual(calls.command[0].msg, proto.clearSlot(2, 3));
});

// ── isEmptySlot ──────────────────────────────────────────────────────────────

test('isEmptySlot recognizes EmptySlotError and typed timeouts', () => {
  assert.equal(device.isEmptySlot(new device.EmptySlotError()), true);
  assert.equal(device.isEmptySlot(new transport.TimeoutError()), true);
  // A generic error that merely *mentions* a timeout is NOT an empty slot.
  assert.equal(device.isEmptySlot(new Error('Timeout — device did not respond')), false);
  assert.equal(device.isEmptySlot(new Error('NACK — device rejected the command')), false);
  assert.equal(device.isEmptySlot(null), false);
});
