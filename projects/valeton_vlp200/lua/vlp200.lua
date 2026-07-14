-- ============================================================================
-- Valeton VLP-200 - Electra One Mini companion script
--
-- Continuous CCs (volumes) are handled by the preset JSON.
-- All buttons / toggles are sent from Lua so we avoid:
--   1) multiple pads sharing parameterNumber=CC1 (parameterMap fights)
--   2) onValue=0 never transmitting (STOP ALL / Project step)
--
-- Family MIDI map (VLP-400 manual; VLP-200 fw 1.1+ expected):
--   CC2 L1 vol - CC3 L2 vol - CC4 Drum vol
--   CC5 Project UP (0) - CC6 Project DOWN (0)
--   CC1 Footswitch action (data = action id)
--   PC  Project recall 0..98
-- ============================================================================

print("VLP-200 Mini controller loaded")

-- MIDI routing
-- -------------
-- Electra logical ports:
--   Port 1 = MIDI IO 1 + USB Host 1 + USB Device 1
--   Port 2 = MIDI IO 2 + USB Host 2 + USB Device 2
--
-- Electra Mini has only ONE pair of TRS MIDI jacks = MIDI IO 1 = Port 1.
-- Sending on Port 2 lights USB Host/Device LEDs but never the analog MIDI
-- IO indicator (there is no physical MIDI IO 2 on Mini).
--
-- Lua midi.send* can take an optional leading interface:
--   USB_DEV=0, USB_HOST=1, MIDI_IO=2
-- We target MIDI_IO explicitly so the TRS jack is used.
local DEVICE_ID = 1
local WANTED_PORT = 1   -- must match presets/valeton_vlp200.json devices[0].port
local WANTED_CH = 1     -- must match devices[0].channel
local OUT = PORT_1
local CH = 1
-- Prefer analog TRS. Fall back to fan-out if MIDI_IO is unavailable.
local IFACE = (MIDI_IO ~= nil) and MIDI_IO or nil

local function syncMidiRoute()
    local dev = devices.get(DEVICE_ID)
    if not dev then
        print("VLP-200: device 1 missing; defaulting to PORT_1 ch1 MIDI_IO")
        OUT = PORT_1
        CH = WANTED_CH
        info.setText("VLP-200 P1 ch1 MIDI_IO")
        return
    end

    pcall(function() dev:setPort(WANTED_PORT) end)
    pcall(function() dev:setChannel(WANTED_CH) end)

    local port = WANTED_PORT
    local okp, p = pcall(function() return dev:getPort() end)
    if okp and type(p) == "number" then
        port = p
    end
    OUT = (port == 2) and PORT_2 or PORT_1

    local okc, c = pcall(function() return dev:getChannel() end)
    if okc and type(c) == "number" and c >= 1 and c <= 16 then
        CH = c
    else
        CH = WANTED_CH
    end

    local ifaceName = (IFACE ~= nil) and "MIDI_IO" or "ALL"
    print(string.format("VLP-200 MIDI -> %s PORT_%d ch %d", ifaceName, port, CH))
    info.setText(string.format("VLP-200 P%d ch%d %s", port, CH, ifaceName))
end

-- CC#1 footswitch action ids
local ACT = {
    PLAY_STOP_ALL = 0,
    DRUM          = 1,
    TAP           = 2,
    L1_REC        = 3,
    L1_STACK      = 4,
    L1_PLAY       = 5,
    L1_UNDO       = 6,
    L2_REC        = 7,
    L2_STACK      = 8,
    L2_PLAY       = 9,
    L2_UNDO       = 10,
    L1_ONCE       = 21,
    L2_ONCE       = 22,
}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- True on pad press. Soft keys (onValue=1) and encoder pads (127)
-- both need to count. Ignore release / off / nil.
local function pressed(value)
    if value == nil or value == "off" or value == false then
        return false
    end
    if type(value) == "number" then
        return value ~= 0
    end
    return true
end

-- Send helpers: always prefer TRS MIDI IO when available.
local function sendCC(cc, value)
    if IFACE ~= nil then
        midi.sendControlChange(IFACE, OUT, CH, cc, value)
    else
        midi.sendControlChange(OUT, CH, cc, value)
    end
end

local function sendPC(program)
    if IFACE ~= nil then
        midi.sendProgramChange(IFACE, OUT, CH, program)
    else
        midi.sendProgramChange(OUT, CH, program)
    end
end

local function sendRaw(bytes)
    if IFACE ~= nil then
        midi.sendMessage(IFACE, OUT, bytes)
    else
        midi.sendMessage(OUT, bytes)
    end
end

local function sendStop()
    if IFACE ~= nil then
        pcall(function() midi.sendStop(IFACE, OUT) end)
    else
        pcall(function() midi.sendStop(OUT) end)
    end
