---
title: Snapshots & Captures
type: concept
tags: [snapshots, captures, sysex, storage]
sources: [api-sysex]
updated: 2026-06-30
---

# Snapshots & Captures

Two per-project value/recording stores, both keyed by **projectId**. Source:
[[api-sysex]].

## Snapshots — saved control values
A snapshot stores the current values of a preset's controls so they can be
recalled. Organized by `projectId`, in banks/slots, stored under `ctrlv2/snaps/`.
- **List** `0x02 0x05` (`{projectId}`) → `snapshots[]` (`slot, bankNumber, name,
  color, filename`).
- **Data** `0x02 0x03` (`{projectId, bankNumber, slot}`) → `parameters[]`
  (`deviceId, messageType, parameterNumber, midiValue`).
- **Update** `0x04 0x06` (name/color) · **Remove** `0x05 0x06` ·
  **Swap** `0x06 0x06` (empty target ⇒ move) · **Set snapshot slot** `0x14 0x09`.
- Events: snapshot list change `0x7E 0x03`, snapshot bank switch `0x7E 0x04`.

## Captures — recorded MIDI
A capture is a recorded collection of MIDI messages (a Standard MIDI File).
Organized by `projectId`, stored under `ctrlv2/captures/`.
- **List** `0x02 0x31` (`{projectId}`) → `captures[]` (`slot, bankNumber, name,
  color, filename .mid, midiInterface, port`).
- **Data** `0x02 0x30` (`{projectId, bankNumber, slot}`) → **packed 7-bit SMF data**.
- **Update** `0x04 0x06` · **Remove** `0x05 0x32` · **Swap** `0x06 0x06` ·
  **Set capture slot** `0x14 0x33`.
- Event: capture list change `0x7E 0x31`.

> ⚠️ The source reuses resource byte `0x06` (Snapshot) in several capture
> examples where `0x32` (Capture) is meant — likely doc copy-paste errors. Remove
> Capture is documented as `0x05 0x32`; the surrounding hex sometimes shows `0x06`.
> Flagged for lint / verification against firmware.

Related: [[preset-slots-and-banks]], [[operation-and-resource-bytes]],
[[request-response-handshake]].
