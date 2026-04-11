'use strict';

const path = require('path');
const fs   = require('fs');
const proto     = require('./protocol');
const transport = require('./transport');

function parseSlot(bank, slot) {
  if (bank == null && slot == null) return { bank: undefined, slot: undefined };
  if (bank == null || slot == null) throw new Error('--bank and --slot must be used together');
  const b = parseInt(bank, 10);
  const s = parseInt(slot, 10);
  if (isNaN(b) || b < 0 || b > 11) throw new Error('--bank must be 0–11');
  if (isNaN(s) || s < 0 || s > 11) throw new Error('--slot must be 0–11');
  return { bank: b, slot: s };
}

function safeName(name) {
  return (name || 'preset').trim().replace(/[^a-z0-9_\-. ]/gi, '_').replace(/\s+/g, '_').slice(0, 60);
}

async function getInfo() {
  const { payload } = await transport.query(proto.infoRequest());
  return proto.decodeJSON(payload);
}

async function getPreset({ bank, slot } = {}) {
  const s = parseSlot(bank, slot);
  const { payload } = await transport.query(proto.presetRequest(s.bank, s.slot));
  return proto.decodeJSON(payload);
}

async function putPreset(preset, { bank, slot } = {}) {
  if (!preset || typeof preset !== 'object') throw new Error('preset must be an object');
  const s = parseSlot(bank, slot);
  await transport.command(proto.presetUpload(JSON.stringify(preset), s.bank, s.slot));
}

async function getLua({ bank, slot } = {}) {
  const s = parseSlot(bank, slot);
  const { payload } = await transport.query(proto.luaRequest(s.bank, s.slot));
  return proto.decodeText(payload);
}

async function scanSlots({ bank = 0, slotCount = 12, timeoutMs = 3000, onSlot } = {}) {
  const results = [];
  for (let slot = 0; slot < slotCount; slot++) {
    let result;
    try {
      const { payload } = await transport.query(proto.presetRequest(bank, slot), { timeoutMs });
      const preset = proto.decodeJSON(payload);
      result = { bank, slot, status: 'ok', name: preset.name || '(unnamed)' };
    } catch (err) {
      const isEmpty = err.message.includes('Timeout') || err.message.includes('did not respond');
      result = { bank, slot, status: isEmpty ? 'empty' : 'error', error: isEmpty ? undefined : err.message };
    }
    results.push(result);
    if (onSlot) onSlot(result);
  }
  return results;
}

async function pullPresetToFile({ bank, slot, outFile } = {}) {
  const preset = await getPreset({ bank, slot });
  const dest = outFile || `${safeName(preset.name)}.json`;
  fs.writeFileSync(dest, JSON.stringify(preset, null, 2), 'utf8');
  return { preset, outFile: path.resolve(dest) };
}

async function pushPresetFromFile(filePath, { bank, slot } = {}) {
  let raw;
  try { raw = fs.readFileSync(filePath, 'utf8'); }
  catch { throw new Error(`Cannot read file: ${filePath}`); }

  let preset;
  try { preset = JSON.parse(raw); }
  catch (e) { throw new Error(`Invalid JSON in ${path.basename(filePath)}: ${e.message}`); }

  if (!preset.name || !Array.isArray(preset.controls))
    throw new Error('File does not look like an Electra One preset (missing name or controls)');

  await putPreset(preset, { bank, slot });
  return preset;
}

module.exports = { getInfo, getPreset, putPreset, getLua, scanSlots, pullPresetToFile, pushPresetFromFile };
