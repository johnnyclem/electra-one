# electra-one

Tools for working with the [Electra One](https://electra.one) MIDI controller
without the web editor: a Node.js CLI + terminal UI, and a native macOS
companion app with a live preset editor, Lua script editor, and on-screen
Lua simulator.

Everything talks to the device over USB MIDI SysEx (manufacturer id
`00 21 45`) on the CTRL port. No cloud account required.

## Layout

| Path | What it is |
|---|---|
| `bin/`, `lib/`, `tui/` | Node.js CLI (`e1`) and Ink-based terminal UI |
| `mac/` | Swift package: `ElectraKit` (protocol/device/document), `LuaKit` (embedded Lua simulator), `ElectraOneApp` (SwiftUI app), `e1probe` (headless smoke tool) |
| `presets/` | Sample preset JSON (v2 format) |
| `presets/widgets/` | Vendored known-good widget presets (newer editor schema; see its README) |
| `projects/` | Example `.eproj` editor projects (Eventide H9 Max, Yamaha QY100, Valeton VLP-200 Mini) |
| `scripts/` | Five annotated example Lua scripts (hello world → SysEx patch handler) |
| `wiki/` | LLM-maintained knowledge base on the Electra One platform (SysEx API, preset format, Lua API) |
| `docs/TESTING.md` | How the test suites work |

## Node CLI

Requires Node ≥ 21 and a USB-attached Electra One.

```sh
npm install
node bin/e1.js            # launches the TUI (default command)
node bin/e1.js ports      # list MIDI ports, identify the Electra One
node bin/e1.js info       # firmware / serial / model
node bin/e1.js scan -b 0  # what's in bank 0's 12 slots
node bin/e1.js pull -b 0 -s 1 -o preset.json
node bin/e1.js push preset.json -b 0 -s 1    # .lua files auto-route to push-lua
node bin/e1.js pull-lua -b 0 -s 1
node bin/e1.js backup -b 0 -o backup/
node bin/e1.js switch -b 0 -s 1   # switch AND load a slot
node bin/e1.js clear  -b 0 -s 1   # permanently empty a slot
```

The TUI (`e1` or `npm start`) browses banks/slots, views preset details,
pulls/uploads/activates slots, and can round-trip a preset through `$EDITOR`.

The hardware has **6 banks × 12 slots**; both constants live in
`lib/protocol.js` and are enforced everywhere.

## macOS app

```sh
cd mac
swift run ElectraOneApp     # dev run
./build-app.sh              # bundles ./ElectraOne.app (ad-hoc signed)
```

Features: slot browser, drag-and-drop preset canvas, inspector,
Lua script editor with syntax highlighting, script library, an embedded
Lua simulator (run scripts and paint callbacks without hardware), and
optional AI script generation against any OpenAI-compatible endpoint.

## Testing

```sh
npm test                    # Node unit tests (protocol, device, e2e CLI)
npm run smoke               # TUI render check — needs hardware attached
cd mac && swift test        # Swift package tests (or ./run-tests.sh)
cd mac && swift run e1probe lua   # offline Lua-engine self-test
```

See `docs/TESTING.md` for details.

## License

See `LICENSE`.
