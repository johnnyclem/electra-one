---
title: "Source: Preset Format"
type: source
tags: [json, preset, format]
raw: ../docs/JSON-PresetFormat.pdf
updated: 2026-06-30
---

# Source — Preset Format Description

Faithful summary of `docs/JSON-PresetFormat.pdf` (24 pp.). The `preset.json` file
holds the **complete definition** of an Electra One preset — nothing else needs
to be transferred to run it. JSON schema is published on GitHub. **Minify before
transfer** over USB MIDI for speed. Current `version` is 2.

## Top-level objects
```json
{ "version": 2, "name": "ADSR Test", "projectId": "d8Wj…",
  "pages": [], "devices": [], "overlays": [], "groups": [], "controls": [] }
```
- **version** (mandatory, numeric) · **name** (≤20) · **projectId** (optional ≤20,
  links external metadata in the editor).
- **pages** (mandatory): `{id 1..12, name ≤20, defaultControlSetId 1..3?}`.
- **devices** (mandatory): see [[devices-and-ports]] / [[json-device-overrides]].
  `{id 1..16, name, instrumentId, port 1..2, channel 1..16, rate 10..1000?}`.
- **overlays** (optional): label/symbol lists. `{id 1..51, items:[{value 0..16383,
  label ≤20, bitmap?}]}`. `bitmap` = base64 XBM, **48×18**.
- **groups** (optional): visual separators. `{id 1..1023, pageId 1..12, name ≤40,
  bounds [x,y,w,h], color RGB888 (→RGB565), variant default|highlighted}`.
- **controls** (mandatory): see below.

## Control
A control represents one or more MIDI parameters/messages (fader, list, pad,
ADSR…). Key fields:
- `id` 1..1023 · `type` enum **fader | list | pad | vfader | adsr | adr |
  dx7envelope** · `name` ≤14 (omit/empty ⇒ hidden + no touch indication) ·
  `color` RGB888 · `variant` default|thin|outline|valueOnly|dial ·
  `mode` default|unipolar|bipolar|momentary|toggle · `bounds [x,y,w,h]` ·
  `pageId` 1..12 · `controlSetId` 1..3 (default 1) · `visible` (default true).
- **inputs[]** (optional): `{potId 1..12, valueId}` — binds a physical pot to a value.
- **values[]** (mandatory): one or more, see Value.

## Value
Maps a display value to a MIDI parameter/message; handles MIDI↔display translation.
- `id` (default `"value"`, ≤20) · `min`/`max`/`defaultValue` (−16383..16383,
  **display** range, not MIDI) · `overlayId` (list items / fader labels) ·
  `formatter` (Lua fn name, one arg → formatted string) · `function` (Lua fn,
  args `controlId, value`, called on display-value change) · `message` (mandatory).
  Lua hooks documented in [[api-lua-extension]].

## Message
Describes the MIDI message sent on change and parsed on receive.
- `deviceId` (→ devices array) · **type** enum: `cc7, cc14, nrpn, rpn, SysEx,
  note, program, start, stop, tune, atpoly, atchannel, pitchbend, spp`.
- `parameterNumber` 0..16383 (14-bit: param/note/program/pressure/pitchbend/spp).
- `min`/`max` 0..16383 (**MIDI** range, mapped to value's display min/max).
- `data[]` (SysEx templates): bytes + placeholder objects, e.g.
  `{"type":"value","rules":[{"parameterNumber":40,"bitPosition":0,"bitWidth":3}]}`.
- `onValue`/`offValue` (state controls like Pad; undefined ⇒ no transmit).
- `lsbFirst` (swap LSB/MSB for cc14/nrpn) · `signMode` none|twosComplement|signBit ·
  `bitWidth` 1..14 (default 7 or 14 by type; sign-bit placement for negatives).

Detailed object model synthesized in [[controls-values-and-messages]]. Related
formats: [[json-performance-format]], [[json-device-overrides]].
