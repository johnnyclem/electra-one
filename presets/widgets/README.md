# Custom-control demo presets (script-drawn widgets)

21 **known-good, upload-as-is** Electra One presets whose controls draw their own
graphics via Lua `setPaintCallback` — the thing native faders/knobs/pads can't do.
Use these to see custom controls actually rendering on the hardware, and as
reference for the exact working preset format.

Vendored from the community library **[roomi-fields/electraone-widgets]** (MIT — see
`UPSTREAM-LICENSE`). Screenshots are the `<name>.png` files next to each preset.

[roomi-fields/electraone-widgets]: https://github.com/roomi-fields/electraone-widgets

## How to upload

These use the current Electra editor schema (`schemaVersion` + a `tiles` array +
the Lua bundled into a `lua` field). **This companion app can't push them yet** —
it writes the older `controls`/`version:2` schema. Upload them the proven way:

1. Open **https://app.electra.one** (or beta.electra.one) in a browser.
2. **Preset → Import** and choose one of the `*.preset.json` files here.
3. **Send to Electra** — the custom control draws on the device.

## Start here

- **`gallery-primitives.preset.json`** and **`theme-gallery.preset.json`** — single
  presets that draw many primitives/theme elements at once (the best "show me
  everything" demos).
- **`lua-xy-pad.preset.json`** / **`xypad.preset.json`** — the smallest, clearest
  examples of wiring `paint` + `touch` + `pot` callbacks on one custom control.
- **`modern-adsr.preset.json`** — a script-drawn replacement for the native ADSR.

## The working custom-control format (what makes them draw)

Confirmed from these files — the four things this app was getting wrong:

- The tile is `"type": "custom"` with a **`"virtual"`** value message (not `cc7`).
- The paint callback is registered in **`preset.onLoad()`**, then **`:repaint()`**
  is called to force the first paint.
- Drawing coordinates are **local** to the control (`0,0` = its top-left).
- The Lua is delivered in the newer `tiles`/`schemaVersion` preset schema.

## All widgets

| Preset | What it draws |
|---|---|
| arp-viz | Scrolling piano-roll view of a running arpeggiator (3-octave). |
| comp-meter | Three-column VU (In / Gain Reduction / Out) with threshold line. |
| cube-lfo | Rotating 3D wireframe cube; sends the projected vertex X/Y as an LFO. |
| eg-template | Envelope generator on the native 4-stage `dx7envelope` tile. |
| eq-3band | 3-band parametric EQ with a live response curve. |
| gallery-primitives | Every implemented primitive (knob, bar, led, …) in multiple states. |
| loopop-tombola | OP-1-style physics sequencer — balls bounce in a rotating hexagon. |
| lua-xy-pad | Reference XY pad wiring paint + touch + pot on one control. |
| metronomes | Six bouncing-ball visual metronomes, one per row. |
| midi-multi-env | Multi-stage envelope editor (8-point wave + key-on/off modes). |
| mini-cube-lfo | Compact variant of cube-lfo. |
| modern-adsr | Flat/modern live ADSR envelope (replaces native `dx7envelope`). |
| multi-env-encoders | Six-point envelope edited entirely via encoders. |
| note-list-16 | 16-step note-list editor (Waldorf Q-style arpeggiator). |
| send-lfo | Free-running LFO with a built-in oscilloscope. |
| spatial-pan | Top-down circular pan visualisation (VR / Atmos style). |
| step-seq-16 | Two parallel 16-step drum lanes at the same tempo. |
| tape-meter | Mastering-style LUFS + True-Peak meters with peak-hold. |
| theme-gallery | Every Theme palette entry + `Theme.card` primitive + lines. |
| xt-envelopes | paint / touch / pot callback demo (Waldorf XT-style envelopes). |
| xypad | Minimal two-axis touch pad updating two normalised values. |
