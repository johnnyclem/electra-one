'use strict';

const SOX = 0xF0;
const EOX = 0xF7;
const MANUFACTURER = [0x00, 0x21, 0x45];

// Hardware layout: 6 banks × 12 preset slots.
// These are the single source of truth for the JS side; the TUI, CLI, and
// device layer all import them from here.
const BANKS = 6;
const SLOTS_PER_BANK = 12;

const OP = {
  UPLOAD:      0x01,
  REQUEST:     0x02,
  RESPONSE:    0x01, // same byte as UPLOAD on the wire — direction disambiguates
  REMOVE:      0x05, // remove/clear files in a slot
  SWITCH_SLOT: 0x09, // "switch preset slot" — switches to AND loads the preset
  SELECT_SLOT: 0x14, // "set preset slot" — arms the target slot for upload; does NOT load it
  ACK_NACK:    0x7E,
};

const RES = {
  PRESET:  0x01,
  SLOT:    0x08, // bank/slot pair — used by select/switch/clear
  LUA:     0x0C,
  INFO:    0x7F,
};

function frame(...bytes) {
  return [SOX, ...MANUFACTURER, ...bytes, EOX];
}

const infoRequest = () => frame(OP.REQUEST, RES.INFO);

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
 *
 * Bodies are encoded as 7-bit ASCII (SysEx data bytes must be < 0x80);
 * Node's 'ascii' encoding strips the high bit, so non-ASCII characters are
 * mangled rather than corrupting the stream.
 */
function presetUpload(jsonStr) {
  const payload = Array.from(Buffer.from(jsonStr, 'ascii'));
  return [SOX, ...MANUFACTURER, OP.UPLOAD, RES.PRESET, ...payload, EOX];
}

/** "Set preset slot" — arm the given bank/slot as the active upload target. */
function presetSlotSelect(bank, slot) {
  return frame(OP.SELECT_SLOT, RES.SLOT, bank, slot);
}

/** "Switch preset slot" — switch the device to the given bank/slot and load it. */
function presetSlotSwitch(bank, slot) {
  return frame(OP.SWITCH_SLOT, RES.SLOT, bank, slot);
}

/**
 * "Clear preset slot" — permanently removes all files in the slot (preset +
 * Lua), freeing a burned/corrupt slot. (op 0x05, resource 0x08)
 */
function clearSlot(bank, slot) {
  return frame(OP.REMOVE, RES.SLOT, bank, slot);
}

function luaRequest(bank, slot) {
  if (bank != null && slot != null) return frame(OP.REQUEST, RES.LUA, bank, slot);
  return frame(OP.REQUEST, RES.LUA);
}

/**
 * Build a Lua-upload SysEx message.
 *
 * Like presetUpload, the device always uploads to the *currently active* slot;
 * there is no bank/slot variant. The source follows the resource byte directly.
 * To target a specific slot, send presetSlotSelect() first to arm it, then
 * upload. (Inserting bank/slot bytes here corrupts the Lua body — the same bug
 * that was fixed for presetUpload.)
 */
function luaUpload(luaStr) {
  const payload = Array.from(Buffer.from(luaStr, 'ascii'));
  return [SOX, ...MANUFACTURER, OP.UPLOAD, RES.LUA, ...payload, EOX];
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
  // Shortest valid message is 7 bytes: F0 00 21 45 <op> <code/res> F7.
  if (
    msg.length < 7 ||
    msg[0] !== SOX ||
    !MANUFACTURER.every((b, i) => msg[i + 1] === b) ||
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
  SOX,
  EOX,
  MANUFACTURER,
  BANKS,
  SLOTS_PER_BANK,
  OP,
  RES,
  frame,
  infoRequest,
  presetRequest,
  presetUpload,
  presetSlotSelect,
  presetSlotSwitch,
  clearSlot,
  luaRequest,
  luaUpload,
  classify,
  decodeJSON,
  decodeText,
};
