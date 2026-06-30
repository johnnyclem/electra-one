---
title: Lua Extension Overview
type: concept
tags: [lua, scripting]
sources: [api-lua-extension, api-sysex, json-preset-format]
updated: 2026-06-30
---

# Lua Extension Overview

Synthesis of [[api-lua-extension]] with hooks from [[json-preset-format]] and
[[api-sysex]].

## Mental model
The **JSON preset is declarative** and pre-loads everything; **Lua is the runtime
layer** that manipulates those existing objects. Lua **cannot create preset
objects** (pages/controls/groups/overlays) — but can modify, reposition, hide, and
recolor them, and can create **Devices** (`devices.create`) and **data pipes**.

## Where Lua plugs in
- **Value hooks** in the preset: `formatter` (format display string) and
  `function` (react to value change). See [[controls-values-and-messages]].
- **Standard callbacks**: `preset.onLoad`/`onReady`, `patch.onRequest`,
  `midi.on*` (per message type + generic `onMessage`), `events.onPageChange`/
  `onPotTouch`, custom-control `paint`/`touch`/`pot` callbacks.
- **Remote execution**: SysEx `0x08 0x0D <lua-text>` runs arbitrary Lua — best
  used to *call* predefined functions, not ship large code.

## Module map (quick index)
`controls`/Control · `controller` (model/firmware/uptime/`require`) · `pipe`
([[data-pipes-and-modulation]]) · `devices`/Device ([[devices-and-ports]]) ·
`events` · `graphics` (paint callbacks) · `groups`/Group · `helpers`
(slot↔bounds) · `info` (status bar) · `logger` (`print`) · `Message` ·
`midi` callbacks + `midi.send*` · `parameterMap` · `patch` · `preset` lifecycle ·
`SysexBlock` (`getLength`, `peek`) · `System` · `timer` · `transport` (clock/
start/stop) · `Value` formatters & callbacks · `window`.

## Init order (first load)
global code → `preset.onLoad()` → value-linked functions (default JSON values) →
`preset.onReady()` → event listening. Re-selecting an initialized preset does not
re-init.

## Performance & logging notes
- Don't define empty `midi.on*` callbacks — registration adds overhead.
- Logger is **off by default**; `print()` (prefixed `lua:`) is CTRL-port SysEx
  with a timestamp. See [[request-response-handshake]].
- Only `PAGES` and `POTS` event subscriptions are currently supported.

## ⚠️ Contradiction to resolve
Max length of a single executed Lua command: **65,353 bytes** ([[api-lua-extension]])
vs **65,535 bytes** ([[api-sysex]] Execute Lua command). Both agree commands
<65 bytes run significantly faster. Verify against firmware; flagged for lint.

Related: [[entities/firmware-4-0]], [[file-system-structure]] (multi-file Lua via
`require`).
