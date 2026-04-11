#!/usr/bin/env node
'use strict';

const { program }  = require('commander');
const { writeFileSync } = require('fs');
const { resolve }  = require('path');
const transport    = require('../lib/transport');
const device       = require('../lib/device');
const { version }  = require('../package.json');

const log  = (...a) => console.log(...a);
const err  = (...a) => console.error(...a);
const line = (n = 44) => '─'.repeat(n);
const run  = (fn) => (...args) => fn(...args).catch((e) => { err(`\nError: ${e.message}\n`); process.exit(1); });

async function cmdPorts() {
  const { inputs, outputs } = transport.listAllPorts();
  const { inputPort, outputPort, inputName, outputName } = transport.findE1Ports();
  log('\nMIDI Input Ports:');
  inputs.forEach((n, i) => log(`  [${i}] ${n}${i === inputPort ? ' ◀ Electra One' : ''}`));
  log('\nMIDI Output Ports:');
  outputs.forEach((n, i) => log(`  [${i}] ${n}${i === outputPort ? ' ◀ Electra One' : ''}`));
  log(inputPort >= 0
    ? `\n✓ Device found → IN: ${inputName} | OUT: ${outputName}\n`
    : '\n✗ No Electra One detected. Check USB connection.\n');
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
  const bank = opts.bank != null ? parseInt(opts.bank, 10) : undefined;
  const slot = opts.slot != null ? parseInt(opts.slot, 10) : undefined;
  process.stdout.write(`Pulling ${bank != null ? `bank ${bank}, slot ${slot}` : 'active preset'}… `);
  const { preset, outFile } = await device.pullPresetToFile({ bank, slot, outFile: opts.out });
  log('ok\n');
  log(`  Name    : ${preset.name}`);
  log(`  Pages   : ${preset.pages?.length ?? '?'} | Controls: ${preset.controls?.length ?? '?'}`);
  log(`  Saved   : ${outFile}\n`);
}

async function cmdPush(file, opts) {
  const bank = opts.bank != null ? parseInt(opts.bank, 10) : undefined;
  const slot = opts.slot != null ? parseInt(opts.slot, 10) : undefined;
  process.stdout.write(`Validating ${file}… `);
  const preset = await device.pushPresetFromFile(file, { bank, slot });
  log('ok\n');
  log(`  Pushed  : "${preset.name}" → ${bank != null ? `bank ${bank}, slot ${slot}` : 'active slot'}`);
  log(`  Controls: ${preset.controls?.length ?? '?'}\n`);
}

async function cmdPullLua(opts) {
  const bank = opts.bank != null ? parseInt(opts.bank, 10) : undefined;
  const slot = opts.slot != null ? parseInt(opts.slot, 10) : undefined;
  process.stdout.write(`Pulling Lua from ${bank != null ? `bank ${bank}, slot ${slot}` : 'active preset'}… `);
  const lua = await device.getLua({ bank, slot });
  const outFile = opts.out || 'main.lua';
  writeFileSync(outFile, lua, 'utf8');
  log('ok\n');
  log(`  Saved: ${resolve(outFile)} (${lua.split('\n').length} lines)\n`);
}

async function cmdScan(opts) {
  const bank      = opts.bank    != null ? parseInt(opts.bank, 10)    : 0;
  const slotCount = opts.slots   != null ? parseInt(opts.slots, 10)   : 12;
  const timeoutMs = opts.timeout != null ? parseInt(opts.timeout, 10) : 3000;
  log(`\nScanning bank ${bank} (${slotCount} slots)…\n`);
  log('  Slot  Status    Name');
  log('  ────  ────────  ' + '─'.repeat(34));
  const results = await device.scanSlots({
    bank, slotCount, timeoutMs,
    onSlot: (r) => {
      const status = { ok: 'ok      ', empty: 'empty   ', error: 'error   ' }[r.status];
      const name   = r.status === 'ok' ? r.name : r.status === 'error' ? `(${r.error})` : '—';
      log(`  [${String(r.slot).padStart(2, '0')}]  ${status}  ${name}`);
    },
  });
  log(`\n  ${results.filter(r => r.status === 'ok').length} of ${slotCount} slots occupied in bank ${bank}.\n`);
}

program.name('e1').description('Manage your Electra One without the web app').version(version);
program.command('ports').description('List MIDI ports and identify the Electra One').action(run(cmdPorts));
program.command('info').description('Show firmware version, model, serial number').action(run(cmdInfo));
program.command('scan').description('Scan preset slots and list their names')
  .option('-b, --bank <n>',    'Bank to scan (default: 0)')
  .option('-n, --slots <n>',   'Number of slots to check (default: 12)')
  .option('-t, --timeout <ms>','Per-slot timeout in ms (default: 3000)')
  .action(run(cmdScan));
program.command('pull').description('Download a preset to a JSON file')
  .option('-b, --bank <n>', 'Bank number').option('-s, --slot <n>', 'Slot number')
  .option('-o, --out <file>', 'Output filename (default: <preset-name>.json)')
  .action(run(cmdPull));
program.command('push <file>').description('Upload a preset JSON to the device')
  .option('-b, --bank <n>', 'Target bank').option('-s, --slot <n>', 'Target slot')
  .action(run(cmdPush));
program.command('pull-lua').description('Download the Lua script from a preset slot')
  .option('-b, --bank <n>', 'Bank number').option('-s, --slot <n>', 'Slot number')
  .option('-o, --out <file>', 'Output filename (default: main.lua)')
  .action(run(cmdPullLua));

program.parse(process.argv);
