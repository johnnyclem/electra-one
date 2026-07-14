-- ============================================================================
-- Yamaha QY100 — Electra One companion script
-- Upload separately:  node bin/e1.js push projects/yamaha_qy100/lua/qy100.lua -b B -s S
-- ============================================================================

print("QY100 script loaded")

local OUT = PORT_1
local activePart = 1

-- Controls on Part / Tone / Sends pages whose deviceId follows the Part list
local FOCUS_CTRLS = {
    701, 702, 703, 704, 705, 706, 707, 708, 709, 730,
    710, 711, 712, 713, 714, 715, 716, 717, 718, 719, 720,
}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function sysex(bytes)
    midi.sendSysex(OUT, bytes)
end

-- Rebind focused-part controls to device id == part (1..16)
local function rebindPart(part)
    activePart = clamp(part, 1, 16)
    for _, id in ipairs(FOCUS_CTRLS) do
        local ctrl = controls.get(id)
        if ctrl then
            local val = ctrl:getValue("value")
            if val then
                local msg = val:getMessage()
                if msg then
                    msg:setDeviceId(activePart)
                end
            end
        end
    end
    info.setText(string.format("Part %d", activePart))
end

-- Part selector (list values 0..15)
function onPartSelect(valueObject, value)
    rebindPart(value + 1)
end

function onSongSelect(valueObject, value)
    midi.sendMessage(OUT, { 0xF3, clamp(value, 0, 127) })
    info.setText(string.format("Song %d", value + 1))
end

function onPatternSelect(valueObject, value)
    midi.sendMessage(OUT, { 0xF3, clamp(value, 0, 127) })
    info.setText(string.format("Pattern %d", value + 1))
end

-- Transport realtime (FA start / FC stop). Pad function fires on press (value≠0).
function onPlay(valueObject, value)
    if value ~= 0 then
        midi.sendMessage(OUT, { 0xFA })
        info.setText("PLAY")
    end
end

function onStop(valueObject, value)
    if value ~= 0 then
        midi.sendMessage(OUT, { 0xFC })
        info.setText("STOP")
    end
end

-- Style sections: F0 43 7E 00 ss 7F F7
-- Requires QY100 in Pattern/Song play; MIDI Control reception enabled.
local function section(ss, label)
    sysex({ 0x43, 0x7E, 0x00, ss, 0x7F })
    info.setText(label or "Section")
end

function sectionIntro(valueObject, value)   if value ~= 0 then section(0x08, "INTRO") end end
function sectionMainA(valueObject, value)   if value ~= 0 then section(0x09, "MAIN A") end end
function sectionMainB(valueObject, value)   if value ~= 0 then section(0x0A, "MAIN B") end end
function sectionFillAB(valueObject, value)  if value ~= 0 then section(0x0B, "FILL AB") end end
function sectionFillBA(valueObject, value)  if value ~= 0 then section(0x0C, "FILL BA") end end
function sectionEnding(valueObject, value)  if value ~= 0 then section(0x0D, "ENDING") end end
function sectionBlank(valueObject, value)   if value ~= 0 then section(0x0E, "BLANK") end end

function onMasterVolume(valueObject, value)
    sysex({ 0x7F, 0x7F, 0x04, 0x01, 0x00, clamp(value, 0, 127) })
end

function onTranspose(valueObject, value)
    local semi = clamp(value, -24, 24)
    sysex({ 0x43, 0x10, 0x4C, 0x00, 0x00, 0x04, 0x40 + semi })
end

-- Sys Mode / Sys Panic pages — one-shot pads only
function onXgOn(valueObject, value)
    if value ~= 0 then
        sysex({ 0x43, 0x10, 0x4C, 0x00, 0x00, 0x7E, 0x00 })
        info.setText("XG System On")
    end
end

function onGmOn(valueObject, value)
    if value ~= 0 then
        sysex({ 0x7E, 0x7F, 0x09, 0x01 })
        info.setText("GM Mode On")
    end
end

function onAllSoundOff(valueObject, value)
    if value == 0 then return end
    for ch = 1, 16 do
        midi.sendControlChange(OUT, ch, 120, 0)
    end
    info.setText("All Sound Off")
end