end

local function pulseFs(actionId, label)
    sendCC(1, actionId)
    if label then
        info.setText(label)
    end
end

-- ---------------------------------------------------------------------------
-- Project
-- ---------------------------------------------------------------------------

function onProjectSelect(valueObject, value)
    local p = clamp(value, 0, 98)
    sendPC(p)
    info.setText(string.format("Project %02d ch%d", p + 1, CH))
end

function onProjectUp(valueObject, value)
    if pressed(value) then
        sendCC(5, 0)
        info.setText(string.format("Project UP ch%d", CH))
    end
end

function onProjectDown(valueObject, value)
    if pressed(value) then
        sendCC(6, 0)
        info.setText(string.format("Project DN ch%d", CH))
    end
end

-- ---------------------------------------------------------------------------
-- Footswitch actions (CC1)
-- ---------------------------------------------------------------------------

function onPlayStopAll(valueObject, value)
    if pressed(value) then pulseFs(ACT.PLAY_STOP_ALL, "STOP ALL") end
end

function onDrumToggle(valueObject, value)
    if pressed(value) then pulseFs(ACT.DRUM, "DRUM") end
end

function onTapTempo(valueObject, value)
    if pressed(value) then pulseFs(ACT.TAP, "TAP") end
end

function onL1Rec(valueObject, value)
    if pressed(value) then pulseFs(ACT.L1_REC, "L1 REC") end
end

function onL1Play(valueObject, value)
    if pressed(value) then pulseFs(ACT.L1_PLAY, "L1 PLAY") end
end

function onL1Undo(valueObject, value)
    if pressed(value) then pulseFs(ACT.L1_UNDO, "L1 UNDO") end
end

function onL1Stack(valueObject, value)
    if pressed(value) then pulseFs(ACT.L1_STACK, "L1 STACK") end
end

function onL1Once(valueObject, value)
    if pressed(value) then pulseFs(ACT.L1_ONCE, "L1 ONCE") end
end

function onL2Rec(valueObject, value)
    if pressed(value) then pulseFs(ACT.L2_REC, "L2 REC") end
end

function onL2Play(valueObject, value)
    if pressed(value) then pulseFs(ACT.L2_PLAY, "L2 PLAY") end
end

function onL2Undo(valueObject, value)
    if pressed(value) then pulseFs(ACT.L2_UNDO, "L2 UNDO") end
end

function onL2Stack(valueObject, value)
    if pressed(value) then pulseFs(ACT.L2_STACK, "L2 STACK") end
end

function onL2Once(valueObject, value)
    if pressed(value) then pulseFs(ACT.L2_ONCE, "L2 ONCE") end
end

-- ALL PLAY: pulse L1 + L2 play/stop actions
function onAllPlay(valueObject, value)
    if not pressed(value) then return end
    sendCC(1, ACT.L1_PLAY)
    sendCC(1, ACT.L2_PLAY)
    info.setText("ALL PLAY")
end

-- ALL STOP: CC1 action 0 can be dropped by some stacks as "zero value",
-- so also stop each loop via its play/stop action + MIDI realtime Stop.
function onAllStop(valueObject, value)
    if not pressed(value) then return end
    -- Raw 3-byte CC so value 0 is definitely on the wire
    local status = 0xB0 + (CH - 1)
    sendRaw({ status, 1, ACT.PLAY_STOP_ALL })
    sendCC(1, ACT.L1_PLAY)
    sendCC(1, ACT.L2_PLAY)
    sendCC(1, ACT.DRUM)
    sendStop()
    info.setText("ALL STOP")
end

-- ---------------------------------------------------------------------------
-- userFunctions -> Assign Buttons (optional override)
-- Primary soft-key path is JSON potIds 9-12 (Mini soft buttons 2-5).
-- These userFunctions are a backup for Preset Menu -> Assign Buttons.
-- ---------------------------------------------------------------------------

function ufL1Stack()
    onL1Stack(nil, 127)
end

function ufAllPlay()
    onAllPlay(nil, 127)
end

function ufAllStop()
    onAllStop(nil, 127)
end

function ufTap()
    onTapTempo(nil, 127)
end

preset.userFunctions = {
    pot1 = { call = ufL1Stack, name = "L1 STACK", close = false },
    pot2 = { call = ufAllPlay, name = "ALL PLAY", close = false },
    pot3 = { call = ufAllStop, name = "ALL STOP", close = false },
    pot4 = { call = ufTap,     name = "TAP",      close = false },
}

function preset.onLoad()
    syncMidiRoute()
end

function preset.onReady()
    syncMidiRoute()
    info.setText(string.format("VLP-200 ready P%d ch%d", WANTED_PORT, CH))
end
