'use strict';

/**
 * device.js
 *
 * High-level Electra One operations.
 * This is the public API — import this in commands or tests.
 *
 * Each function validates inputs, composes protocol messages,
 * sends via transport, and returns clean structured data.
 */

const path = require('path');
const fs   = require('fs');

const proto     = require('./protocol');
const transport = require('./transport');

// ── Utilities ─────────────────────────────────────────────────────────────────

/**
 * Validate and parse bank/slot arguments.
 * Returns { bank, slot } as integers, or { bank: undefined, slot: undefined }
 * for "active slot" requests.
 */
function parseSlot(bank, slot) {
  if (bank == null && slot == null) return { bank: undefined, slot: undefined };

  if (bank == null || slot == null) {
    throw new Error('--bank and --slot must be used together');
  }
  const b = parseInt(bank, 10);
  const s = parseInt(slot, 10);
  if (isNaN(b) || b < 0 || b > 11) throw new Error('--bank must be 0–11');
  if (isNaN(s) || s < 0 || s > 11) throw new Error('--slot must be 0–11');
  return { bank: b, slot: s };
}

/**
 * Produce a filesystem-safe filename from a preset name.
 * @param {string} name
 * @returns {string}
 */
function safeName(name) {
  return (name || 'preset')
    .trim()
    .replace(/[^a-z0-9_\-. ]/gi, '_')
    .replace(/\s+/g, '_')
    .slice(0, 60);
}

// ── Device operations ─────────────────────────────────────────────────────────

/**
 * @typedef {object} DeviceInfo
 * @property {string} versionText
 * @property {number} versionSeq
 * @property {string} serial
 * @property {string} hwRevision
 * @property {string} model
 * @property {number} modelNum
 */

/**
 * Fetch hardware and firmware info from the device.
 * @returns {Promise<DeviceInfo>}
 */
async function getInfo() {
  const { payload } = await transport.query(proto.infoRequest());
  return proto.decodeJSON(payload);
}

/**
 * @typedef {object} Preset
 * @property {string} name
 * @property {number} version
 * @property {string} [projectId]
 * @property {object[]} pages
 * @property {object[]} devices
 * @property {object[]} controls
 */

/**
 * Download a preset from the device.
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @returns {Promise<Preset>}
 */
async function getPreset({ bank, slot } = {}) {
  const s = parseSlot(bank, slot);
  const { payload } = await transport.query(proto.presetRequest(s.bank, s.slot));
  return proto.decodeJSON(payload);
}

/**
 * Upload a preset to the device.
 * @param {Preset|object} preset  - already-parsed preset object
 * @param {object} [opts]
 * @param {number} [opts.bank]    - omit to replace the active slot
 * @param {number} [opts.slot]
 * @returns {Promise<void>}
 */
async function putPreset(preset, { bank, slot } = {}) {
  if (!preset || typeof preset !== 'object') throw new Error('preset must be an object');
  const s = parseSlot(bank, slot);
  const jsonStr = JSON.stringify(preset);
  await transport.command(proto.presetUpload(jsonStr, s.bank, s.slot));
}

/**
 * Download the Lua script from a preset slot.
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @returns {Promise<string>} Lua source code
 */
async function getLua({ bank, slot } = {}) {
  const s = parseSlot(bank, slot);
  const { payload } = await transport.query(proto.luaRequest(s.bank, s.slot));
  return proto.decodeText(payload);
}

/**
 * @typedef {object} SlotResult
 * @property {number} bank
 * @property {number} slot
 * @property {'ok'|'empty'|'error'} status
 * @property {string} [name]
 * @property {string} [error]
 */

/**
 * Scan a range of slots and return what's in them.
 * Empty slots typically time out — that's treated as 'empty', not an error.
 *
 * @param {object} [opts]
 * @param {number} [opts.bank=0]       - which bank to scan
 * @param {number} [opts.slotCount=12] - how many slots to check
 * @param {number} [opts.timeoutMs=3000] - per-slot timeout (shorter than default)
 * @param {(result: SlotResult) => void} [opts.onSlot] - progress callback
 * @returns {Promise<SlotResult[]>}
 */