function onAllNotesOff(valueObject, value)
    if value == 0 then return end
    for ch = 1, 16 do
        midi.sendControlChange(OUT, ch, 123, 0)
    end
    info.setText("All Notes Off")
end

function onResetControllers(valueObject, value)
    if value == 0 then return end
    for ch = 1, 16 do
        midi.sendControlChange(OUT, ch, 121, 0)
    end
    info.setText("Reset Controllers")
end

function onAllParamReset(valueObject, value)
    if value == 0 then return end
    sysex({ 0x43, 0x10, 0x4C, 0x00, 0x00, 0x7F, 0x00 })
    info.setText("All Param Reset")
end

-- Global FX via XG parameter change
local function xg(ah, am, al, data)
    local msg = { 0x43, 0x10, 0x4C, ah, am, al }
    for i = 1, #data do msg[#msg + 1] = data[i] end
    sysex(msg)
end

local REVERB = {
    [0] = {0x00,0x00}, [1]={0x01,0x00}, [2]={0x01,0x01}, [3]={0x02,0x00},
    [4]={0x02,0x01}, [5]={0x02,0x02}, [6]={0x03,0x00}, [7]={0x03,0x01},
    [8]={0x04,0x00}, [9]={0x10,0x00}, [10]={0x11,0x00}, [11]={0x13,0x00},
}
local CHORUS = {
    [0]={0x00,0x00}, [1]={0x41,0x00}, [2]={0x41,0x01}, [3]={0x41,0x02},
    [4]={0x41,0x08}, [5]={0x42,0x00}, [6]={0x42,0x01}, [7]={0x42,0x02},
    [8]={0x42,0x08}, [9]={0x43,0x00}, [10]={0x43,0x01}, [11]={0x43,0x08},
}
local VARI = {
    [0]={0x00,0x00}, [1]={0x05,0x00}, [2]={0x06,0x00}, [3]={0x07,0x00},
    [4]={0x08,0x00}, [5]={0x41,0x00}, [6]={0x43,0x00}, [7]={0x44,0x00},
    [8]={0x45,0x00}, [9]={0x46,0x00}, [10]={0x47,0x00}, [11]={0x48,0x00},
    [12]={0x49,0x00}, [13]={0x4A,0x00}, [14]={0x4B,0x00}, [15]={0x4E,0x00},
    [16]={0x40,0x00},
}

function onReverbType(valueObject, value)
    local t = REVERB[value] or REVERB[0]
    xg(0x02, 0x01, 0x00, { t[1] })
    xg(0x02, 0x01, 0x01, { t[2] })
end

function onReverbReturn(valueObject, value)
    xg(0x02, 0x01, 0x0C, { clamp(value, 0, 127) })
end

function onReverbPan(valueObject, value)
    xg(0x02, 0x01, 0x0D, { clamp(value, 0, 127) })
end

function onChorusType(valueObject, value)
    local t = CHORUS[value] or CHORUS[0]
    xg(0x02, 0x01, 0x20, { t[1] })
    xg(0x02, 0x01, 0x21, { t[2] })
end

function onChorusReturn(valueObject, value)
    xg(0x02, 0x01, 0x2C, { clamp(value, 0, 127) })
end

function onChorusPan(valueObject, value)
    xg(0x02, 0x01, 0x2D, { clamp(value, 0, 127) })
end

function onChorusToRev(valueObject, value)
    xg(0x02, 0x01, 0x2E, { clamp(value, 0, 127) })
end

function onVarType(valueObject, value)
    local t = VARI[value] or VARI[0]
    xg(0x02, 0x01, 0x40, { t[1] })
    xg(0x02, 0x01, 0x41, { t[2] })
end

function onVarReturn(valueObject, value)
    xg(0x02, 0x01, 0x56, { clamp(value, 0, 127) })
end

function onVarPan(valueObject, value)
    xg(0x02, 0x01, 0x57, { clamp(value, 0, 127) })
end

function onVarToRev(valueObject, value)
    xg(0x02, 0x01, 0x58, { clamp(value, 0, 127) })
end

function onVarToCho(valueObject, value)
    xg(0x02, 0x01, 0x59, { clamp(value, 0, 127) })
end

function onVarConnection(valueObject, value)
    xg(0x02, 0x01, 0x5A, { clamp(value, 0, 1) })
end

function preset.onReady()
    rebindPart(1)
end
