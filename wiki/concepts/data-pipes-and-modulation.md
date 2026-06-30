---
title: Data Pipes & Modulation
type: concept
tags: [modulation, performance, lua, data-pipe, macro]
sources: [json-performance-format, api-lua-extension]
updated: 2026-06-30
---

# Data Pipes & Modulation

How values get combined and modulated across controls and presets. Sources:
[[json-performance-format]], [[api-lua-extension]].

## Performance value-ref modes
A [[json-performance-format|performance]] multi-reference (`valueRefs[]`, up to 16
values per pot/source) links preset control values to one performance control. Each
value uses a **mode**:
- **setValue** — straight map of the value's range onto the reference's full
  0..127. No extra params. (Macro that sets several params together.)
- **modulate** — add modulation to the value's *current* value; requires `depth`.
  Like Elektron macro knobs (base value + modulation amount).
- **dataPipe** — modulate from a named **data pipe** stream produced by another
  preset; requires `pipe: { name, bankNumber 0..5, slot 0..11 }`.

## Data pipes (Lua)
A **data pipe** is a named channel: one preset streams floating-point numbers,
others receive them — enabling cross-preset interaction (e.g. an LFO preset
driving knobs in another preset) without coupling their internals.

```lua
local id = pipe.acquire("output")   -- create a named pipe (returns pipeId)
pipe.send(id, value)                -- push a float to all listeners
pipe.release(id)                    -- free the pipeId
```
The performance `pipe.name` must match the producing preset's pipe output name;
`bankNumber`/`slot` locate that producer preset. See [[preset-slots-and-banks]].

## Macro controls
Build a macro by giving one performance pot a `valueRefs[]` array spanning several
controls (mix of `setValue`/`modulate`/`dataPipe`). The reference needs an explicit
`name` (can't be auto-derived from multiple values).

Related: [[controls-values-and-messages]], [[json-performance-format]].
