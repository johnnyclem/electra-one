# Electra One — native macOS app

A SwiftUI app that connects to a USB Electra One over CoreMIDI and lets you
browse, view, download, edit, upload, and activate presets. Same protocol as
the Node CLI/TUI in the repo root, reimplemented natively (no Node required).

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
