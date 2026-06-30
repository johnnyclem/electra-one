---
title: "Source: Performance Format"
type: source
tags: [json, performance, format, macro, modulation]
raw: ../docs/JSON-PerformanceFormat.pdf
updated: 2026-06-30
---

# Source — Performance Format Description

Faithful summary of `docs/JSON-PerformanceFormat.pdf` (10 pp.). Stored as
`performance.json` in a preset slot. A **performance** adds an extra page that
gathers a customized selection of an associated preset's controls into one
layout — and enables **macro controls** and **modulation** — **without modifying
the preset**. Introduced in fw 4.0; format `version` 1; evolving. The performance
references the preset's controls/values by id and lives in the same slot.
Uploaded/queried via [[api-sysex]] resource `0x11`.

## Top level
```json
{ "version": 1, "references": [], "groups": [] }
```

## references[] (mandatory)
Each reference is a control on the performance page, positioned by
`controlSetId` (1..3) + `potId` (1..12). It points to a preset control via either:
- **Simple reference** — `controlId` (1..1023): one preset control.
- **Multi-reference** — `valueRefs[]` (up to 16 control values): macro/modulation;
  **must** include a `name` (≤14) since it can't be auto-derived.

### valueRef
`{ controlId, valueId (default "value"), mode, … }`. Up to 16 values driven by
one pot or modulation source. **mode** enum:
- `setValue` — map control value range to full 0..127 of the reference. No params.
- `modulate` — apply modulation on top of the current value (macro-knob style,
  like Elektron). Requires `depth`.
- `dataPipe` — modulate from a [[data-pipes-and-modulation|data pipe]] stream.
  Requires `pipe: { name, bankNumber 0..5, slot 0..11 }` identifying the source
  preset's named pipe output.

## groups[] (optional)
Visual separators, independent from preset groups (no `id`/`pageId`).
`{ name ≤40, bounds [x,y,w,h], color RGB888 (default FFFFFF), variant
default|highlighted }`. height 0 ⇒ thin line, else rectangle.

> Note: the full example at the doc's end shows `groups` entries that *do* carry
> `id`/`pageId` (mirroring preset groups), inconsistent with the per-field spec
> that says performance groups omit them. Flagged for lint. See
> [[json-performance-format]] vs [[json-preset-format]] group definitions.

Related: [[controls-values-and-messages]], [[data-pipes-and-modulation]],
[[json-preset-format]].
