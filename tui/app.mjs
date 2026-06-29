// tui/app.mjs
//
// Full-screen terminal app for the Electra One.
//
// Auto-connects to a USB-attached Electra One, lists preset slots in a bank,
// and lets you view / pull / edit / upload / activate presets — all over the
// persistent MIDI connection in lib/transport.js.
//
// No build step: Ink + React rendered through `htm` tagged templates.

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { render, Box, Text, useApp, useInput, useStdin } from 'ink';
import htm from 'htm';
import { spawn } from 'node:child_process';
import { writeFileSync, readFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const device    = require('../lib/device');
const transport = require('../lib/transport');

const html = htm.bind(React.createElement);

const SLOTS_PER_BANK = 12;
const BANKS = 6;
const SCAN_TIMEOUT = 1500;

const safeName = (name) =>
  (name || 'preset').trim().replace(/[^a-z0-9_\-. ]/gi, '_').replace(/\s+/g, '_').slice(0, 60);

// ── Slot list ─────────────────────────────────────────────────────────────────

function SlotRow({ slot, cursor }) {
  const selected = slot.slot === cursor;
  const marker = selected ? '▶' : ' ';
  let label, color;
  switch (slot.status) {
    case 'ok':       label = slot.name;          color = 'green';   break;
    case 'empty':    label = '—';                color = 'gray';    break;
    case 'scanning': label = 'scanning…';        color = 'yellow';  break;
    case 'error':    label = `(${slot.error})`;  color = 'red';     break;
    default:         label = '·';                color = 'gray';    break;
  }
  return html`
    <${Box}>
      <${Text} color=${selected ? 'cyan' : undefined} bold=${selected}>
        ${marker} [${String(slot.slot).padStart(2, '0')}] ${'  '}
      <//>
      <${Text} color=${color}>${label}<//>
    <//>
  `;
}

// ── Detail pane ─────────────────────────────────────────────────────────────────

function Detail({ detail, loading }) {
  if (loading) {
    return html`<${Box} flexDirection="column"><${Text} color="yellow">Loading preset…<//><//>`;
  }
  if (!detail) {
    return html`
      <${Box} flexDirection="column">
        <${Text} dimColor>Select a slot and press <${Text} color="cyan">Enter<//> to view it.<//>
      <//>`;
  }
  if (detail.empty) {
    return html`<${Box}><${Text} dimColor>Slot ${detail.slot} is empty.<//><//>`;
  }
  const p = detail.preset;
  const pages = p.pages?.length ?? 0;
  const controls = p.controls?.length ?? 0;
  const devices = p.devices?.length ?? 0;
  return html`
    <${Box} flexDirection="column">
      <${Text} bold color="green">${p.name || '(unnamed)'}<//>
      <${Text} dimColor>slot ${detail.slot} · v${p.version ?? '?'}${p.projectId ? ` · ${p.projectId}` : ''}<//>
      <${Box} marginTop=${1} flexDirection="column">
        <${Text}>Pages    : ${pages}<//>
        <${Text}>Controls : ${controls}<//>
        <${Text}>Devices  : ${devices}<//>
      <//>
      ${devices > 0 && html`
        <${Box} marginTop=${1} flexDirection="column">
          <${Text} dimColor>Devices:<//>
          ${p.devices.slice(0, 6).map((d, i) => html`
            <${Text} key=${i}>  • ${d.name || d.id || '?'}${d.port != null ? ` (port ${d.port})` : ''}<//>
          `)}
        <//>`}
    <//>
  `;
}

// ── Inline text prompt (for upload path) ────────────────────────────────────────

function Prompt({ label, value }) {
  return html`
    <${Box}>
      <${Text} color="cyan">${label} <//>
      <${Text}>${value}<//>
      <${Text} inverse> <//>
    <//>
  `;
}

// ── Main app ─────────────────────────────────────────────────────────────────

function App() {
  const { exit } = useApp();
  const { setRawMode } = useStdin();

  const [status, setStatus]   = useState('connecting'); // connecting|ready|error
  const [info, setInfo]       = useState(null);
  const [portName, setPort]   = useState('');
  const [errorMsg, setError]  = useState('');

  const [bank, setBank]       = useState(0);
  const [slots, setSlots]     = useState(() => freshSlots());
  const [cursor, setCursor]   = useState(0);

  const [detail, setDetail]   = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const [busy, setBusy]       = useState(false);
  const [message, setMessage] = useState('');

  const [mode, setMode]       = useState('browse'); // browse | upload
  const [input, setInput]     = useState('');

  const scanToken = useRef(0); // cancels stale scans on bank change/refresh

  function freshSlots() {
    return Array.from({ length: SLOTS_PER_BANK }, (_, slot) => ({ slot, status: 'unknown' }));
  }

  // Connect once on mount.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const ports = transport.connect();
        if (cancelled) return;
        setPort(ports.inputName || '');
        const i = await device.getInfo();
        if (cancelled) return;
        setInfo(i);
        setStatus('ready');
      } catch (e) {
        if (!cancelled) { setError(e.message); setStatus('error'); }
      }
    })();
    return () => { cancelled = true; };
  }, []);

  // (Re)scan whenever the bank changes (and once we're ready).
  const rescan = useCallback((targetBank) => {
    const token = ++scanToken.current;
    setSlots(freshSlots());
    setDetail(null);
    (async () => {
      await device.scanSlots({
        bank: targetBank,
        slotCount: SLOTS_PER_BANK,
        timeoutMs: SCAN_TIMEOUT,
        onSlot: (r) => {
          if (token !== scanToken.current) return; // a newer scan started
          setSlots((prev) => {
            const next = prev.slice();
            next[r.slot] = { slot: r.slot, status: r.status, name: r.name, error: r.error };
            return next;
          });
        },
      });
      if (token === scanToken.current) setMessage(`Scanned bank ${targetBank}.`);
    })();
  }, []);

  useEffect(() => {
    if (status === 'ready') rescan(bank);
  }, [status, bank, rescan]);

  // ── Operations ──────────────────────────────────────────────────────────────

  const current = slots[cursor];

  const withBusy = async (msg, fn) => {
    setBusy(true);
    setMessage(msg);
    try {
      const done = await fn();
      setMessage(done || 'Done.');
    } catch (e) {
      setMessage(`Error: ${e.message}`);
    } finally {
      setBusy(false);
    }
  };

  const loadDetail = useCallback(async (slot) => {
    setDetailLoading(true);
    setDetail(null);
    try {
      const preset = await device.getPreset({ bank, slot });
      setDetail({ slot, preset });
      setMessage(`Loaded "${preset.name}".`);
    } catch (e) {
      if (device.isEmptySlot(e)) setDetail({ slot, empty: true });
      else setMessage(`Error: ${e.message}`);
    } finally {
      setDetailLoading(false);
    }
  }, [bank]);

  const pullToFile = (slot) => withBusy(`Pulling slot ${slot}…`, async () => {
    const preset = await device.getPreset({ bank, slot });
    const file = path.resolve(`${safeName(preset.name)}.json`);
    writeFileSync(file, JSON.stringify(preset, null, 2), 'utf8');
    return `Saved → ${file}`;
  });

  const activate = (slot) => withBusy(`Activating bank ${bank}, slot ${slot}…`, async () => {
    await device.switchSlot(bank, slot);
    return `Activated bank ${bank}, slot ${slot} on device.`;
  });

  const uploadFile = (slot, file) => withBusy(`Uploading ${file} → slot ${slot}…`, async () => {
    const preset = await device.pushPresetFromFile(file, { bank, slot });
    rescan(bank);
    return `Uploaded "${preset.name}" → bank ${bank}, slot ${slot}.`;
  });

  // Pull → open $EDITOR → push back on save.
  const editInEditor = (slot) => {
    const editor = process.env.VISUAL || process.env.EDITOR || 'vi';
    setBusy(true);
    setMessage(`Pulling slot ${slot} for editing…`);
    (async () => {
      let preset;
      try {
        preset = await device.getPreset({ bank, slot });
      } catch (e) {
        setBusy(false);
        setMessage(device.isEmptySlot(e) ? 'Slot is empty — nothing to edit.' : `Error: ${e.message}`);
        return;
      }
      const dir = mkdtempSync(path.join(tmpdir(), 'e1-edit-'));
      const file = path.join(dir, `${safeName(preset.name)}.json`);
      const before = JSON.stringify(preset, null, 2);
      writeFileSync(file, before, 'utf8');

      // Hand the terminal to the editor.
      setRawMode(false);
      await new Promise((resolve) => {
        const child = spawn(editor, [file], { stdio: 'inherit' });
        child.on('exit', resolve);
        child.on('error', () => resolve());
      });
      setRawMode(true);

      let edited;
      try {
        const after = readFileSync(file, 'utf8');
        if (after === before) { setBusy(false); setMessage('No changes — left slot untouched.'); return; }
        edited = JSON.parse(after);
      } catch (e) {
        setBusy(false);
        setMessage(`Invalid JSON after edit — not uploaded: ${e.message}`);
        return;
      }
      try {
        await device.putPreset(edited, { bank, slot });
        setMessage(`Saved edits → bank ${bank}, slot ${slot}.`);
        rescan(bank);
      } catch (e) {
        setMessage(`Upload failed: ${e.message}`);
      } finally {
        setBusy(false);
      }
    })();
  };

  // ── Input handling ────────────────────────────────────────────────────────────

  useInput((inputChar, key) => {
    if (mode === 'upload') {
      if (key.escape) { setMode('browse'); setInput(''); setMessage('Upload cancelled.'); return; }
      if (key.return) {
        const file = input.trim();
        setMode('browse'); setInput('');
        if (file) uploadFile(cursor, file);
        return;
      }
      if (key.backspace || key.delete) { setInput((s) => s.slice(0, -1)); return; }
      if (inputChar && !key.ctrl && !key.meta) setInput((s) => s + inputChar);
      return;
    }

    if (busy) return; // ignore keys during operations

    if (inputChar === 'q' || (key.ctrl && inputChar === 'c')) {
      transport.disconnect();
      exit();
      return;
    }
    if (key.upArrow || inputChar === 'k') { setCursor((c) => (c - 1 + SLOTS_PER_BANK) % SLOTS_PER_BANK); return; }
    if (key.downArrow || inputChar === 'j') { setCursor((c) => (c + 1) % SLOTS_PER_BANK); return; }
    if (key.return) { loadDetail(cursor); return; }
    if (inputChar === 'p') { pullToFile(cursor); return; }
    if (inputChar === 'e') { editInEditor(cursor); return; }
    if (inputChar === 's') { activate(cursor); return; }
    if (inputChar === 'u') { setMode('upload'); setInput(''); setMessage(''); return; }
    if (inputChar === 'r') { rescan(bank); return; }
    if (inputChar === ']' || inputChar === 'b') { setBank((b) => (b + 1) % BANKS); return; }
    if (inputChar === '[') { setBank((b) => (b - 1 + BANKS) % BANKS); return; }
  });

  // ── Render ────────────────────────────────────────────────────────────────────

  if (status === 'connecting') {
    return html`<${Box} padding=${1}><${Text} color="yellow">Connecting to Electra One…<//><//>`;
  }
  if (status === 'error') {
    return html`
      <${Box} flexDirection="column" padding=${1}>
        <${Text} color="red" bold>Could not connect to the Electra One.<//>
        <${Box} marginTop=${1}><${Text}>${errorMsg}<//><//>
        <${Box} marginTop=${1}><${Text} dimColor>Press q to quit.<//><//>
      <//>`;
  }

  return html`
    <${Box} flexDirection="column" padding=${1}>
      <!-- Header -->
      <${Box} justifyContent="space-between">
        <${Text} bold color="cyan">Electra One ${info ? info.model.toUpperCase() : ''} · fw ${info?.versionText ?? '?'}<//>
        <${Text} dimColor>${info?.serial ?? ''}<//>
      <//>
      <${Box}><${Text} dimColor>${portName}<//><//>

      <!-- Bank + body -->
      <${Box} marginTop=${1}>
        <${Text} bold>Bank ${bank}<//>
        <${Text} dimColor>  ([ / ] to change)<//>
      <//>
      <${Box} marginTop=${1}>
        <${Box} flexDirection="column" width=${30} marginRight=${2}>
          ${slots.map((s) => html`<${SlotRow} key=${s.slot} slot=${s} cursor=${cursor} />`)}
        <//>
        <${Box} flexDirection="column" flexGrow=${1} borderStyle="round" borderColor="gray" paddingX=${1}>
          <${Detail} detail=${detail} loading=${detailLoading} />
        <//>
      <//>

      <!-- Status line -->
      <${Box} marginTop=${1}>
        ${busy
          ? html`<${Text} color="yellow">⏳ ${message}<//>`
          : html`<${Text}>${message || ' '}<//>`}
      <//>

      <!-- Footer -->
      ${mode === 'upload'
        ? html`<${Box} marginTop=${1}><${Prompt} label="Upload JSON file path:" value=${input} /><//>`
        : html`
          <${Box} marginTop=${1}>
            <${Text} dimColor>
              ↑/↓ move · Enter view · ${'p'} pull · ${'e'} edit · ${'u'} upload · ${'s'} activate · ${'r'} rescan · ${'q'} quit
            <//>
          <//>`}
    <//>
  `;
}

export { App };

export function start() {
  // Ink needs a TTY for full-screen + input.
  if (!process.stdout.isTTY) {
    console.error('The TUI needs an interactive terminal (TTY).');
    process.exit(1);
  }
  const app = render(html`<${App} />`);
  return app.waitUntilExit();
}
