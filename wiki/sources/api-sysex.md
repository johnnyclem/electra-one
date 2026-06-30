---
title: "Source: SysEx Implementation"
type: source
tags: [sysex, api, protocol]
raw: ../docs/API-SysEx.pdf
updated: 2026-06-30
---

# Source — SysEx Implementation

Faithful summary of `docs/API-SysEx.pdf` ("SysEx implementation | Electra One
Documentation", 55 pp.). The Electra One can be **configured, programmed, and
fully controlled over MIDI SysEx**; the web editor at app.electra.one is built
entirely on this same API. Requires **firmware 4.0+**. See cross-cutting pages:
[[sysex-message-structure]], [[operation-and-resource-bytes]],
[[request-response-handshake]].

## Fundamentals
- **Byte notation**: all values hex `0xNN` unless stated decimal.
- **Manufacturer Id**: `0x00 0x21 0x45` (MIDI Association id for Electra One s.r.o.).
  Must begin every message to the controller.
- **Management port**: prefer the **Electra Controller CTRL** port (Windows
  `MIDIIN3`, Linux `PORT 3`). Responses always return on the port the request arrived on.
- **Handshake**: requests are either **Data Queries** (read-only) or **Commands**
  (mutate state). Queries return JSON; Commands return **ACK** (`0x7E 0x01`) or
  **NACK** (`0x7E 0x00`).
- **Transaction Id** (optional, fw 4.0+): inserted right after the manufacturer
  id as `0x00 <lsb> <msb>` (7-bit split). Echoed back in ACK/NACK so async
  responses can be matched. Id 4183 → `0x00 0x77 0x20`.
- **Message shape**: `0xF0 <mfr-id> [0x00 <txn>] <operation> <resource> <payload> 0xF7`.
  Payloads are binary, JSON (ASCII, strict 7-bit), or mixed.

## Operations (first byte after id/txn)
`0x01` upload · `0x02` request (query) · `0x03` MIDI learn · `0x04` update
(persistent) · `0x05` remove · `0x06` swap · `0x08` execute · `0x09` switch ·
`0x14` updateRuntime · `0x7E` controller-event (from device) · `0x7F` system call.
Full table in [[operation-and-resource-bytes]].

## Queries (operation `0x02`) — return JSON dumps (`0x01 <resource> …`)
| Resource | Returns |
|---|---|
| `0x7F` Electra info | `versionText`, `versionSeq`, `serial`, `hwRevision` |
| `0x7E` runtime info | `{ "freePercentage": 85 }` |
| `0x01` preset | preset.json (same format as upload). Optional `bankNumber slot` |
| `0x0C` Lua script | `main.lua` source text |
| `0x0F` device overrides | devices.json (see [[json-device-overrides]]) |
| `0x12` persisted data | data.json (Lua table saved with `persist()`) |
| `0x11` performance | performance.json (see [[json-performance-format]]) |
| `0x02` configuration | config JSON (router, presetBanks, usbHostAssigments, midiControl) |
| `0x04` preset list | current slot + array of presets (`hasLua`, `isPinned`, `projectId`) |
| `0x08` preset slot info | slot meta + `files[]` with md5 per file |
| `0x05` snapshot list | by `projectId` |
| `0x03` snapshot data | by projectId/bank/slot → `parameters[]` |
| `0x31` capture list / `0x30` capture data | captures (packed 7-bit SMF) |
| `0x10` USB host devices | connected USB host devices, ports, vid/pid |

Most slot queries default to the **active slot** if no `bankNumber slot` given.
Banks are `0..5`, slots `0..11`.

## Uploads (operation `0x01`) → ACK/NACK, always to **active** slot
`0x01` preset · `0x0C` Lua script (`main.lua`) · `0x0F` device overrides ·
`0x12` persisted data · `0x11` performance · `0x02` configuration. Uploaded
preset/Lua is activated immediately.

## Persistent commands (survive reboot)
- **Remove** (`0x05`): preset `0x01`, Lua `0x0C`, config `0x02`, snapshot `0x06`,
  capture `0x32`. Bank/slot or JSON id payloads.
- **Update** (`0x04`): snapshot/capture attributes (name, color); **Load
  preloaded preset** (`0x04 0x08` with `{bankNumber, slot, preset:"ns/path"}`).
- **Swap** (`0x06`): snapshots/captures between slots (empty target ⇒ move).

## Runtime commands (lost on reboot)
- **Switch** (`0x09`): preset slot `0x08`, page `0x0A` (0..11), control set `0x0B` (0..2).
- **Execute** (`0x08`): **Run Lua command** `0x08 0x0D <lua-text>` (max 65,535 B;
  keep <65 B fast; prefer calling predefined functions). Reload preset slot `0x08 0x08`.
- **Update runtime** (`0x14`): Set preset slot `0x08` (arms slot, no load);
  Set snapshot/capture slot; **Update control** `0x07 <id-lsb> <id-msb> <json>`
  (name/color/visible/value, controlId split into 7-bit MSB/LSB);
  **Override value text** `0x0E` (perf-optimized, numeric value-id table 0x00–0x08);
  **Set bottom bar text** `0x77` (≤40 chars); **Set events port** `0x7B`
  (0=Port1,1=Port2,2=CTRL); **Subscribe events** `0x79` (bit flags); **Set logger port** `0x7D`.
- **System** (`0x7F`): logger on/off + level `0x7D` (level 0 critical…3 tracing);
  window repaint `0x7A`; reboot `0x78`. Lua debug `0x7C`. MIDI learn `0x03`.

## Subscribe-events flags (`0x14 0x79 <flags>`, OR together)
bit0 Page, bit1 Control Set, bit2 USB Host, bit3 Pots, bit4 Touch, bit5 Button,
bit6 Window. **Only Page and Pots events currently supported.** Reset with `0x00`.

## Controller events (device → host, `0x7E …`)
ACK `0x01` / NACK `0x00` (carry txn id) · preset switch `0x02` · snapshot list
change `0x03` · capture list change `0x31` · pot touch `0x0A`
(`pot-id, control-id-lsb/msb, touched`) · preset list change `0x05` · page switch
`0x06` · control-set switch `0x07` · preset-bank switch `0x08` · snapshot bank
switch `0x04`. Default routed to CTRL (changeable via Set Events Port).

- **MIDI learn** (`0x03 <json>`): when enabled, every incoming MIDI msg on user
  ports is reported as JSON (`port,msg,channel,parameterId,value` or
  `msg:"sysex", data:[…]`). Normal processing is suspended while active.
- **Log message** (`0x7F 0x00 <text>`): `"<ms-since-boot> <text>"`. Lua `print()`
  output always sent; firmware logs gated by logger flag/level.

See [[api-file-transfer]] for chunked/atomic multi-file transfer that extends this API.
