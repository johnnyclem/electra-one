---
title: SysEx Message Structure
type: concept
tags: [sysex, protocol]
sources: [api-sysex, api-file-transfer]
updated: 2026-06-30
---

# SysEx Message Structure

How every Electra One management message is framed. Source: [[api-sysex]].

## Anatomy
```
0xF0  <manufacturer-id>  [0x00 <txn-lsb> <txn-msb>]  <operation>  <resource>  <payload…>  0xF7
```
- `0xF0` / `0xF7` — SysEx start/end.
- **Manufacturer id** — `0x00 0x21 0x45` (Electra One s.r.o., assigned by MIDI
  Association). Mandatory first bytes after `0xF0`.
- **Transaction Id** (optional, fw 4.0+) — flag byte `0x00` then 7-bit LSB, MSB.
  Echoed in ACK/NACK to match async responses. Example: 4183 → `0x00 0x77 0x20`.
  Older firmware (<4.0.0) does not support it — check version first.
- **Operation** + **Resource** — see [[operation-and-resource-bytes]].
- **Payload** — binary, JSON, or mixed. JSON must be ASCII, strictly 7-bit.

## Encoding rules
- All bytes hex `0xNN` unless decimal is stated.
- 14-bit ids (controlId, transactionId) split into two 7-bit halves:
  `msb = id >> 7`, `lsb = id & 0x7F`.
- Larger integers (file sizes) split into four 7-bit bytes, little-endian:
  `b0 = n & 0x7F`, `b1 = (n>>7)&0x7F`, `b2 = (n>>14)&0x7F`, `b3 = (n>>21)&0x7F`.
  Reconstruct: `n = b0 + (b1<<7) + (b2<<14) + (b3<<21)`. See [[api-file-transfer]].

## Ports
Prefer the **CTRL** port (Windows `MIDIIN3`, Linux `PORT 3`) for management
traffic. Responses always return on the request's port. Default event/log routing
is CTRL but configurable. See [[request-response-handshake]].

Related: [[operation-and-resource-bytes]], [[request-response-handshake]],
[[entities/firmware-4-0]].
