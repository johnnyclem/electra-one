---
title: "Source: Device Overrides Format"
type: source
tags: [json, devices, format, overrides]
raw: ../docs/JSON-DeviceOverrides.pdf
updated: 2026-06-30
---

# Source — Device Overrides Format Description

Faithful summary of `docs/JSON-DeviceOverrides.pdf` (3 pp.). Stored as
`devices.json` in a preset slot. A **device override** lets a user remap the MIDI
**ports and channels** of a preset's devices **without editing the preset
itself** — adapting a shared preset to local hardware. Uploaded/queried via
[[api-sysex]] resource `0x0F`.

> ⚠️ Source mislabels itself: the prose header/intro is copy-pasted from the
> Performance doc ("describes the format of the Electra One Performance file…").
> The actual schema described is **devices**, not performance. Treat the device
> schema below as authoritative.

## Format
```json
{ "version": 1,
  "devices": [
    { "id": 1, "name": "My MKS-50", "instrumentId": "roland-mks50",
      "port": 1, "channel": 1, "rate": 20 },
    { "id": 2, "name": "BeatFX plugin", "instrumentId": "generic-MIDI",
      "port": 2, "channel": 1 } ] }
```
- **version** (mandatory, numeric) — this doc is version 1.
- **devices[]** (mandatory) — each a hardware or software MIDI device.

## Device fields
- `id` (mandatory) 1..16 — referenced by other objects.
- `name` (mandatory) string, length 0..20.
- `port` (mandatory) 1..2 — the internal MIDI bus. **Port 1** ties together MIDI
  IO 1 + USB Host 1 + USB Device 1; **Port 2** ties IO 2 + USB Host 2 + USB Dev 2.
- `channel` (mandatory) 1..16.
- `rate` (seen in examples, e.g. SysEx Get response) — min inter-message delay (ms).

Electra handles up to 16 simultaneous devices; you always address a **device**,
never a raw port/channel. See [[devices-and-ports]] and the device fields in
[[json-preset-format]].
