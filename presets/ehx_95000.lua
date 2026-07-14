-- ============================================================================
-- Electro-Harmonix 95000 Performance Loop Laboratory
-- Electra One Mini companion script
--
-- Continuous CCs (volumes, pans…) are handled by the preset JSON.
-- Footswitches / buttons are sent from Lua as MIDI Program Change (manual
-- p.37) so we avoid parameterMap fights from shared carriers.
--
-- MIDI map (95000 User Reference Manual v1.0):
--   CC7  MASTER LVL · CC9 CLIX LVL · CC14/15 DRY L/R · CC20-25 Track vols
--   CC26 MIXDOWN · CC27 TEMPO · CC28 Expression · CC29/30 DRY pan
--   CC85-90 Track pans · CC102-108 Overdub (DUB) · CC115 Loop select 0-99
--   PC 0-99 loop select · PC 100-127 transport / buttons / mute
--
-- MIDI clock master (Modes page):
--   TEMPO fader (virtual 40–240 BPM) + CLK RUN pad.
--   When running, Electra emits 24 PPQN MIDI Clock + Start/Stop so the
--   95000 can slave in EXT. CLOCK XT / BX mode (manual p.12–13, 32).
--
-- Routing: Electra Mini TRS = Port 1 / MIDI IO. Lua sends on MIDI_IO.
-- ============================================================================

print("EHX 95000 Mini controller loaded")

local DEVICE_ID = 1
local WANTED_PORT = 1
local WANTED_CH = 1
local OUT = PORT_1
local CH = 1
local IFACE = (MIDI_IO ~= nil) and MIDI_IO or nil

-- Minimum gap between button-push messages (manual: >= 300 ms)
local MIN_BTN_MS = 320
local lastBtnMs = 0

-- MIDI clock master state (Electra → 95000)
local PPQN = 24
local BPM_MIN, BPM_MAX = 40, 240
local bpm = 120
local clockRunning = false
local CLOCK_PAD_ID = 55
local LABEL_START = "Start MIDI 🕐"  -- U+1F551
local LABEL_STOP  = "STOP MIDI 🕐"
local clockPad = nil

local function nowMs()
    local ok, t = pcall(function() return controller.uptime() end)
    if ok and type(t) == "number" then return t end
    return 0
end

local function syncMidiRoute()
    local dev = devices.get(DEVICE_ID)
    if not dev then
        OUT = PORT_1
        CH = WANTED_CH
        info.setText("95000 P1 ch1 (no dev)")
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
    print(string.format("95000 MIDI -> %s PORT_%d ch %d", ifaceName, port, CH))
    info.setText(string.format("95000 P%d ch%d %s", port, CH, ifaceName))
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function pressed(value)
    if value == nil or value == "off" or value == false then
        return false
    end
    if type(value) == "number" then
        return value ~= 0
    end
    return true
end

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

-- Realtime transport (channel-less). Prefer TRS MIDI_IO when available.
local function sendClockPulse()
    if IFACE ~= nil then
        pcall(function() midi.sendClock(IFACE, OUT) end)
    else
        pcall(function() midi.sendClock(OUT) end)
    end
end

local function sendStart()
    if IFACE ~= nil then
        pcall(function() midi.sendStart(IFACE, OUT) end)
    else
        pcall(function() midi.sendStart(OUT) end)
    end
end

local function sendStop()
    if IFACE ~= nil then
        pcall(function() midi.sendStop(IFACE, OUT) end)
    else
        pcall(function() midi.sendStop(OUT) end)
    end
end

local function applyBpm(newBpm)
    bpm = clamp(math.floor(newBpm + 0.5), BPM_MIN, BPM_MAX)
    pcall(function() timer.setBpm(bpm * PPQN) end)
end

local function getClockPad()
    if clockPad then return clockPad end
    local ok, c = pcall(function() return controls.get(CLOCK_PAD_ID) end)
    if ok and c then
        clockPad = c
    end
    return clockPad
end

local function setClockPadLabel(running)
    local pad = getClockPad()
    if not pad then return end
    local label = running and LABEL_STOP or LABEL_START
    pcall(function() pad:setName(label) end)
end

local function startClock()
    applyBpm(bpm)
    clockRunning = true
    pcall(function() timer.enable() end)
    sendStart()
    setClockPadLabel(true)
    info.setText(string.format("CLK %d ON", bpm))
end

local function stopClock()
    clockRunning = false
    sendStop()
    pcall(function() timer.disable() end)
    setClockPadLabel(false)
    info.setText(string.format("CLK %d OFF", bpm))
end

function timer.onTick()
    if clockRunning then
        sendClockPulse()
    end
end

-- Throttled button press via Program Change (PC 100-127)
local function pulsePC(pc, label)
    local t = nowMs()
    if t > 0 and (t - lastBtnMs) < MIN_BTN_MS then
        info.setText("wait…")
        return
    end
    lastBtnMs = t
    sendPC(pc)
    if label then
        info.setText(label)
    end
end

-- Alternate path: CC3 button press (same data values as PC 100+)
-- Kept for cases where PC is filtered; prefer PC for clarity.
local function pulseCC3(data, label)
    local t = nowMs()
    if t > 0 and (t - lastBtnMs) < MIN_BTN_MS then
        info.setText("wait…")
        return
    end
    lastBtnMs = t
    sendCC(3, data)
    if label then
        info.setText(label)
    end
end

-- ---------------------------------------------------------------------------
-- Transport / footswitches (PC)
-- ---------------------------------------------------------------------------

function onPlayStop(valueObject, value)
    if pressed(value) then pulsePC(103, "PLAY/STOP") end
