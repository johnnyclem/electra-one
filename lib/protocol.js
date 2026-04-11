'use strict';

const SOX = 0xF0;
const EOX = 0xF7;
const MANUFACTURER = [0x00, 0x21, 0x45];

const OP = {
  UPLOAD:   0x01,
  REQUEST:  0x02,
  RESPONSE: 0x01,
  ACK_NACK: 0x7E,
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

function presetUpload(jsonStr, bank, slot) {
  const payload = Array.from(Buffer.from(jsonStr, 'ascii'));
  if (bank != null && slot != null)
    return [SOX, ...MANUFACTURER, OP.UPLOAD, RES.PRESET, bank, slot, ...payload, EOX];
  return [SOX, ...MANUFACTURER, OP.UPLOAD, RES.PRESET, ...payload, EOX];
}

function luaRequest(bank, slot) {
  if (bank != null && slot != null) return frame(OP.REQUEST, RES.LUA, bank, slot);
  return frame(OP.REQUEST, RES.LUA);
}

function classify(msg) {
  if (
    msg[0] !== SOX  || msg[1] !== 0x00 ||
    msg[2] !== 0x21 || msg[3] !== 0x45 ||
    msg.at(-1) !== EOX
  ) return { type: 'unknown' };

  const op = msg[4];
  if (op === OP.RESPONSE) return { type: 'data', resource: msg[5], payload: msg.slice(6, -1) };
  if (op === OP.ACK_NACK) return { type: msg[5] === 0x01 ? 'ack' : 'nack' };
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
  presetRequest, presetUpload, luaRequest,
  classify, decodeJSON, decodeText,
};
