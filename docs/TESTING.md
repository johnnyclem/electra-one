# Testing

The project has two independent codebases, each with its own unit-test suite.
Both run fully offline — no Electra One hardware required.

## Node CLI / TUI (`lib/`, `bin/`, `tui/`)

Uses the built-in `node:test` runner (no extra dependencies).

```sh
npm test
```

- `test/protocol.test.js` — SysEx framing, message classification, and JSON/text
  decoding (pure functions).
- `test/device.test.js` — the high-level device API, driven through a mock
  transport that records the exact bytes each operation would send and feeds
  back canned responses. Covers slot validation, arm-then-upload ordering,
  empty-slot handling, scan/backup classification, and file I/O helpers.

The hardware-dependent end-to-end render check is kept separate (it needs a
device attached) and is **not** part of `npm test`:

```sh
npm run smoke   # requires a connected Electra One
```

## macOS app (`mac/`)

Uses [swift-testing](https://github.com/apple/swift-testing) via a `.testTarget`
covering the offline layers: `Protocol`, `SlotGeometry`, `PresetDocument`,
project import, `E1Device.summarize`, and the `LuaEngine`.

```sh
cd mac && ./run-tests.sh
```

`run-tests.sh` wraps `swift test`. Under a full Xcode install `swift test` works
directly; with only the Command Line Tools it points the compiler and dynamic
loader at the bundled `Testing.framework`, which the script handles
automatically.

The headless `e1probe` executable remains available for on-device smoke checks
and offline self-tests:

```sh
cd mac && swift run e1probe doc    # offline document-model self-test
cd mac && swift run e1probe lua    # offline Lua-engine self-test
cd mac && swift run e1probe        # full probe (requires a connected device)
```
