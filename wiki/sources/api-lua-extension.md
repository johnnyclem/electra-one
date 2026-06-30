---
title: "Source: Lua Extension"
type: source
tags: [lua, scripting, api]
raw: ../docs/API-LuaExtension.pdf
updated: 2026-06-30
---

# Source — Lua Extension

Faithful summary of `docs/API-LuaExtension.pdf` (16 pp.). Adds **procedural
scripting** (Lua) to Electra One presets. The declarative [[json-preset-format|
preset JSON]] pre-loads all pages/devices/groups/controls; Lua then **modifies,
repositions, and toggles** existing objects at runtime. **Lua cannot create new
preset objects** (but can create Devices via `devices.create`). Requires fw 4.0+.
See [[lua-extension-overview]] for the synthesized cross-reference.

## Uploading & executing
- Upload `main.lua` via editor or SysEx `0x01 0x0C <source>`. One script per
  preset (overwrites); multi-file projects via [[api-file-transfer]] + `require`.
- Run arbitrary Lua via SysEx `0x08 0x0D <text>` (max 65,353 B per this doc; the
  base SysEx doc says 65,535 — see [[lua-extension-overview]] ⚠️). Keep short;
  prefer calling predefined functions.

## Script structure & init order
Four building blocks: **setup** (global code), **standard functions**, **standard
callbacks**, **user functions**. First load sequence:
1. global context runs → 2. `preset.onLoad()` → 3. all value-linked Lua functions
run with default JSON values → 4. `preset.onReady()` → 5. listening for events.
Re-selecting an already-initialized preset does **not** re-init it.

## API modules (selected)
- **controls** / **Control**: `controls.get(ref)` →
  `getId/setVisible/isVisible/setName/setColor/setVariant/setBounds/setPot/
  setSlot(slot[,page])/getValueIds/getValue(valueId)/getValues/
  setPaintCallback/setTouchCallback/setPotCallback/repaint/print`. Custom
  controls support paint/touch/pot callbacks.
- **controller**: `getModel` (`mk2`/`mini`), `getNumModel`, `getFirmwareVersion`,
  `getFirmwareNumVersion`, `uptime`, `require(model,minVer)`,
  `isRequired(model,minVer)` (use with `assert`).
- **pipe** (data pipes): `acquire(name)`, `send(pipeId,value)`, `release(pipeId)`
  — cross-preset modulation streams. See [[data-pipes-and-modulation]].
- **devices** / **Device**: `get(id)`, `getByPortChannel(port,ch)`,
  `create(id,name,port,ch)`; device `getId/setName/getName/setPort/getPort/
  setChannel/getChannel/setRate/getRate`.
- **events**: `subscribe(flags)` (only `PAGES|POTS` supported), `setPort`,
  callbacks `onPageChange(new,old)`, `onPotTouch/onPotTouchChange(potId,controlId,touched)`.
- **graphics** (paint callbacks only, clipped to component bounds):
  `setColor, drawPixel, drawLine, drawRect, fillRect, drawRoundRect,
  fillRoundRect, drawTriangle, fillTriangle, drawCircle, fillCircle, drawEllipse,
  fillEllipse, fillCurve(seg), print(x,y,text,width,alignment)`.
- **groups** / **Group**: `get(ref)`; `getId/setLabel/getLabel/setVisible/
  isVisible/setColor/setVariant/setBounds/getBounds/setSlot(slot,w,h)/
  setHorizontalSpan/setVerticalSpan/print`. height 0 = thin line, else rectangle.
- **helpers**: `slotToBounds(slot)`, `boundsToSlot({x,y,w,h})`.
- **info**: `setText(text)` — bottom status bar.
- **logger**: `print(text)` → Console (prefixed `lua:`); logger disabled by
  default for performance; messages are CTRL-port SysEx with timestamp.
- **Message** (one per Value): `setDeviceId/getDeviceId/setType/getType/
  setParameterNumber/getParameterNumber/setValue/getValue/setMin/getMin/setMax/
  getMax/setRange/setOffValue/getOffValue/setOnValue/getOnValue/print`. MIDI
  values up to 14-bit (0..16383).
- **MIDI callbacks** (`midi.*`): generic `onMessage(midiInput,midiMessage)` plus
  typed `onNoteOn/onNoteOff/onControlChange/onAfterTouchPoly/onAfterTouchChannel/
  onProgramChange/onPitchBend/onSongSelect/onSongPosition/onClock/onStart/onStop/
  onContinue/onActiveSensing/onSystemReset/onTuneRequest/onSysex(…,sysexBlock)`.
  `midiInput = {interface, port}`. 24 clocks per quarter note. Don't define empty
  callbacks (registration overhead).
- **MIDI functions** (`midi.send*`): `sendMessage(port,msg)`, `sendNoteOn/Off`,
  `sendControlChange`, `sendAfterTouchPoly/Channel`, `sendProgramChange`,
  `sendPitchBend`, etc. Optional leading `interface` arg targets one interface;
  omit to send to all (USB Dev, USB Host, MIDI IO).
- **parameterMap**: `set(deviceId, type, parameterNumber, value)` etc. — the
  global value store mapping parameters to current MIDI values.
- **patch**: `patch.onRequest(device)` callback for patch-dump requests; request
  helpers. **preset**: `onLoad`/`onReady` lifecycle. **timer**, **transport**
  (clock/start/stop), **window**, **SysexBlock** (`getLength`, `peek(i)`, build
  custom SysEx), **System**, value **formatters** and **function callbacks**.

## Globals (constants)
`PORT_1/PORT_2/PORT_CTRL`; message types `PT_CC7`, `PT_NRPN`, …; `CONTROL_SET_1..3`;
`POT_1..POT_12`; variants `VT_DEFAULT/VT_HIGHLIGHTED/VT_THIN/VT_VALUEONLY/VT_DIAL/
VT_CHECKBOX`; MIDI types `NOTE_ON`, `CONTROL_CHANGE`, `SYSEX`, …; models
`MODEL_ANY/MODEL_MK1/MODEL_MK2/MODEL_MINI_MK1`; bounds indices `X/Y/WIDTH/HEIGHT`;
`CONTROL_SETS`; segments `TOP_LEFT/TOP_RIGHT/BOTTOM_LEFT/BOTTOM_RIGHT`.

Related: [[controls-values-and-messages]], [[data-pipes-and-modulation]],
[[json-preset-format]] (`formatter`/`function` hooks point at Lua functions).
