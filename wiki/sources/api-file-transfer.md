---
title: "Source: File Transfer SysEx API"
type: source
tags: [sysex, api, file-transfer, storage]
raw: ../docs/API-FileTransfer.pdf
updated: 2026-06-30
---

# Source — File Transfer SysEx API

Faithful summary of `docs/API-FileTransfer.pdf` (10 pp.). An **extension of the
core [[api-sysex|SysEx Implementation]]** for uploading, downloading, listing,
and deleting files inside the controller — chunked transfer, MD5 integrity, and
multi-file Lua projects. Requires **firmware 4.0+**. Same message structure as
the base API.

## Internal storage
Files live on a removable **SD card** (side slot; under bottom lid on older MK2).
Firmware itself is in separate internal flash, not on the SD card. See
[[file-system-structure]] for the full layout.

Key tree:
```
ctrlv2/
  captures/   (by projectId)        lua/      (preloaded modules, ns subfolders)
  presets/    (preloaded, ns)       slots/    (b00..b05 / p00..p11)
  snaps/      (by projectId)        configv4.cfg
assets/  boot/  cache/
```
Each `slots/bNN/pNN/` may contain: `preset.json`, `main.lua`, `devices.json`,
`data.json`, `performance.json`.

**USB Disk mode** (bootloader): SD card appears as a drive, but it is not a full
mass-storage device — slow, and cannot format the card.

## Transfer protocol — staged cache (atomic, multi-file)
Files are streamed into a **transfer cache**, verified, then moved to final
locations as one all-or-nothing transaction.

1. **Open cache** — `0x01 0x2D`. Clears any prior/unfinished transfer.
2. **Register file** — `0x01 0x2E <file-id> <size0..3>`. `fileId` 0..127; size is
   4×7-bit little-endian (`size0 = size & 0x7F`, `size1 = (size>>7)&0x7F`, …).
   Repeat per file.
3. **Transfer chunk** — `0x01 0x2F <file-id> <7-bit-data>`. Arbitrary length;
   remaining total decremented; progress reported via event.
4. **Commit** — `0x04 0x2D <commit-json>`. Verifies each file's MD5; on mismatch
   the **whole** distribution is cancelled (files stay in cache).

### Commit JSON
```json
{ "files": [ {
  "id": 1, "location": "slots", "type": "luaModule",
  "path": "test", "bankNumber": 0, "slot": 0,
  "md5": "1c40e4876067a51b9ed5ee73b7a32f09" } ] }
```
- **location** enum: `slots`, `updates` (boot/firmware), `assets`, `modules`
  (preloaded Lua), `presets` (preloaded presets), `root` (config files).
  - `slots` needs `bankNumber` (0..5) + `slot` (0..11); extra Lua files need
    `path` (plain filename, no `.lua`, no subfolders).
  - `modules`/`presets` need `namespace` + `path`.
- **type** enum: `firmware`, `bootloader`, `preset`, `lua`, `luaModule`, `ui`,
  `config`, `deviceList`, `datafile`, `performance`.
- **md5**: integrity digest over the transferred file.

## Query files
- **Get location files** — `0x02 0x34 <location-query-json>` → `0x01 0x34` JSON
  with `path`, `exists`, `files[]` (name + md5). Query e.g.
  `{"location":"slots","bankNumber":0,"slot":0}`.
- For slots only, the simpler [[api-sysex|Preset Slot Information]] query also works.

## Remove files
- **Remove from location** — `0x05 0x34 <location-query-json>` deletes all files
  in a location (same JSON shape as the query). For slots only, base API's
  Clear Preset Slot also works.

## Events
- **Report progress** — `0x7E 0x2D <size0..3>`: bytes transferred so far
  (reconstruct: `size0 + (size1<<7) + (size2<<14) + (size3<<21)`). Combine with
  registered total size to compute %. Default routed to CTRL.

Related: [[api-sysex]], [[file-system-structure]], [[lua-extension-overview]]
(multi-file Lua projects loaded via `require`).
