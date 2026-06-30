---
title: Preset Slots, Banks & Slot Files
type: concept
tags: [preset, storage, slots]
sources: [api-sysex, api-file-transfer, json-preset-format]
updated: 2026-06-30
---

# Preset Slots, Banks & Slot Files

Source: [[api-sysex]], [[api-file-transfer]].

## Slot model
- **6 banks × 12 slots = 72 preset slots.** `bankNumber` 0..5, `slot` 0..11.
- On disk: `ctrlv2/slots/bNN/pNN/` (see [[file-system-structure]]).
- Each slot folder may hold up to five files:
  | File | Resource | Format | Page |
  |---|---|---|---|
  | `preset.json` | `0x01` | preset | [[json-preset-format]] |
  | `main.lua` | `0x0C` | lua | [[lua-extension-overview]] |
  | `devices.json` | `0x0F` | deviceList | [[json-device-overrides]] |
  | `data.json` | `0x12` | datafile (persisted Lua table) | — |
  | `performance.json` | `0x11` | performance | [[json-performance-format]] |
  Extra Lua source files can also be added via [[api-file-transfer]].

## Active vs. armed slot
- **Active slot** — the loaded/running preset. Slot queries with no `bank slot`
  default here. Uploads always go to the active slot.
- **Switch Preset Slot** (`0x09 0x08`) — change active slot and load it.
- **Set Preset Slot** (`0x14 0x08`) — *arm* a slot as selected (for subsequent
  file ops) **without** loading it.
- **Reload Preset Slot** (`0x08 0x08`) — terminate & reinitialize the slot's
  preset (+ Lua, device overrides, performance).
- **Load Preloaded Preset** (`0x04 0x08`, `{bankNumber, slot, preset:"ns/path"}`)
  — copy a preloaded preset into a slot and activate it.

## Identity & integrity
- **projectId** — external id stored in the preset; ties a preset to snapshots,
  captures, and editor metadata. See [[snapshots-and-captures]].
- **Preset slot info** (`0x02 0x08`) and **location files** queries return per-file
  **MD5** digests; MD5 also gates [[api-file-transfer]] commits.
- **Preset list** (`0x02 0x04`) returns the current slot plus each preset's
  `name`, `projectId`, `hasLua`, `isPinned`.

## Preloaded content
`ctrlv2/presets/<namespace>/` and `ctrlv2/lua/<namespace>/` hold preloaded
presets and Lua modules (namespace = developer nickname). Provisioned via USB disk
mode or file transfer; loaded with Load Preloaded Preset / Lua `require`.

Related: [[operation-and-resource-bytes]], [[devices-and-ports]].
