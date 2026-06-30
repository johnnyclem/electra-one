# Wiki Log

Append-only, chronological. Newest at bottom. Each entry:
`## [YYYY-MM-DD] <ingest|query|lint> | <title>`. List with:
`grep "^## \[" log.md`.

## [2026-06-30] setup | Wiki initialized
Created the LLM Wiki for the Electra One platform per the LLM Wiki pattern.
Structure: `CLAUDE.md` (schema), `index.md`, `log.md`, `sources/`, `concepts/`,
`entities/`. Installed `poppler` (pdftotext) to extract the PDF sources.

## [2026-06-30] ingest | API-SysEx.pdf — SysEx Implementation
Source page [[sources/api-sysex]]. Touched concepts:
[[concepts/sysex-message-structure]], [[concepts/operation-and-resource-bytes]],
[[concepts/request-response-handshake]], [[concepts/preset-slots-and-banks]],
[[concepts/snapshots-and-captures]]; entities [[entities/firmware-4-0]],
[[entities/controller-hardware]]. Manufacturer id `0x00 0x21 0x45`; query vs
command; ACK/NACK; transaction ids; full operation/resource tables.

## [2026-06-30] ingest | API-FileTransfer.pdf — File Transfer SysEx API
Source page [[sources/api-file-transfer]]. Created
[[concepts/file-system-structure]]; updated [[concepts/preset-slots-and-banks]],
[[concepts/operation-and-resource-bytes]]. Staged-cache protocol (open/register/
chunk/commit), MD5 integrity, location & type enums, progress events.

## [2026-06-30] ingest | API-LuaExtension.pdf — Lua Extension
Source page [[sources/api-lua-extension]]. Created
[[concepts/lua-extension-overview]], [[concepts/data-pipes-and-modulation]];
updated [[concepts/controls-values-and-messages]], [[concepts/devices-and-ports]].
Captured module map, callbacks, init order, globals. Flagged Execute-Lua max-length
contradiction with the SysEx doc.

## [2026-06-30] ingest | JSON-PresetFormat.pdf — Preset Format
Source page [[sources/json-preset-format]]. Drove
[[concepts/controls-values-and-messages]]; updated [[concepts/devices-and-ports]].
Top-level objects; Control/Value/Input/Message/Overlay/Group schemas; SysEx
message templates; 14-bit/sign handling.

## [2026-06-30] ingest | JSON-DeviceOverrides.pdf — Device Overrides Format
Source page [[sources/json-device-overrides]]. Updated
[[concepts/devices-and-ports]]. Noted the doc's mislabeled Performance intro text.

## [2026-06-30] ingest | JSON-PerformanceFormat.pdf — Performance Format
Source page [[sources/json-performance-format]]. Drove
[[concepts/data-pipes-and-modulation]]; updated
[[concepts/controls-values-and-messages]]. references (simple/multi), valueRef
modes (setValue/modulate/dataPipe), performance groups. Flagged groups id/pageId
spec-vs-example inconsistency.

## [2026-06-30] lint | Initial backlog recorded
Captured open questions in [[index]]: Execute-Lua max length (65,353 vs 65,535),
capture resource byte `0x06` vs `0x32`, Device Overrides mislabeled intro,
Performance groups id/pageId, and a missing Configuration-format source doc.
