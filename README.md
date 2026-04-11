# Electra One Mini Lua Learning Kit

A progressive set of 5 Lua scripts to learn the Electra One's capabilities, from basics to advanced SysEx handling.

## Quick Start

1. Go to [app.electra.one](https://app.electra.one) (the Preset Editor)
2. Create a new preset or open an existing one
3. Click the **Lua** tab in the editor
4. Paste a script and click **Upload**
5. Open the **Console** panel to see `print()` output

## The Scripts

| # | Script | Concepts | Difficulty |
|---|--------|----------|------------|
| 1 | `01_hello_world.lua` | print, callbacks, timer, controller info | ⭐ |
| 2 | `02_midi_io.lua` | Send/receive MIDI, transport sync | ⭐⭐ |
| 3 | `03_control_manipulation.lua` | Dynamic UI, pages, formatters | ⭐⭐⭐ |
| 4 | `04_midi_lfo.lua` | Timer-driven LFO, graphics API | ⭐⭐⭐⭐ |
| 5 | `05_sysex_patch_handler.lua` | SysEx parsing, patch dumps, persistence | ⭐⭐⭐⭐⭐ |

---

## Script 1: Hello World & Basics

**What you'll learn:**
- The `print()` function for debugging
- Preset lifecycle: `onLoad` → `onReady` → `onEnter`
- Querying controller model and firmware
- Basic timer usage

**Key APIs:**
```lua
print("message")                    -- Log to console
controller.getModel()               -- "mk2" or "mini"
controller.getFirmwareVersion()     -- e.g., "4.0.5"
info.setText("status message")      -- Display in status bar
timer.setPeriod(500)                -- Set timer interval (ms)
timer.enable() / timer.disable()
```

---

## Script 2: MIDI Input/Output

**What you'll learn:**
- Sending all MIDI message types
- Receiving MIDI with callbacks
- External clock sync with transport module
- Port routing (PORT_1, PORT_2)

**Key APIs:**
```lua
-- Sending
midi.sendControlChange(PORT_1, channel, cc, value)
midi.sendNoteOn(PORT_1, channel, note, velocity)
midi.sendProgramChange(PORT_1, channel, program)
midi.sendNrpn(PORT_1, channel, param, value, lsbFirst, reset)
midi.sendSysex(PORT_1, {bytes...})

-- Receiving (define these functions)
function midi.onControlChange(midiInput, channel, cc, value)
function midi.onNoteOn(midiInput, channel, note, velocity)
function midi.onSysex(midiInput, sysexBlock)

-- Transport sync
transport.enable()
function transport.onClock(midiInput)   -- 24 per quarter note
function transport.onStart(midiInput)
function transport.onStop(midiInput)
```

**Ableton Live Tips:**
- Enable Electra One as MIDI input in Live's preferences
- Turn on "Remote" for the Electra port
- Use MIDI Map mode to assign CCs
- Send MIDI clock from Live for transport sync

---

## Script 3: Control Manipulation

**What you'll learn:**
- Getting/modifying control properties
- Dynamic show/hide based on context
- Moving controls between slots
- Value formatters for custom display
- Page and group management

**Key APIs:**
```lua
-- Controls
local ctrl = controls.get(refId)
ctrl:setVisible(true/false)
ctrl:setSlot(slot)              -- Move to grid position
ctrl:setName("New Name")
ctrl:setColor(0xFF0000)         -- RGB hex
ctrl:getValue("value")          -- Get Value object

-- Values & Formatting
function formatPercent(valueObject, value)
    return string.format("%d%%", value)
end

-- Value callbacks
function onFaderChange(valueObject, value)
    local ctrl = valueObject:getControl()
    -- Do something with the value
end

-- Pages
pages.display(pageId)
pages.getActive()

-- Overlays (list items)
overlays.create(id, {
    {value = 0, label = "Option 1"},
    {value = 1, label = "Option 2"},
})
```

---

## Script 4: MIDI LFO Generator

**What you'll learn:**
- Timer-driven periodic execution
- Waveform generation (sine, triangle, saw, square)
- `parameterMap` for value manipulation
- Graphics API for custom visualizations
- State management patterns

**Key APIs:**
```lua
-- Timer
timer.setPeriod(20)     -- 50Hz update
timer.enable()
function timer.onTick()
    -- Called every period
end

-- Parameter Map
parameterMap.set(deviceId, PT_CC7, paramNum, value)
parameterMap.get(deviceId, PT_CC7, paramNum)
parameterMap.modulate(deviceId, type, param, modValue, depth)

-- Graphics (for Custom controls)
graphics.setColor(0x00FFFF)
graphics.drawLine(x1, y1, x2, y2)
graphics.fillRect(x, y, w, h)
graphics.drawCircle(x, y, radius)
graphics.print(x, y, "text", width, CENTER)
```

---

## Script 5: SysEx Patch Handler

**What you'll learn:**
- Patch request/response callbacks
- SysEx message parsing with `sysexBlock`
- Building and sending custom SysEx
- Checksum calculation
- Data persistence with `persist()`/`recall()`
- User functions in Preset Menu

**Key APIs:**
```lua
-- Patch callbacks (define in preset JSON first)
function patch.onRequest(device)
    -- Send your patch request here
end

function patch.onResponse(device, responseId, sysexBlock)
    -- Parse incoming patch dump
    local length = sysexBlock:getLength()
    local byte = sysexBlock:peek(position)
end

-- Persistence
persist(luaTable)       -- Save to non-volatile storage
recall(luaTable)        -- Load from storage

-- User functions in preset menu
preset.userFunctions = {
    pot1 = { call = myFunction, name = "Button", close = true },
}
```

---

## Parameter Types Reference

| Constant | Type | Usage |
|----------|------|-------|
| `PT_CC7` | CC (7-bit) | Standard MIDI CC 0-127 |
| `PT_CC14` | CC (14-bit) | High-res CC pairs |
| `PT_NRPN` | NRPN | Non-Registered Parameter |
| `PT_RPN` | RPN | Registered Parameter |
| `PT_SYSEX` | SysEx | System Exclusive params |
| `PT_NOTE` | Note | Note messages |
| `PT_PROGRAM` | Program | Program change |
| `PT_VIRTUAL` | Virtual | Lua-only, no MIDI |

## Global Constants

```lua
-- Ports
PORT_1, PORT_2, PORT_CTRL

-- Interfaces
USB_DEV, USB_HOST, MIDI_IO

-- Controller Models
MODEL_MK2, MODEL_MINI

-- Origins (in parameterMap.onChange)
ORIGIN_LUA, ORIGIN_CONTROL, ORIGIN_MIDI

-- Control Sets
CONTROL_SET_1, CONTROL_SET_2, CONTROL_SET_3

-- Pot IDs
POT_1 through POT_12

-- Bounds array indices
X, Y, WIDTH, HEIGHT

-- Text alignment
LEFT, CENTER, RIGHT

-- Curve segments
TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT
```

---

## Debugging Tips

1. **Use `print()` liberally** - Check the Console in the web editor
2. **Start simple** - Test callbacks one at a time
3. **Check ref IDs** - Control references must match the preset
4. **Verify MIDI routing** - Use the MIDI Console to monitor traffic
5. **Firmware version** - Some features require v4.0+

## Resources

- [Official Lua Extension Docs](https://docs.electra.one/developers/luaext.html)
- [Lua Crash Course](https://docs.electra.one/luacourse)
- [Preset Editor](https://app.electra.one)
- [Electra One Forum](https://forum.electra.one)
- [Preset Library](https://app.electra.one/presets)

## Hardware Notes (Electra One Mini)

- 6 touch-sensitive knobs (vs 12 on mkII)
- No touchscreen (knob-first interaction)
- Same Lua capabilities as mkII
- Presets are cross-compatible with mkII
- Use Performance overlays for more parameters

---

Happy scripting! 🎹

