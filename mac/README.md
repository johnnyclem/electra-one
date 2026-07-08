# Electra One — native macOS app

A SwiftUI **visual preset editor** for the Electra One. Renders presets like the
device screen (pages, controls laid out by their bounds/color/type), and lets
you build and edit them **with or without hardware connected**. When a device
is attached over USB it also browses, loads, and saves presets on it. Same
protocol as the Node CLI/TUI in the repo root, reimplemented natively over
CoreMIDI (no Node required).

## What it does

- **Visual editor** — a black "screen" canvas draws each control at its real
  `bounds` with its color and a type-specific graphic (fader bar, pad, list).
  Page tabs switch pages. Drag a control to reposition it.
- **Connector arrows** — FigJam/OmniGraffle-style arrows on the canvas. Hover
  (or select) a control and drag from an edge dot to arrow another control, or
  use the inspector's "Link to Page…" to draw an arrow to a floating page pill
  (click the pill to jump to that page). Select an arrow to edit its label and
  color, reverse it, or delete it. Connectors are editor annotations: they save
  into the preset `.json` under a `connectors` key and round-trip through
  files, but are stripped from device uploads (the firmware doesn't know the
  key), and deleting a control removes its arrows.
- **Inspector** — select a control to edit its name, color (Electra palette),
  type, MIDI message (cc7/cc14/nrpn/note/program/…), parameter number, and
  exact position. Add/delete controls. Rename the preset and pages.
- **Offline** — New Preset / Open File… work with no device. Save to a `.json`
  file. Editing preserves every field of the original JSON, so round-tripping
  never corrupts a preset.
- **Imports `.eproj` projects** — open an Electra web-editor project and it's
  converted to the editable preset model: `tiles` → controls, `slotId` →
  pixel bounds + page/control-set/pot, and the embedded Lua script is carried
  along. Saving to the device uploads the preset **and** the Lua.
- **With a device** — browse banks/slots, click a slot to open it in the
  editor, and Save to Device (pick bank/slot) to upload.

## Build & run

```bash
cd mac
./build-app.sh            # release build → ElectraOne.app (ad-hoc signed)
open ./ElectraOne.app
```

For development:

```bash
swift run ElectraOneApp   # run the app directly
swift run e1probe         # headless: connect, read info, scan bank 0
swift build               # compile everything
```

Requires the Swift toolchain (Swift 5.9+/6.x; the Xcode Command Line Tools are
enough — no full Xcode needed). Targets macOS 13+.

## Layout

| Target | Role |
|--------|------|
| `ElectraKit` | MIDI transport (CoreMIDI), SysEx protocol, `E1Device` actor |
| `ElectraOneApp` | SwiftUI front-end (`AppModel`, `ContentView`) |
| `e1probe` | headless connection/scan check for verifying the hardware link |

## How it talks to the device

- **`MIDITransport`** opens the `Electra … CTRL` source/destination once,
  reassembles fragmented SysEx until `F7`, and sends via `MIDISend` (CoreMIDI
  splits large uploads on the wire). Exchanges are serialized by the
  `E1Device` actor.
- **`E1Proto`** builds/decodes the SysEx (manufacturer `00 21 45`). Requests
  use op `0x02`; uploads (op `0x01`) target the **active** slot, so
  `putPreset` arms the slot first with `0x14 0x08 bank slot`. ACK = `7E 01`,
  NACK = `7E 00`; other `7E` codes (e.g. `05`) are notifications and ignored.
- Editing shows the preset JSON in a built-in editor; **Save to Device**
  validates the JSON and uploads it to the slot. Empty slots are detected by a
  zero-length response.
