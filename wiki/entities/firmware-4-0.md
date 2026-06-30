---
title: Firmware 4.0
type: entity
tags: [firmware, versioning]
sources: [api-sysex, api-file-transfer, api-lua-extension, json-performance-format]
updated: 2026-06-30
---

# Firmware 4.0

The baseline for everything in this wiki. **All** documented APIs and formats —
the [[sysex-message-structure|SysEx API]], [[api-file-transfer|File Transfer API]],
[[lua-extension-overview|Lua Extension]], and the **Performance** feature
([[json-performance-format]]) — require **firmware version 4.0 or later**.

## Version reporting
- **Get Electra info** (`0x02 0x7F`) returns:
  ```json
  { "versionText": "v4.0.0", "versionSeq": 400000000,
    "serial": "EO2-5301787f", "hwRevision": "3.0" }
  ```
- From Lua: `controller.getFirmwareVersion()` (string),
  `controller.getFirmwareNumVersion()` (numeric), and
  `controller.require(model, "4.0.0")` / `isRequired(...)` for guards.

## Compatibility notes
- **Transaction Ids** are unsupported before 4.0.0 — hosts should check the
  version before using them. See [[sysex-message-structure]].
- Event subscriptions currently honor only **Page** and **Pots** flags.
- Performance format is `version` 1 and "expected to keep evolving."

Related: [[entities/controller-hardware]], [[request-response-handshake]].