async function scanSlots({ bank = 0, slotCount = 12, timeoutMs = 3000, onSlot } = {}) {
  const results = [];

  for (let slot = 0; slot < slotCount; slot++) {
    let result;
    try {
      const { payload } = await transport.query(
        proto.presetRequest(bank, slot),
        { timeoutMs }
      );
      const preset = proto.decodeJSON(payload);
      result = { bank, slot, status: 'ok', name: preset.name || '(unnamed)' };
    } catch (err) {
      const isEmpty = err.message.includes('Timeout') || err.message.includes('did not respond');
      result = {
        bank, slot,
        status: isEmpty ? 'empty' : 'error',
        error:  isEmpty ? undefined : err.message,
      };
    }

    results.push(result);
    if (onSlot) onSlot(result);
  }

  return results;
}

/**
 * Convenience: pull a preset and save it to a file.
 * Returns the resolved output path.
 *
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @param {string} [opts.outFile] - defaults to <preset-name>.json
 * @returns {Promise<{ preset: Preset, outFile: string }>}
 */
async function pullPresetToFile({ bank, slot, outFile } = {}) {
  const preset = await getPreset({ bank, slot });
  const dest = outFile || `${safeName(preset.name)}.json`;
  fs.writeFileSync(dest, JSON.stringify(preset, null, 2), 'utf8');
  return { preset, outFile: path.resolve(dest) };
}

/**
 * Convenience: load a preset JSON file and push it to the device.
 *
 * @param {string} filePath
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @returns {Promise<Preset>} the preset that was pushed
 */
async function pushPresetFromFile(filePath, { bank, slot } = {}) {
  let raw;
  try {
    raw = fs.readFileSync(filePath, 'utf8');
  } catch {
    throw new Error(`Cannot read file: ${filePath}`);
  }

  let preset;
  try {
    preset = JSON.parse(raw);
  } catch (e) {
    throw new Error(`Invalid JSON in ${path.basename(filePath)}: ${e.message}`);
  }

  if (!preset.name || !Array.isArray(preset.controls)) {
    throw new Error('File does not look like an Electra One preset (missing name or controls)');
  }

  await putPreset(preset, { bank, slot });
  return preset;
}


/**
 * Back up all occupied slots in a bank to a directory.
 *
 * @param {object} [opts]
 * @param {number} [opts.bank=0]
 * @param {number} [opts.slotCount=12]
 * @param {string} [opts.outDir='backup']
 * @param {(status: object) => void} [opts.onSlot]
 * @returns {Promise<{ saved: number, skipped: number, outDir: string }>}
 */
async function backupBank({ bank = 0, slotCount = 12, outDir = 'backup', onSlot } = {}) {
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  let saved = 0, skipped = 0;
  for (let slot = 0; slot < slotCount; slot++) {
    let status;
    try {
      const preset = await getPreset({ bank, slot });
      const filename = `b${bank}_s${String(slot).padStart(2,'0')}_${safeName(preset.name)}.json`;
      const dest = path.join(outDir, filename);
      fs.writeFileSync(dest, JSON.stringify(preset, null, 2), 'utf8');
      saved++;
      status = { bank, slot, result: 'saved', name: preset.name, file: dest };
    } catch (e) {
      skipped++;
      const isEmpty = e.message.includes('Timeout') || e.message.includes('did not respond');
      status = { bank, slot, result: isEmpty ? 'empty' : 'error', error: isEmpty ? undefined : e.message };
    }
    if (onSlot) onSlot(status);
  }
  return { saved, skipped, outDir: path.resolve(outDir) };
}

/**
 * Switch the active preset slot on the device.
 * @param {number} bank
 * @param {number} slot
 * @returns {Promise<void>}
 */
async function switchSlot(bank, slot) {
  const s = parseSlot(bank, slot);
  const msg = proto.frame(0x09, 0x08, s.bank, s.slot);
  await transport.command(msg);
}

module.exports = {
  getInfo,
  getPreset, putPreset,
  getLua,
  scanSlots,
  pullPresetToFile, pushPresetFromFile,
  backupBank,
  switchSlot,
};
