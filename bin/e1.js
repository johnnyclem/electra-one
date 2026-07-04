#!/usr/bin/env node
'use strict';

/**
 * bin/e1.js
 *
 * CLI entry point. Commander wiring only — no business logic here.
 * All real work lives in lib/device.js.
 */

const path = require('path');
const fs   = require('fs');

const { program } = require('commander');
const transport   = require('../lib/transport');
const device      = require('../lib/device');
const { version } = require('../package.json');

// ── Output helpers ────────────────────────────────────────────────────────────

const log  = (...a) => console.log(...a);
const err  = (...a) => console.error(...a);
const line = (n = 42) => '─'.repeat(n);

/**
 * Wrap an async command handler so errors print cleanly and the process
 * always exits. The persistent MIDI ports keep the event loop alive, so we
 * disconnect and exit explicitly once the command finishes.
 */
const run = (fn) => (...args) =>
  fn(...args)
    .then(() => {
      transport.disconnect();
      process.exit(0);
    })
    .catch((e) => {
      err(`\nError: ${e.message}\n`);
      transport.disconnect();
      process.exit(1);
    });

/**
 * Validate and parse the shared -b/-s flags, and produce the human-readable
 * target label. Throws (with the CLI-friendly message) on bad input, so
 * nothing gets printed for an invalid target.
 */
function targetFromOpts(opts, activeLabel = 'active slot') {
  const { bank, slot } = device.parseSlot(opts.bank, opts.slot);
  const where = bank != null ? `bank ${bank}, slot ${slot}` : activeLabel;
  return { bank, slot, where };
}

// ── Command implementations ───────────────────────────────────────────────────

async function cmdPorts() {
  const { inputs, outputs } = transport.listAllPorts();
  const { inputPort, outputPort, inputName, outputName } = transport.findE1Ports();

  log('\nMIDI Input Ports:');
  inputs.forEach((name, i) => {
    const marker = i === inputPort ? ' ◀ Electra One' : '';
    log(`  [${i}] ${name}${marker}`);
  });

  log('\nMIDI Output Ports:');
  outputs.forEach((name, i) => {
    const marker = i === outputPort ? ' ◀ Electra One' : '';
    log(`  [${i}] ${name}${marker}`);
  });

  if (inputPort >= 0) {
    log(`\n✓ Device found → IN: ${inputName} | OUT: ${outputName}\n`);
  } else {
    log('\n✗ No Electra One detected. Check USB connection and try again.\n');
  }
}

async function cmdInfo() {
  process.stdout.write('Querying device… ');
  const info = await device.getInfo();
  log('ok\n');
  log(line());
  log(` Model    : ${info.model.toUpperCase()} (hw rev ${info.hwRevision})`);
  log(` Firmware : ${info.versionText}`);
  log(` Serial   : ${info.serial}`);
  log(line() + '\n');
}

async function cmdPull(opts) {
  const { bank, slot, where } = targetFromOpts(opts, 'active preset');
  process.stdout.write(`Pulling ${where}… `);

  const { preset, outFile } = await device.pullPresetToFile({
    bank, slot, outFile: opts.out,
  });

  log('ok\n');
  log(`  Name : ${preset.name}`);
  log(`  Pages: ${preset.pages?.length ?? '?'} | Controls: ${preset.controls?.length ?? '?'}`);
  log(`  Saved: ${outFile}\n`);
}

async function cmdPush(file, opts) {
  // Detect file type by extension
  if (file.endsWith('.lua')) {
    return cmdPushLua(file, opts);
  }

  const { bank, slot, where } = targetFromOpts(opts);
  process.stdout.write(`Validating ${file}… `);

  // pushPresetFromFile validates JSON + structure before sending
  const preset = await device.pushPresetFromFile(file, { bank, slot });
  log('ok\n');
  log(`  Pushed : "${preset.name}" → ${where}`);
  log(`  Controls: ${preset.controls?.length ?? '?'}\n`);
}

async function cmdPushLua(file, opts) {
  const { bank, slot, where } = targetFromOpts(opts);
  process.stdout.write(`Uploading Lua to ${where}… `);

  const lua = await device.pushLuaFromFile(file, { bank, slot });
  log('ok\n');
  log(`  Pushed : ${path.basename(file)} → ${where}`);
  log(`  Lines  : ${lua.split('\n').length}\n`);
}

async function cmdPullLua(opts) {
  const { bank, slot, where } = targetFromOpts(opts, 'active preset');
  process.stdout.write(`Pulling Lua from ${where}… `);

  const lua     = await device.getLua({ bank, slot });
  const outFile = opts.out || 'main.lua';

  fs.writeFileSync(outFile, lua, 'utf8');

  log('ok\n');
  log(`  Saved: ${path.resolve(outFile)}`);
  log(`  Lines: ${lua.split('\n').length}\n`);
}

async function cmdScan(opts) {
  const bank      = opts.bank != null ? parseInt(opts.bank, 10) : 0;
  const slotCount = opts.slots != null ? parseInt(opts.slots, 10) : device.SLOTS_PER_BANK;

  log(`\nScanning bank ${bank} (${slotCount} slots)…\n`);
  log(`  Slot  Status    Name`);
  log(`  ────  ────────  ──────────────────────────────────`);

  const results = await device.scanSlots({
    bank,
    slotCount,
    timeoutMs: opts.timeout != null ? parseInt(opts.timeout, 10) : 3000,
    onSlot: (r) => {
      const status = r.status === 'ok'    ? 'ok      '
                   : r.status === 'empty' ? 'empty   '
                   :                        'error   ';
      const name   = r.status === 'ok'    ? r.name
                   : r.status === 'error' ? `(${r.error})`
                   :                        '—';
      log(`  [${String(r.slot).padStart(2, '0')}]  ${status}  ${name}`);
    },
  });

  const found = results.filter(r => r.status === 'ok');
  log(`\n  ${found.length} of ${slotCount} slots occupied in bank ${bank}.\n`);
}

