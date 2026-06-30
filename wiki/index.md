# Electra One Developer Wiki — Index

LLM-maintained knowledge base on the Electra One MIDI controller's developer APIs
and file formats. Conventions in [[CLAUDE]]. Timeline in [[log]].

**Start here:** [[concepts/sysex-message-structure]] ·
[[concepts/lua-extension-overview]] · [[concepts/preset-slots-and-banks]].

## Sources (one page per ingested document)
| Page | Covers | Raw |
|---|---|---|
| [[sources/api-sysex]] | Core SysEx API: queries, uploads, commands, events, learn, logging | docs/API-SysEx.pdf |
| [[sources/api-file-transfer]] | Chunked/atomic multi-file transfer, MD5, locations, SD layout | docs/API-FileTransfer.pdf |
| [[sources/api-lua-extension]] | Lua scripting: modules, callbacks, globals | docs/API-LuaExtension.pdf |
| [[sources/json-preset-format]] | `preset.json`: pages, devices, overlays, groups, controls, values, messages | docs/JSON-PresetFormat.pdf |
| [[sources/json-device-overrides]] | `devices.json`: port/channel remap | docs/JSON-DeviceOverrides.pdf |
| [[sources/json-performance-format]] | `performance.json`: references, macros, modulation, groups | docs/JSON-PerformanceFormat.pdf |

## Concepts (cross-cutting synthesis)
| Page | Summary |
|---|---|
| [[concepts/sysex-message-structure]] | Message framing, manufacturer id, txn id, 7-bit encoding |
| [[concepts/operation-and-resource-bytes]] | Reference tables for operation + resource bytes |
| [[concepts/request-response-handshake]] | Query vs command, ACK/NACK, events, subscriptions, MIDI learn, logging |
| [[concepts/preset-slots-and-banks]] | 6×12 slots, slot files, active vs armed, preloaded content |
| [[concepts/controls-values-and-messages]] | Control→Value→Message object model + Lua runtime |
| [[concepts/devices-and-ports]] | Device abstraction, Port 1/2 buses, overrides, USB host |
| [[concepts/data-pipes-and-modulation]] | setValue/modulate/dataPipe modes, Lua pipes, macros |
| [[concepts/snapshots-and-captures]] | Saved values vs recorded MIDI, both by projectId |
| [[concepts/lua-extension-overview]] | Lua mental model, module map, init order, hooks |
| [[concepts/file-system-structure]] | SD card tree, slot folders, commit locations |

## Entities
| Page | Summary |
|---|---|
| [[entities/firmware-4-0]] | Baseline version; version reporting; compatibility |
| [[entities/controller-hardware]] | Models, pots, control sets, pages, I/O, memory |

## Open questions / lint backlog
- Max Execute-Lua length: 65,353 vs 65,535 bytes (sources disagree). See [[concepts/lua-extension-overview]].
- Capture resource byte `0x06` vs `0x32` inconsistencies. See [[concepts/snapshots-and-captures]].
- Device Overrides doc carries mislabeled Performance intro text. See [[sources/json-device-overrides]].
- Performance `groups` with/without `id`/`pageId` (spec vs example). See [[sources/json-performance-format]].
- Not yet ingested: Configuration format (`config`/`configv4.cfg`) — referenced by SysEx but no source doc here.
