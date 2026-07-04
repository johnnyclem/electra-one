'use strict';

/**
 * e2e-cli.test.js
 *
 * True end-to-end tests: spawn the real CLI (bin/e1.js) as a subprocess with
 * test/helpers/mock-midi.cjs preloaded, so the whole stack runs — commander →
 * device.js → transport.js → (mock) node-midi → simulated Electra One — and
 * we assert on stdout, exit codes, written files, and the exact SysEx bytes
 * the CLI put on the wire.
 */

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const CLI = path.join(ROOT, 'bin', 'e1.js');
const MOCK = path.join(ROOT, 'test', 'helpers', 'mock-midi.cjs');

/** Run the CLI against the mock device; returns { stdout, stderr, status }. */
function e1(args, env = {}) {
  const r = spawnSync(process.execPath, ['--require', MOCK, CLI, ...args], {
    encoding: 'utf8',
    timeout: 15000,
    env: { ...process.env, ...env },
  });
  if (r.error) throw r.error;
  return { stdout: r.stdout, stderr: r.stderr, status: r.status };
}

function tmpDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'e1-e2e-'));
}

/** Read the frames the mock device received, as arrays of bytes. */
function framesFrom(logFile) {
  return fs.readFileSync(logFile, 'utf8').trim().split('\n').map(JSON.parse);
}

// ── discovery & info ─────────────────────────────────────────────────────────

test('e1 ports finds the mock Electra One', () => {
  const { stdout, status } = e1(['ports']);
  assert.equal(status, 0);
  assert.match(stdout, /Electra Controller Electra CTRL/);
  assert.match(stdout, /✓ Device found/);
});

test('e1 info prints model, firmware and serial', () => {
  const { stdout, status } = e1(['info']);
  assert.equal(status, 0);
  assert.match(stdout, /Model\s+: MK2/);
  assert.match(stdout, /Firmware : 3\.7\.1/);
  assert.match(stdout, /Serial\s+: MOCK0001/);
});

test('e1 info fails cleanly when the device never answers', () => {
  const { stderr, status } = e1(['info'], { E1_MOCK_SILENT: '1' });
  assert.equal(status, 1);
  assert.match(stderr, /Timeout/);
});

// ── scan ─────────────────────────────────────────────────────────────────────

test('e1 scan reports occupied and empty slots', () => {
  const { stdout, status } = e1(['scan', '-b', '0', '-n', '3', '-t', '500']);
  assert.equal(status, 0);
  assert.match(stdout, /\[00\]\s+empty/);
  assert.match(stdout, /\[01\]\s+ok\s+Mock Preset/);
  assert.match(stdout, /\[02\]\s+empty/);
  assert.match(stdout, /1 of 3 slots occupied/);
});

// ── pull ─────────────────────────────────────────────────────────────────────

test('e1 pull downloads a preset to a file', () => {
  const dir = tmpDir();
  const out = path.join(dir, 'pulled.json');
  const { stdout, status } = e1(['pull', '-b', '0', '-s', '1', '-o', out]);
  assert.equal(status, 0);
  assert.match(stdout, /Name : Mock Preset/);
  const preset = JSON.parse(fs.readFileSync(out, 'utf8'));
  assert.equal(preset.name, 'Mock Preset');
  assert.equal(preset.controls.length, 1);
});

test('e1 pull survives fragmented SysEx responses', () => {
  const dir = tmpDir();
  const out = path.join(dir, 'frag.json');
  const { status } = e1(['pull', '-b', '0', '-s', '1', '-o', out], { E1_MOCK_FRAGMENT: '1' });
  assert.equal(status, 0);
  assert.equal(JSON.parse(fs.readFileSync(out, 'utf8')).name, 'Mock Preset');
});

test('e1 pull on an empty slot reports it', () => {
  const { stderr, status } = e1(['pull', '-b', '0', '-s', '3']);
  assert.equal(status, 1);
  assert.match(stderr, /Slot is empty/);
});

test('e1 pull validates bank range before touching the device', () => {
  const { stdout, stderr, status } = e1(['pull', '-b', '9', '-s', '0']);
  assert.equal(status, 1);
  assert.match(stderr, /--bank must be 0–5/);
  assert.doesNotMatch(stdout, /Pulling/, 'no progress line for an invalid target');
});

// ── push ─────────────────────────────────────────────────────────────────────