async function cmdBackup(opts) {
  const bank      = opts.bank   != null ? parseInt(opts.bank, 10)   : 0;
  const slotCount = opts.slots  != null ? parseInt(opts.slots, 10)  : device.SLOTS_PER_BANK;
  const outDir    = opts.out    || 'backup';

  log(`\nBacking up bank ${bank} (${slotCount} slots) → ${outDir}/\n`);
  log('  Slot  Result    Name / File');
  log('  ────  ────────  ' + '─'.repeat(40));

  const { saved, skipped } = await device.backupBank({
    bank, slotCount, outDir,
    onSlot: (s) => {
      if (s.result === 'saved') {
        log(`  [${String(s.slot).padStart(2,'0')}]  saved     ${s.name}  →  ${path.basename(s.file)}`);
      } else if (s.result === 'empty') {
        log(`  [${String(s.slot).padStart(2,'0')}]  empty     —`);
      } else {
        log(`  [${String(s.slot).padStart(2,'0')}]  error     (${s.error})`);
      }
    },
  });

  log(`\n  ✓ ${saved} preset(s) saved, ${skipped} slot(s) skipped.\n`);
}

async function cmdSwitch(opts) {
  const bank = parseInt(opts.bank, 10);
  const slot = parseInt(opts.slot, 10);
  process.stdout.write(`Switching to bank ${bank}, slot ${slot}… `);
  await device.switchSlot(bank, slot);
  log('ok\n');
}

async function cmdClear(opts) {
  const bank = parseInt(opts.bank, 10);
  const slot = parseInt(opts.slot, 10);
  process.stdout.write(`Clearing bank ${bank}, slot ${slot} (preset + Lua)… `);
  await device.clearSlot(bank, slot);
  log('ok\n');
  log('  Slot is now empty.\n');
}

// ── CLI definition ────────────────────────────────────────────────────────────

program
  .name('e1')
  .description('Manage your Electra One without the web app')
  .version(version);

program
  .command('ports')
  .description('List all MIDI ports and identify the Electra One')
  .action(run(cmdPorts));

program
  .command('info')
  .description('Show device firmware version, model, and serial number')
  .action(run(cmdInfo));

program
  .command('scan')
  .description('Scan preset slots and show what\'s loaded')
  .option('-b, --bank <n>', 'Bank to scan (default: 0)')
  .option('-n, --slots <n>', 'Number of slots to scan (default: 12)')
  .option('-t, --timeout <ms>', 'Per-slot timeout in ms (default: 3000)')
  .action(run(cmdScan));

program
  .command('pull')
  .description('Download a preset from the device to a JSON file')
  .option('-b, --bank <n>', 'Bank number (use with --slot)')
  .option('-s, --slot <n>', 'Slot number (use with --bank)')
  .option('-o, --out <file>', 'Output filename (default: <preset-name>.json)')
  .action(run(cmdPull));

program
  .command('push <file>')
  .description('Upload a preset (.json) or Lua script (.lua) to the device')
  .option('-b, --bank <n>', 'Target bank (use with --slot; default: active slot)')
  .option('-s, --slot <n>', 'Target slot (use with --bank)')
  .action(run(cmdPush));

program
  .command('push-lua <file>')
  .description('Upload a Lua script to a preset slot on the device')
  .option('-b, --bank <n>', 'Target bank (use with --slot; default: active slot)')
  .option('-s, --slot <n>', 'Target slot (use with --bank)')
  .action(run(cmdPushLua));

program
  .command('pull-lua')
  .description('Download the Lua script from the active (or specified) preset slot')
  .option('-b, --bank <n>', 'Bank number')
  .option('-s, --slot <n>', 'Slot number')
  .option('-o, --out <file>', 'Output filename (default: main.lua)')
  .action(run(cmdPullLua));

program
  .command('backup')
  .description('Download all occupied preset slots in a bank to a directory')
  .option('-b, --bank <n>',  'Bank to back up (default: 0)')
  .option('-n, --slots <n>', 'Number of slots to check (default: 12)')
  .option('-o, --out <dir>', 'Output directory (default: ./backup)')
  .action(run(cmdBackup));

program
  .command('switch')
  .description('Switch the active preset slot on the device')
  .requiredOption('-b, --bank <n>', 'Bank number')
  .requiredOption('-s, --slot <n>', 'Slot number')
  .action(run(cmdSwitch));

program
  .command('clear')
  .description('Permanently clear a preset slot (preset + Lua) — frees a burned/corrupt slot')
  .requiredOption('-b, --bank <n>', 'Bank number')
  .requiredOption('-s, --slot <n>', 'Slot number')
  .action(run(cmdClear));

program
  .command('tui', { isDefault: true })
  .description('Launch the full-screen interactive app (default)')
  .action(() => {
    // The TUI is an ESM module (Ink); load it dynamically from CommonJS.
    import('../tui/app.mjs')
      .then((m) => m.start())
      .then(() => {
        transport.disconnect();
        process.exit(0);
      })
      .catch((e) => {
        err(`\nError: ${e.message}\n`);
        transport.disconnect();
        process.exit(1);
      });
  });

program.parse(process.argv);
