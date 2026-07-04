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
- `test/e2e-cli.test.js` — true end-to-end: spawns the real `bin/e1.js` as a
  subprocess with `test/helpers/mock-midi.cjs` preloaded (a drop-in `midi`
  replacement simulating an attached Electra One), and asserts on stdout, exit
  codes, written files, and the exact SysEx frames put on the wire — including
  fragmented-response reassembly, switch (0x09) vs arm (0x14) opcodes, and
  validation failing before anything is sent.

The hardware-dependent end-to-end render check is kept separate (it needs a
device attached) and is **not** part of `npm test`:

```sh
npm run smoke   # requires a connected Electra One
```

## macOS app (`mac/`)

Uses [swift-testing](https://github.com/apple/swift-testing) via two
`.testTarget`s:

- `ElectraKitTests` — the offline layers: `Protocol`, `SlotGeometry`,
  `PresetDocument`, project import, the `LuaEngine`, and `E1Device` driven
  through an injected mock `E1TransportProtocol` (getInfo decode, empty-slot
  throws, scan classification).
- `ElectraOneAppTests` — app/UI logic: the editor↔document Lua sync and the
  UI-driven Lua generation flows (Custom-control paint callbacks compile and
  produce draw ops, script-button wrappers, paint-render caching, stale-script
  clearing when switching presets). Backed by a temp script library so tests
  never touch the user's real one.

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