test('e1 push arms the slot then uploads (0x14 before 0x01)', () => {
  const dir = tmpDir();
  const file = path.join(dir, 'p.json');
  const log = path.join(dir, 'frames.log');
  fs.writeFileSync(file, JSON.stringify({ name: 'PushMe', controls: [] }));

  const { stdout, status } = e1(['push', file, '-b', '2', '-s', '3'], { E1_MOCK_LOG: log });
  assert.equal(status, 0);
  assert.match(stdout, /Pushed : "PushMe" → bank 2, slot 3/);

  const frames = framesFrom(log);
  const arm = frames.find((f) => f[4] === 0x14);
  const upload = frames.find((f) => f[4] === 0x01 && f[5] === 0x01);
  assert.ok(arm, 'sent a slot-select (arm) frame');
  assert.deepEqual(arm.slice(5, 8), [0x08, 2, 3], 'armed bank 2 slot 3');
  assert.ok(upload, 'sent a preset upload frame');
  assert.ok(frames.indexOf(arm) < frames.indexOf(upload), 'armed before uploading');
  const body = Buffer.from(upload.slice(6, -1)).toString('ascii');
  assert.equal(JSON.parse(body).name, 'PushMe', 'uploaded JSON is intact on the wire');
});

test('e1 push routes .lua files to the Lua upload (resource 0x0C)', () => {
  const dir = tmpDir();
  const file = path.join(dir, 's.lua');
  const log = path.join(dir, 'frames.log');
  fs.writeFileSync(file, 'print("hello")');

  const { status } = e1(['push', file, '-b', '0', '-s', '0'], { E1_MOCK_LOG: log });
  assert.equal(status, 0);
  const upload = framesFrom(log).find((f) => f[4] === 0x01 && f[5] === 0x0C);
  assert.ok(upload, 'sent a Lua upload frame');
  assert.equal(Buffer.from(upload.slice(6, -1)).toString('ascii'), 'print("hello")');
});

test('e1 push rejects a non-preset JSON file without sending anything', () => {
  const dir = tmpDir();
  const file = path.join(dir, 'x.json');
  const log = path.join(dir, 'frames.log');
  fs.writeFileSync(file, '{"foo": 1}');

  const { stderr, status } = e1(['push', file, '-b', '0', '-s', '0'], { E1_MOCK_LOG: log });
  assert.equal(status, 1);
  assert.match(stderr, /does not look like an Electra One preset/);
  assert.ok(!fs.existsSync(log), 'nothing reached the device');
});

// ── lua round-trip ───────────────────────────────────────────────────────────

test('e1 pull-lua downloads the slot script', () => {
  const dir = tmpDir();
  const out = path.join(dir, 'main.lua');
  const lua = { '0:1': 'function preset.onReady()\n  print("hi")\nend\n' };
  const { status } = e1(['pull-lua', '-b', '0', '-s', '1', '-o', out], {
    E1_MOCK_LUA: JSON.stringify(lua),
  });
  assert.equal(status, 0);
  assert.equal(fs.readFileSync(out, 'utf8'), lua['0:1']);
});

test('e1 pull-lua on a slot with no script reports it instead of writing an empty file', () => {
  const dir = tmpDir();
  const out = path.join(dir, 'main.lua');
  const { stderr, status } = e1(['pull-lua', '-b', '0', '-s', '1', '-o', out]);
  assert.equal(status, 1);
  assert.match(stderr, /No Lua script/);
  assert.ok(!fs.existsSync(out), 'no empty file written');
});

// ── switch / clear ───────────────────────────────────────────────────────────

test('e1 switch sends the switch-and-load opcode (0x09), not arm (0x14)', () => {
  const dir = tmpDir();
  const log = path.join(dir, 'frames.log');
  const { stdout, status } = e1(['switch', '-b', '1', '-s', '4'], { E1_MOCK_LOG: log });
  assert.equal(status, 0);
  assert.match(stdout, /Switching to bank 1, slot 4… ok/);
  const frames = framesFrom(log);
  assert.equal(frames.length, 1);
  assert.deepEqual(frames[0].slice(4, 8), [0x09, 0x08, 1, 4]);
});

test('e1 clear sends the remove opcode (0x05)', () => {
  const dir = tmpDir();
  const log = path.join(dir, 'frames.log');
  const { status } = e1(['clear', '-b', '0', '-s', '2'], { E1_MOCK_LOG: log });
  assert.equal(status, 0);
  const frames = framesFrom(log);
  assert.deepEqual(frames[0].slice(4, 8), [0x05, 0x08, 0, 2]);
});

// ── backup ───────────────────────────────────────────────────────────────────

test('e1 backup saves occupied slots and skips empties', () => {
  const dir = tmpDir();
  const outDir = path.join(dir, 'backup');
  const slots = {
    '0:0': { name: 'First', version: 2, pages: [], devices: [], controls: [] },
    '0:2': { name: 'Third', version: 2, pages: [], devices: [], controls: [] },
  };
  const { stdout, status } = e1(['backup', '-b', '0', '-n', '3', '-o', outDir], {
    E1_MOCK_SLOTS: JSON.stringify(slots),
  });
  assert.equal(status, 0);
  assert.match(stdout, /2 preset\(s\) saved, 1 slot\(s\) skipped/);
  const files = fs.readdirSync(outDir).sort();
  assert.deepEqual(files, ['b0_s00_First.json', 'b0_s02_Third.json']);
});
