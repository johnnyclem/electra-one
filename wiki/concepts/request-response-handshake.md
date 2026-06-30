---
title: Request / Response Handshake & Events
type: concept
tags: [sysex, protocol, events]
sources: [api-sysex, api-file-transfer]
updated: 2026-06-30
---

# Request / Response Handshake & Events

Source: [[api-sysex]]. Frame: [[sysex-message-structure]].

## Two request categories
- **Data Query** (`0x02`) — read-only. Response is a **data dump** (`0x01
  <resource> <json> 0xF7`).
- **Command** — mutates state. Response is **ACK** or **NACK**, never data.

## ACK / NACK
```
ACK :  0xF0 00 21 45 7E 01 <txn-lsb> <txn-msb> 0xF7
NACK:  0xF0 00 21 45 7E 00 <txn-lsb> <txn-msb> 0xF7
```
- `0x7E` = controller event; `0x01` ACK / `0x00` NACK.
- Transaction id echoed (split 7-bit). If the command carried no txn id, `0x00
  0x00` is returned. Lets a host match responses to async/out-of-order commands.

## Controller events (device → host, `0x7E <code>`)
Keep the host in sync with on-device actions. Triggered by user actions OR as
responses to SysEx commands. **User-driven** events default to the **CTRL** port
(changeable via Set Events Port `0x14 0x7B`); **command-response** events always
return on the port the command arrived on.

| Code | Event | Payload |
|---|---|---|
| `0x01`/`0x00` | ACK / NACK | txn id |
| `0x02` | Preset switch | bank, slot |
| `0x03` | Snapshot list change / snapshot change | — |
| `0x04` | Snapshot bank switch | bank |
| `0x05` | Preset list change | — |
| `0x06` | Page switch | page (0..11) |
| `0x07` | Control Set switch | set (0..2) |
| `0x08` | Preset bank switch / USB host change | bank / — |
| `0x0A` | Pot touch | potId, controlId lsb/msb, touched |
| `0x2D` | File transfer progress | size (4×7-bit) |
| `0x31` | Capture list change | — |

## Subscriptions
Some events require opt-in via **Subscribe Events** (`0x14 0x79 <flags>`, OR
bits): Page(0x01), Control Set(0x02), USB Host(0x04), Pots(0x08), Touch(0x10),
Button(0x20), Window(0x40). **Currently only Page and Pots are supported.** From
Lua, use `events.subscribe(PAGES | POTS)`. See [[lua-extension-overview]].

## MIDI Learn
Enable with `0x03 0x01`. While active, normal MIDI processing is suspended and
every incoming message on user ports is reported as JSON
(`{port,msg,channel,parameterId,value}` or `{port,msg:"sysex",data:[…]}`).

## Logging
Log messages: `0x7F 0x00 "<ms-since-boot> <text>"`. Lua `print()` output is always
sent (prefixed `lua:`); firmware logs gated by the non-volatile logger flag +
level (0 critical … 3 tracing). Logger port set separately (`0x14 0x7D`), default CTRL.

Related: [[operation-and-resource-bytes]], [[snapshots-and-captures]],
[[file-system-structure]].
