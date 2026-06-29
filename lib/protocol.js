'use strict';

const SOX = 0xF0;
const EOX = 0xF7;
const MANUFACTURER = [0x00, 0x21, 0x45];

const OP = {
  UPLOAD:      0x01,
  REQUEST:     0x02,
  RESPONSE:    0x01,
  SELECT_SLOT: 0x14, // "set preset slot" — arms the target slot for upload
  ACK_NACK:    0x7E,
};

const RES = {
  PRESET:  0x01,
  LUA:     0x0C,
  INFO:    0x7F,
  RUNTIME: 0x7E,
};

function frame(...bytes) {
  return [SOX, ...MANUFACTURER, ...bytes, EOX];
}

const infoRequest    = () => frame(OP.REQUEST, RES.INFO);
const runtimeRequest = () => frame(OP.REQUEST, RES.RUNTIME);

function presetRequest(bank, slot) {
  if (bank != null && slot != null) return frame(OP.REQUEST, RES.PRESET, bank, slot);
  return frame(OP.REQUEST, RES.PRESET);
}

/**
 * Build a preset-upload SysEx message.
 *
 * IMPORTANT: the device always uploads to the *currently active* slot. There
 * is no bank/slot variant of the upload command — the JSON body follows the
 * resource byte directly. To target a specific slot, send presetSlotSelect()
 * first to arm it, then upload. (Earlier code inserted bank/slot bytes here,
 * which corrupted the JSON body and got a NACK.)
 */
function presetUpload(jsonStr) {
  const payload = Array.from(Buffer.from(jsonStr, 'ascii'));
  return [SOX, ...MANUFACTURER, OP.UPLOAD, RES.PRESET, ...payload, EOX];
}

/** "Set preset slot" — arm the given bank/slot as the active target. */
function presetSlotSelect(bank, slot) {
  return frame(OP.SELECT_SLOT, 0x08, bank, slot);
}

function luaRequest(bank, slot) {
  if (bank != null && slot != null) return frame(OP.REQUEST, RES.LUA, bank, slot);
  return frame(OP.REQUEST, RES.LUA);
}

/**
 * Acknowledgement codes carried in the byte after the 0x7E op.
 *
 * Empirically, an upload triggers two 0x7E messages from the device:
 *   F0 00 21 45 7E 05 F7          ← a notification (NOT a result)
 *   F0 00 21 45 7E 01 00 00 F7    ← the actual ACK
 *
 * The old code treated any 0x7E whose code byte wasn't 0x01 as a NACK, so the
 * leading 0x05 notification was misread as a rejection. We now decode the code
 * explicitly and ignore anything that isn't a definite ack/nack.
 */
const ACK = 0x01;
const NAK = 0x00;

function classify(msg) {
  if (
    msg[0] !== SOX  || msg[1] !== 0x00 ||
    msg[2] !== 0x21 || msg[3] !== 0x45 ||
    msg.at(-1) !== EOX
  ) return { type: 'unknown' };

  const op = msg[4];
  if (op === OP.RESPONSE) return { type: 'data', resource: msg[5], payload: msg.slice(6, -1) };
  if (op === OP.ACK_NACK) {
    const code = msg[5];
    if (code === ACK) return { type: 'ack' };
    if (code === NAK) return { type: 'nack' };
    return { type: 'status', code }; // e.g. 0x05 notification — wait for the real ack/nack
  }
  return { type: 'unknown' };
}

function decodeJSON(payload) {
  try {
    return JSON.parse(Buffer.from(payload).toString('ascii'));
  } catch (e) {
    throw new Error(`Malformed JSON in device response: ${e.message}`);
  }
}

function decodeText(payload) {
  return Buffer.from(payload).toString('ascii');
}

module.exports = {
  SOX, EOX, MANUFACTURER, OP, RES,
  frame, infoRequest, runtimeRequest,
  presetRequest, presetUpload, presetSlotSelect, luaRequest,
  classify, decodeJSON, decodeText,
};
