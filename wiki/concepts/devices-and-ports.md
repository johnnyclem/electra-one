---
title: Devices & Ports
type: concept
tags: [devices, midi, ports]
sources: [json-preset-format, json-device-overrides, api-lua-extension, api-sysex]
updated: 2026-06-30
---

# Devices & Ports

Source: [[json-device-overrides]], [[json-preset-format]], [[api-lua-extension]].

## Device abstraction
You **always address a Device**, never a raw port/channel. A device is a hardware
synth (MIDI IO), a hardware sequencer (USB Host), or a software plugin (USB
Device). Electra handles **up to 16 simultaneous devices** (Lua `devices.get`
accepts ids 1..32, but preset device `id` is 1..16).

Device fields (preset & overrides): `id` 1..16, `name` ≤20, `instrumentId`,
`port` 1..2, `channel` 1..16, `rate` 10..1000 ms (min inter-message delay).

## Internal port buses
Two logical ports, each bridging three physical interfaces:
- **Port 1** = MIDI IO 1 + USB Host 1 + USB Device 1.
- **Port 2** = MIDI IO 2 + USB Host 2 + USB Device 2.
- **CTRL** — management/event/log port (not a device bus). Lua `PORT_CTRL`.

Lua interfaces: messages can target one interface (USB Dev / USB Host / MIDI IO)
or all of them; the optional leading `interface` arg on `midi.send*` selects one.

## Device overrides
`devices.json` ([[json-device-overrides]]) remaps a preset's device **ports and
channels** for a local rig **without editing the preset**. Query/upload via SysEx
resource `0x0F`; file type `deviceList`. Runtime equivalents in Lua:
`device:setPort/setChannel/setRate`, `devices.create(id,name,port,channel)`,
`devices.getByPortChannel(port,channel)`.

## USB Host
**Get USB Host devices** (`0x02 0x10`) lists connected USB-host gear with
`manufacturer, product, serialNumber, vid, pid, ports[] (devicePort, name,
electraPort)`. A **USB host change** event fires on connect/disconnect.

Related: [[controls-values-and-messages]], [[request-response-handshake]],
[[entities/controller-hardware]].
