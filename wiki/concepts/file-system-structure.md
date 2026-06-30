---
title: SD Card File System Structure
type: concept
tags: [storage, file-transfer, sd-card]
sources: [api-file-transfer]
updated: 2026-06-30
---

# SD Card File System Structure

Source: [[api-file-transfer]].

## Storage medium
A removable **SD card** holds presets, Lua, and system resources (fonts, graphics,
config). **Firmware is NOT on the SD card** — it lives in separate internal flash.
Card slot is on the enclosure side (under the bottom lid on older MK2 units).
Accessible via **USB Disk mode** in the bootloader (slow; cannot format).

## Layout
```
/
├─ assets/                fonts & graphical data (type: ui)
├─ boot/                  firmware & bootloader updates (location: updates)
├─ cache/                 in-progress file transfers (staged cache)
└─ ctrlv2/
   ├─ captures/<projectId>/   recorded MIDI (.mid)        [[snapshots-and-captures]]
   ├─ lua/<namespace>/        preloaded Lua modules (require-able)
   ├─ presets/<namespace>/    preloaded presets
   ├─ snaps/<projectId>/      snapshots
   ├─ slots/bNN/pNN/          72 preset slots (6 banks × 12)
   └─ configv4.cfg            controller configuration
```
Namespace = developer nickname; developers manage their own folders and can
request inclusion in official releases via Electra support.

## Slot folder contents
`bNN` = bank 00..05, `pNN` = slot 00..11. Each `pNN/` may contain:
`preset.json`, `main.lua`, `devices.json`, `data.json`, `performance.json`, plus
extra `.lua` source files. See [[preset-slots-and-banks]].

## Commit locations ↔ paths
File-transfer `location` enum maps to these areas: `slots` (needs bankNumber+slot,
`path` for extra Lua), `updates` (boot/), `assets`, `modules` (lua/<ns>),
`presets` (presets/<ns>), `root` (config files). Details + `type` enum in
[[api-file-transfer]].

Related: [[operation-and-resource-bytes]], [[lua-extension-overview]].
