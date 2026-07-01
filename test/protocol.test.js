'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const proto = require('../lib/protocol');

const SOX = 0xF0;
const EOX = 0xF7;
const MFR = [0x00, 0x21, 0x45];

// ── framing ────────────────────────────────────────────────────────────────

test('frame wraps bytes in SysEx + manufacturer id', () => {
  assert.deepEqual(proto.frame(0x02, 0x7F), [SOX, ...MFR, 0x02, 0x7F, EOX]);
});

test('infoRequest is a request (0x02) for the info resource (0x7F)', () => {
  assert.deepEqual(proto.infoRequest(), [SOX, ...MFR, 0x02, 0x7F, EOX]);
});

test('presetRequest with no slot targets the active preset', () => {
  assert.deepEqual(proto.presetRequest(), [SOX, ...MFR, 0x02, 0x01, EOX]);
});

test('presetRequest with bank/slot appends the coordinates', () => {
  assert.deepEqual(proto.presetRequest(3, 7), [SOX, ...MFR, 0x02, 0x01, 3, 7, EOX]);
});

test('presetRequest treats slot 0 as a real slot, not "active"', () => {
  // Regression: 0 is falsy but a valid bank/slot. `!= null` must gate on this.
  assert.deepEqual(proto.presetRequest(0, 0), [SOX, ...MFR, 0x02, 0x01, 0, 0, EOX]);
});

test('luaRequest active vs specific slot', () => {
  assert.deepEqual(proto.luaRequest(), [SOX, ...MFR, 0x02, 0x0C, EOX]);
  assert.deepEqual(proto.luaRequest(1, 2), [SOX, ...MFR, 0x02, 0x0C, 1, 2, EOX]);
});

test('presetSlotSelect arms a slot (op 0x14, res 0x08)', () => {
  assert.deepEqual(proto.presetSlotSelect(2, 5), [SOX, ...MFR, 0x14, 0x08, 2, 5, EOX]);
});

test('clearSlot removes a slot (op 0x05, res 0x08)', () => {
  assert.deepEqual(proto.clearSlot(1, 4), [SOX, ...MFR, 0x05, 0x08, 1, 4, EOX]);
});

// ── uploads: body follows the resource byte directly (no bank/slot) ──────────

test('presetUpload places raw JSON bytes after op/resource, no slot bytes', () => {
  const msg = proto.presetUpload('{"name":"x"}');
  assert.equal(msg[0], SOX);
  assert.deepEqual(msg.slice(1, 4), MFR);
  assert.equal(msg[4], 0x01, 'op = upload');
  assert.equal(msg[5], 0x01, 'resource = preset');
  const body = msg.slice(6, -1);
  assert.equal(Buffer.from(body).toString('ascii'), '{"name":"x"}');
  assert.equal(msg.at(-1), EOX);
});

test('luaUpload places raw source after op/resource', () => {
  const msg = proto.luaUpload('print(1)');
  assert.equal(msg[4], 0x01, 'op = upload');
  assert.equal(msg[5], 0x0C, 'resource = lua');
  assert.equal(Buffer.from(msg.slice(6, -1)).toString('ascii'), 'print(1)');
});

test('upload bodies are ascii-encoded byte arrays', () => {
  const msg = proto.presetUpload('AB');
  assert.deepEqual(msg.slice(6, -1), [0x41, 0x42]);
});

// ── classify ─────────────────────────────────────────────────────────────────

test('classify decodes a data response and slices out the payload', () => {
  const msg = [SOX, ...MFR, 0x01, 0x01, 0x7B, 0x7D, EOX]; // op=response res=preset {}
  assert.deepEqual(proto.classify(msg), {
    type: 'data', resource: 0x01, payload: [0x7B, 0x7D],
  });
});

test('classify recognizes ACK (0x7E 0x01)', () => {
  assert.deepEqual(proto.classify([SOX, ...MFR, 0x7E, 0x01, 0x00, 0x00, EOX]), { type: 'ack' });
});

test('classify recognizes NACK (0x7E 0x00)', () => {
  assert.deepEqual(proto.classify([SOX, ...MFR, 0x7E, 0x00, EOX]), { type: 'nack' });
});

test('classify treats a non-ack/nack 0x7E code as a transient status, not a NACK', () => {
  // The 0x05 "notification" preceding a real ack must NOT read as a rejection.
  assert.deepEqual(proto.classify([SOX, ...MFR, 0x7E, 0x05, EOX]), { type: 'status', code: 0x05 });
});

test('classify rejects messages with the wrong manufacturer id', () => {
  assert.deepEqual(proto.classify([SOX, 0x00, 0x00, 0x00, 0x01, 0x01, EOX]), { type: 'unknown' });
});

test('classify rejects messages not terminated by EOX', () => {
  assert.deepEqual(proto.classify([SOX, ...MFR, 0x01, 0x01, 0x00]), { type: 'unknown' });
});

test('classify returns unknown for an unrecognized op', () => {
  assert.deepEqual(proto.classify([SOX, ...MFR, 0x42, 0x00, EOX]), { type: 'unknown' });
});

// ── decode helpers ───────────────────────────────────────────────────────────

test('decodeJSON parses an ascii JSON payload', () => {
  const payload = Array.from(Buffer.from('{"name":"Demo","version":2}', 'ascii'));
  assert.deepEqual(proto.decodeJSON(payload), { name: 'Demo', version: 2 });
});

test('decodeJSON throws a descriptive error on malformed JSON', () => {
  const payload = Array.from(Buffer.from('{not json', 'ascii'));
  assert.throws(() => proto.decodeJSON(payload), /Malformed JSON in device response/);
});

test('decodeText decodes an ascii payload to a string', () => {
  const payload = Array.from(Buffer.from('function onReady() end', 'ascii'));
  assert.equal(proto.decodeText(payload), 'function onReady() end');
});

test('round-trip: presetUpload body decodes back via decodeJSON', () => {
  const preset = { name: 'RT', controls: [{ id: 1 }] };
  const msg = proto.presetUpload(JSON.stringify(preset));
  assert.deepEqual(proto.decodeJSON(msg.slice(6, -1)), preset);
});