end

function onRecord(valueObject, value)
    if pressed(value) then pulsePC(102, "RECORD") end
end

function onUndo(valueObject, value)
    if pressed(value) then pulsePC(101, "UNDO") end
end

function onTrackFsw(valueObject, value)
    if pressed(value) then pulsePC(100, "TRACK FSW") end
end

function onLoopDown(valueObject, value)
    if pressed(value) then pulsePC(104, "LOOP DN") end
end

function onLoopUp(valueObject, value)
    if pressed(value) then pulsePC(105, "LOOP UP") end
end

function onNewLoop(valueObject, value)
    if pressed(value) then pulsePC(106, "NEW LOOP") end
end

function onReverse(valueObject, value)
    if pressed(value) then pulsePC(107, "REVERSE") end
end

function onOct(valueObject, value)
    if pressed(value) then pulsePC(108, "OCT") end
end

function onTap(valueObject, value)
    if pressed(value) then pulsePC(109, "TAP") end
end

function onTrack1(valueObject, value)
    if pressed(value) then pulsePC(110, "TRACK 1") end
end

function onTrack2(valueObject, value)
    if pressed(value) then pulsePC(111, "TRACK 2") end
end

function onTrack3(valueObject, value)
    if pressed(value) then pulsePC(112, "TRACK 3") end
end

function onTrack4(valueObject, value)
    if pressed(value) then pulsePC(113, "TRACK 4") end
end

function onTrack5(valueObject, value)
    if pressed(value) then pulsePC(114, "TRACK 5") end
end

function onTrack6(valueObject, value)
    if pressed(value) then pulsePC(115, "TRACK 6") end
end

function onMixdownBtn(valueObject, value)
    if pressed(value) then pulsePC(116, "MIXDOWN") end
end

function onPunch(valueObject, value)
    if pressed(value) then pulsePC(117, "PUNCH") end
end

function onQuantize(valueObject, value)
    if pressed(value) then pulsePC(118, "QUANTIZE") end
end

function onPage(valueObject, value)
    if pressed(value) then pulsePC(119, "PAGE") end
end

function onExtClock(valueObject, value)
    -- Cycles 95000 IN → XT (full slave) → BX (beat sync). Does not start
    -- Electra's clock generator — use TEMPO + CLK RUN after enabling XT/BX.
    if pressed(value) then
        pulsePC(127, string.format("EXT CLK · BPM %d", bpm))
    end
end

-- Dial Electra master tempo (virtual fader, 40–240 BPM). Live-updates the
-- clock generator while running; 95000 follows via MIDI Clock, not CC27.
function onTempo(valueObject, value)
    applyBpm(value)
    if clockRunning then
        info.setText(string.format("CLK %d ON", bpm))
    else
        info.setText(string.format("BPM %d", bpm))
    end
end

-- Toggle MIDI clock master out (Start/Clock/Stop → 95000 MIDI IN).
function onClockRun(valueObject, value)
    if not pressed(value) then return end
    if clockRunning then
        stopClock()
    else
        startClock()
    end
end

-- Mute/unmute tracks (PC 120-126)
function onMute1(valueObject, value)
    if pressed(value) then pulsePC(120, "MUTE T1") end
end
function onMute2(valueObject, value)
    if pressed(value) then pulsePC(121, "MUTE T2") end
end
function onMute3(valueObject, value)
    if pressed(value) then pulsePC(122, "MUTE T3") end
end
function onMute4(valueObject, value)
    if pressed(value) then pulsePC(123, "MUTE T4") end
end
function onMute5(valueObject, value)
    if pressed(value) then pulsePC(124, "MUTE T5") end
end
function onMute6(valueObject, value)
    if pressed(value) then pulsePC(125, "MUTE T6") end
end
function onMuteMix(valueObject, value)
    if pressed(value) then pulsePC(126, "MUTE MIX") end
end

-- Loop direct select (manual p.35-37):
--   PC 0-99  selects loop 00-99  (same channel path as LOOP UP/DN — reliable)
--   CC115 0-99 is the alternate continuous select path
-- Do NOT throttle these: the 300ms rule applies to button-push PC 100+,
-- not to loop-number select.
function onLoopSelect(valueObject, value)
    local n = clamp(math.floor(value + 0.5), 0, 99)
    sendPC(n)
    sendCC(115, n)
    info.setText(string.format("Loop %02d", n))
end

-- ---------------------------------------------------------------------------
-- Soft-key userFunctions (Assign Buttons backup)
-- pot1..pot4 → soft keys 2-5 when assigned
-- ---------------------------------------------------------------------------

function ufPlay()
    onPlayStop(nil, 127)
end
function ufRecord()
    onRecord(nil, 127)
end
function ufUndo()
    onUndo(nil, 127)
end
function ufTap()
    onTap(nil, 127)
end

preset.userFunctions = {
    pot1 = { call = ufPlay,   name = "PLAY/STOP", close = false },
    pot2 = { call = ufRecord, name = "RECORD",    close = false },
    pot3 = { call = ufUndo,   name = "UNDO",      close = false },
    pot4 = { call = ufTap,    name = "TAP",       close = false },
}

function preset.onLoad()
    syncMidiRoute()
    applyBpm(bpm)
    clockRunning = false
    pcall(function() timer.disable() end)
    setClockPadLabel(false)
end

function preset.onReady()
    syncMidiRoute()
    applyBpm(bpm)
    clockRunning = false
    pcall(function() timer.disable() end)
    setClockPadLabel(false)
    info.setText(string.format("95000 ready P%d ch%d", WANTED_PORT, CH))
end
