---
title: Controls, Values, Inputs & Messages
type: concept
tags: [preset, controls, midi, model]
sources: [json-preset-format, api-lua-extension, json-performance-format]
updated: 2026-06-30
---

# Controls, Values, Inputs & Messages

The core preset object model, synthesized from [[json-preset-format]] and the
runtime view in [[api-lua-extension]].

## Hierarchy
```
Preset
 └─ Control (id 1..1023; fader|list|pad|vfader|adsr|adr|dx7envelope)
     ├─ inputs[]  {potId 1..12, valueId}        ← physical pot ↔ value binding
     └─ values[]  (one per parameter)
          ├─ display: min/max/defaultValue (−16383..16383), overlayId
          ├─ Lua hooks: formatter(value)→str, function(controlId,value)
          └─ Message (the MIDI side)
```

## Value
A **display-level** parameter instance. `min/max/defaultValue` are *display*
values (not MIDI). `overlayId` swaps numeric values for labels/symbols (see
overlays in [[json-preset-format]]). Two Lua hooks (function names resolved in the
preset's Lua script):
- `formatter` — one arg `(value)`, returns a formatted string for display.
- `function` — args `(controlId, value)`, runs on every display-value change.

## Message
The **MIDI-level** mapping; sent on change and matched on receive.
- `type`: `cc7, cc14, nrpn, rpn, SysEx, note, program, start, stop, tune, atpoly,
  atchannel, pitchbend, spp`.
- `parameterNumber` 0..16383 (14-bit; overloaded by type).
- `min`/`max` are the **MIDI** range, mapped to the Value's display range.
- State controls (Pad): `onValue`/`offValue` (undefined ⇒ no transmit).
- 14-bit handling: `lsbFirst`, `signMode` (none|twosComplement|signBit),
  `bitWidth` 1..14.
- SysEx templates: `data[]` mixes literal bytes with placeholder objects like
  `{"type":"value","rules":[{parameterNumber,bitPosition,bitWidth}]}`.

## Runtime (Lua)
`controls.get(id)` returns a Control userdata: read/modify visibility, name,
color, variant, bounds, pot/slot, and reach Values (`getValue(valueId)`) and their
`Message` objects. The global **parameterMap** holds current MIDI values
(`parameterMap.set(deviceId, type, parameterNumber, value)`). Lua can reposition,
recolor, hide/show, and reassign controls — but **cannot create** new controls.

## Layout primitives
- **bounds** `[x, y, width, height]`; helpers `slotToBounds`/`boundsToSlot`.
- **slot** — page 6×6 grid position 1..36 (`setSlot`).
- **controlSetId** 1..3 + **potId** 1..12 — which of the three pot rows a control
  binds to; only one control set active at a time.

## Performance reuse
A [[json-performance-format|performance]] references these controls/values by
`controlId`/`valueId` to build macro/modulated controls on a separate page —
without editing the preset. See [[data-pipes-and-modulation]].

Related: [[devices-and-ports]], [[preset-slots-and-banks]].
