---
title: Controller Hardware
type: entity
tags: [hardware, models, ports]
sources: [api-sysex, api-file-transfer, api-lua-extension]
updated: 2026-06-30
---

# Controller Hardware

What the docs reveal about the physical Electra One. Sources: [[api-sysex]],
[[api-file-transfer]], [[api-lua-extension]].

## Models
Lua `controller.getModel()` → `mk2` | `mini`. Numeric globals:
`MODEL_ANY`, `MODEL_MK1`, `MODEL_MK2`, `MODEL_MINI_MK1`. **hwRevision** is reported
by Get Electra info (e.g. `"3.0"`), distinct from firmware version.

## Front-panel controls
- **12 pots (knobs)** — numbered 1 (top-left) … 12 (bottom-right); Lua `POT_1..12`.
  Touch-sensitive (Pot Touch events).
- **3 control sets** — three rows of 12; only one active at a time; switch via
  buttons, touchscreen, or MIDI. Lua `CONTROL_SET_1..3`.
- **Pages** — up to 12 per preset; **6×6 grid** of 36 slots per page for control
  layout (`setSlot` 1..36). Buttons (`BUTTON_1` … referenced in examples).
- **Touchscreen** with a bottom **status bar** (preset/page name; overridable via
  Set Bottom Bar Text or Lua `info.setText`).

## I/O
- **MIDI IO 1/2**, **USB Host 1/2**, **USB Device 1/2**, bridged into logical
  **Port 1 / Port 2**; plus the **CTRL** management port. See [[devices-and-ports]].
- **SD card** for storage (firmware in separate internal flash). See
  [[file-system-structure]].

## Memory
- 72 preset slots (6 banks × 12). **Get runtime info** (`0x02 0x7E`) reports
  `freePercentage`. `controller.uptime()` gives ms since reset.

Related: [[entities/firmware-4-0]], [[preset-slots-and-banks]].
