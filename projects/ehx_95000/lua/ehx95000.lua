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
-- Toggle state (optimistic local + optional MIDI-in mirror):
--   The 95000 only *receives* CC/PC — it does not transmit button state
--   (manual p.35). Electra tracks toggles when *we* press them, and will
--   also advance UI if a matching PC/CC3 arrives on MIDI IN (thru loop,
--   external controller). Hardware presses on the 95000 itself cannot be
--   observed over MIDI.
--
-- EXT. CLOCK is 3-way (manual p.12–13, 32) — not USB vs DIN:
--   IN  LED off     = internal clock master
--   XT  LED solid   = full external slave (Clock + Start/Stop/SPP)
--   BX  LED blinks  = beat-sync slave (Clock only; ignores Start)
--
-- MIDI clock master (Modes page):
--   TEMPO fader (virtual 40–240 BPM) + Start/Stop MIDI Clock pad.
--   Electra emits 24 PPQN Clock + Start/Stop for XT/BX slave modes.
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
local lastSentPc = -1
local lastSentMs = 0
local ECHO_MS = 80

-- MIDI clock master state (Electra → 95000)
local PPQN = 24
local BPM_MIN, BPM_MAX = 40, 240
local bpm = 120
local clockRunning = false
local CLOCK_PAD_ID = 55
local LABEL_START = "Start MIDI Clock"
local LABEL_STOP  = "Stop MIDI Clock"

-- UI colors (24-bit RGB for Control:setColor)
local COL = {
    dim   = 0x94A3B8,
    rec   = 0xF97316,
    play  = 0x22C55E,
    mix   = 0xF59E0B,
    fx    = 0xEC4899,
    loop  = 0x06B6D4,
    amber = 0xFBBF24,
    green = 0x22C55E,
    pink  = 0xF472B6,
    cyan  = 0x22D3EE,
    orange= 0xFB923C,
}

-- Control ids from generate.py
local ID = {
    reverse  = 45,
    mixdown  = 44,
    oct      = 50,
    punch    = 51,
    quantize = 52,
    extClock = 53,
    clockRun = 55,
}

local ctrlCache = {}

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

local function getCtrl(id)
    if ctrlCache[id] then return ctrlCache[id] end
    local ok, c = pcall(function() return controls.get(id) end)
    if ok and c then
        ctrlCache[id] = c
    end
    return ctrlCache[id]
end

local function paintPad(id, name, color)
    local c = getCtrl(id)
    if not c then return end
    pcall(function() c:setName(name) end)
    pcall(function() c:setColor(color) end)
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

local function setClockPadLabel(running)
    local label = running and LABEL_STOP or LABEL_START
    local color = running and COL.rec or COL.play
    paintPad(CLOCK_PAD_ID, label, color)
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

-- Throttled button press via Program Change (PC 100-127).
-- Returns true if the message was sent.
local function pulsePC(pc, label)
    local t = nowMs()
    if t > 0 and (t - lastBtnMs) < MIN_BTN_MS then
        info.setText("wait…")
        return false
    end
    lastBtnMs = t
    lastSentPc = pc
    lastSentMs = t
    sendPC(pc)
    if label then
        info.setText(label)
    end
    return true
end

local function isOurEcho(pc)
    local t = nowMs()
    if lastSentPc ~= pc then return false end
    if t > 0 and lastSentMs > 0 and (t - lastSentMs) <= ECHO_MS then
        return true
    end
    -- uptime unavailable: still suppress one matching echo shortly after send
    if t == 0 and lastSentPc == pc then
        lastSentPc = -1
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Toggle state (optimistic)
-- ---------------------------------------------------------------------------

-- Binary: false=off, true=on
local bin = {
    reverse  = false,
    oct      = false,
    punch    = false,
    quantize = false,
}

-- EXT. CLOCK: 0=IN, 1=XT, 2=BX
local extMode = 0
-- MIXDOWN: 0=off, 1=normal, 2=constant-tempo
local mixMode = 0

local function applyBinaryUi(key)
    if key == "reverse" then
        if bin.reverse then
            paintPad(ID.reverse, "REV ON", COL.pink)
        else
            paintPad(ID.reverse, "REVERSE", COL.fx)
        end
    elseif key == "oct" then
        if bin.oct then
            paintPad(ID.oct, "OCT ON", COL.pink)
        else
            paintPad(ID.oct, "OCT", COL.fx)
        end
    elseif key == "punch" then
        if bin.punch then
            paintPad(ID.punch, "PUNCH ON", COL.orange)
        else
            paintPad(ID.punch, "PUNCH", COL.rec)
        end
    elseif key == "quantize" then
        if bin.quantize then
            paintPad(ID.quantize, "QNTZ ON", COL.cyan)
        else
            paintPad(ID.quantize, "QUANTIZE", COL.loop)
        end
    end
end

local function applyExtClockUi()
    if extMode == 0 then
        paintPad(ID.extClock, "EXT IN", COL.dim)
    elseif extMode == 1 then
        paintPad(ID.extClock, "EXT XT", COL.green)
    else
        paintPad(ID.extClock, "EXT BX", COL.amber)
    end
