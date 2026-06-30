---
title: Operation & Resource Bytes
type: concept
tags: [sysex, protocol, reference]
sources: [api-sysex, api-file-transfer]
updated: 2026-06-30
---

# Operation & Resource Bytes

Reference tables for the two bytes that follow the manufacturer id (and optional
transaction id) and tell the controller *what to do* and *to what*. Source:
[[api-sysex]], [[api-file-transfer]]. Frame defined in [[sysex-message-structure]].

## Operation byte
| Byte | Operation | Notes |
|---|---|---|
| `0x01` | upload / data dump | host→device upload; device→host dump uses same byte |
| `0x02` | request (query) | read-only |
| `0x03` | MIDI learn | also the learn-info event resource |
| `0x04` | update | persistent change (snapshot/capture attrs, load preloaded) |
| `0x05` | remove | permanent delete |
| `0x06` | swap | exchange snapshot/capture slots |
| `0x08` | execute | run Lua, reload slot |
| `0x09` | switch | active preset slot / page / control set |
| `0x14` | updateRuntime | volatile changes (control, value text, bars, ports, subscriptions) |
| `0x7E` | controller event | device→host notifications + ACK/NACK |
| `0x7F` | system call | logger, window, reboot, log message |

## Resource byte (selected)
| Byte | Resource |
|---|---|
| `0x01` | Preset (preset.json) |
| `0x02` | Configuration |
| `0x03` | Snapshot data |
| `0x04` | Preset list |
| `0x05` | Snapshot list |
| `0x06` | Snapshot |
| `0x07` | Control |
| `0x08` | Preset slot |
| `0x09` | Snapshot slot |
| `0x0A` | Page |
| `0x0B` | Control Set |
| `0x0C` | Lua script (main.lua) / Lua file (legacy execute) |
| `0x0D` | Function (execute Lua command) |
| `0x0E` | Override value text |
| `0x0F` | Preset devices (devices.json) |
| `0x10` | USB host device list |
| `0x11` | Performance (performance.json) |
| `0x12` | Persisted JSON data (data.json) |
| `0x2D` | Staged cache (file transfer open/commit/progress) |
| `0x2E` | Staged cache header (register file) |
| `0x2F` | Staged cache chunk |
| `0x30` | Capture data |
| `0x31` | Capture list |
| `0x32` | Capture |
| `0x33` | Capture slot |
| `0x34` | Location (file transfer query/remove) |
| `0x77` | Bottom bar text / event override |
| `0x78` | Reboot (system) |
| `0x79` | Event subscriptions |
| `0x7A` | Window (repaint) |
| `0x7B` | Events MIDI port |
| `0x7C` | Debug (Lua) |
| `0x7D` | Logger (status/level/port) |
| `0x7E` | Run-time information (query) |
| `0x7F` | Electra information (query) / System call (as operation) |

> Note: byte meaning depends on position — e.g. `0x7E`/`0x7F` are *resources* in a
> query but *operations* for events/system calls; `0x7D`/`0x77` overload by
> context. Read operation first, then resource.

Common combinations and their JSON payloads are catalogued in [[api-sysex]].
Related: [[request-response-handshake]], [[preset-slots-and-banks]].