end

local function applyMixdownUi()
    if mixMode == 0 then
        paintPad(ID.mixdown, "MIXDOWN", COL.mix)
    elseif mixMode == 1 then
        paintPad(ID.mixdown, "MIX NORM", COL.orange)
    else
        paintPad(ID.mixdown, "MIX CT", COL.amber)
    end
end

local function applyAllToggleUi()
    applyBinaryUi("reverse")
    applyBinaryUi("oct")
    applyBinaryUi("punch")
    applyBinaryUi("quantize")
    applyExtClockUi()
    applyMixdownUi()
    setClockPadLabel(clockRunning)
end

local function extLabel()
    if extMode == 0 then return "EXT IN (internal)" end
    if extMode == 1 then return "EXT XT (full slave)" end
    return "EXT BX (beat sync)"
end

local function mixLabel()
    if mixMode == 0 then return "MIXDOWN off" end
    if mixMode == 1 then return "MIX normal" end
    return "MIX CT"
end

-- Advance local state for a toggle PC (no MIDI send). Used after we send,
-- and when a remote PC/CC3 arrives (not our echo).
local function advanceToggleFromPc(pc)
    if pc == 107 then
        bin.reverse = not bin.reverse
        applyBinaryUi("reverse")
        info.setText(bin.reverse and "REV ON" or "REV OFF")
        return true
    elseif pc == 108 then
        bin.oct = not bin.oct
        applyBinaryUi("oct")
        info.setText(bin.oct and "OCT ON" or "OCT OFF")
        return true
    elseif pc == 117 then
        bin.punch = not bin.punch
        applyBinaryUi("punch")
        info.setText(bin.punch and "PUNCH ON" or "PUNCH OFF")
        return true
    elseif pc == 118 then
        bin.quantize = not bin.quantize
        applyBinaryUi("quantize")
        info.setText(bin.quantize and "QNTZ ON" or "QNTZ OFF")
        return true
    elseif pc == 127 then
        extMode = (extMode + 1) % 3
        applyExtClockUi()
        info.setText(extLabel())
        return true
    elseif pc == 116 then
        mixMode = (mixMode + 1) % 3
        applyMixdownUi()
        info.setText(mixLabel())
        return true
    end
    return false
end

-- Local pad press: send PC then advance UI state.
local function pressToggle(pc)
    if not pulsePC(pc) then return end
    advanceToggleFromPc(pc)
end

-- ---------------------------------------------------------------------------
-- Transport / footswitches (PC) — momentary, no latch
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
    if pressed(value) then pressToggle(107) end
end

function onOct(valueObject, value)
    if pressed(value) then pressToggle(108) end
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
    if pressed(value) then pressToggle(116) end
end

function onPunch(valueObject, value)
    if pressed(value) then pressToggle(117) end
end

function onQuantize(valueObject, value)
    if pressed(value) then pressToggle(118) end
end

function onPage(valueObject, value)
    if pressed(value) then pulsePC(119, "PAGE") end
end

function onExtClock(valueObject, value)
    -- Cycles 95000 IN → XT → BX. Does not start Electra's clock generator.
    if pressed(value) then pressToggle(127) end
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

-- Mute/unmute tracks (PC 120-126) — device-side mute depends on current level;
-- we do not latch mute state here.
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
function onLoopSelect(valueObject, value)
    local n = clamp(math.floor(value + 0.5), 0, 99)
    sendPC(n)
    sendCC(115, n)
    info.setText(string.format("Loop %02d", n))
end

-- ---------------------------------------------------------------------------
-- MIDI IN — mirror toggle advances when a matching PC/CC3 arrives.
-- Suppress our own thru-echoes (EXT CLOCK modes enable MIDI THRU on 95000).
-- ---------------------------------------------------------------------------

local function channelMatches(channel)
    if type(channel) ~= "number" then return true end
    -- 0-based or 1-based channel reporting varies by firmware path
    if channel == CH or channel == (CH - 1) then return true end
    return false
end

function midi.onProgramChange(midiInput, channel, program)
    if not channelMatches(channel) then return end
    if type(program) ~= "number" then return end
    if isOurEcho(program) then return end
    advanceToggleFromPc(program)
end

function midi.onControlChange(midiInput, channel, controllerNumber, value)
    if not channelMatches(channel) then return end
    -- CC3 button-press path (same data values as PC 100–127)
    if controllerNumber == 3 and type(value) == "number" and value >= 100 then
        if isOurEcho(value) then return end
        advanceToggleFromPc(value)
    end
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
    -- Assume power-up defaults (all toggles off / EXT IN). User can resync
    -- by cycling once if the hardware was left in another state.
    bin.reverse = false
    bin.oct = false
    bin.punch = false
    bin.quantize = false
    extMode = 0
    mixMode = 0
    applyAllToggleUi()
end

function preset.onReady()
    syncMidiRoute()
    applyBpm(bpm)
    clockRunning = false
    pcall(function() timer.disable() end)
    applyAllToggleUi()
    info.setText(string.format("95000 ready P%d ch%d", WANTED_PORT, CH))
end
