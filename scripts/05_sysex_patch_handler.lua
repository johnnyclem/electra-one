-- ============================================================================
-- SCRIPT 4: MIDI LFO Generator
-- Purpose: Create a software LFO that modulates CC values
-- ============================================================================
-- This script demonstrates:
--   • Timer-based periodic execution
--   • parameterMap for value manipulation
--   • Math functions for waveform generation
--   • State management and user-adjustable parameters
--   • Graphics API for custom control visualization
-- ============================================================================
-- Perfect for: Adding modulation to synths that lack built-in LFOs
-- ============================================================================

print("=== MIDI LFO Generator Loaded ===")

-- LFO STATE
-- ============================================================================
local lfo = {
    enabled = false,
    phase = 0,              -- Current position in cycle (0-1)
    rate = 1.0,             -- Hz (cycles per second)
    depth = 64,             -- Modulation depth (0-127)
    waveform = 0,           -- 0=sine, 1=triangle, 2=saw, 3=square, 4=random
    targetCC = 1,           -- CC number to modulate (default: mod wheel)
    targetChannel = 1,      -- MIDI channel
    centerValue = 64,       -- Center point of modulation
    lastOutput = 0,         -- Last calculated value (for display)
}

-- Waveform names for display
local waveformNames = {"Sine", "Triangle", "Saw Up", "Square", "Random"}

-- WAVEFORM GENERATORS
-- ============================================================================
-- Each returns a value from -1 to +1

function generateSine(phase)
    return math.sin(phase * 2 * math.pi)
end

function generateTriangle(phase)
    if phase < 0.25 then
        return phase * 4
    elseif phase < 0.75 then
        return 1 - (phase - 0.25) * 4
    else
        return -1 + (phase - 0.75) * 4
    end
end

function generateSawUp(phase)
    return phase * 2 - 1
end

function generateSquare(phase)
    return phase < 0.5 and 1 or -1
end

function generateRandom(phase)
    -- Sample-and-hold style random
    return math.random() * 2 - 1
end

-- Get waveform value based on current waveform type
function getWaveformValue(phase, waveformType)
    if waveformType == 0 then
        return generateSine(phase)
    elseif waveformType == 1 then
        return generateTriangle(phase)
    elseif waveformType == 2 then
        return generateSawUp(phase)
    elseif waveformType == 3 then
        return generateSquare(phase)
    elseif waveformType == 4 then
        return generateRandom(phase)
    end
    return 0
end

-- LFO CORE
-- ============================================================================

-- Calculate the LFO output value
function calculateLFO()
    -- Get raw waveform (-1 to +1)
    local raw = getWaveformValue(lfo.phase, lfo.waveform)
    
    -- Scale by depth and add to center
    local scaled = raw * lfo.depth
    local output = lfo.centerValue + scaled
    
    -- Clamp to valid MIDI range
    output = math.max(0, math.min(127, math.floor(output)))
    
    lfo.lastOutput = output
    return output
end

-- Advance the LFO phase based on timer period
local TIMER_PERIOD_MS = 20  -- 50 Hz update rate

function advancePhase()
    local periodSeconds = 1 / lfo.rate
    local phaseIncrement = (TIMER_PERIOD_MS / 1000) / periodSeconds
    lfo.phase = (lfo.phase + phaseIncrement) % 1.0
end

-- TIMER CALLBACK
-- ============================================================================
function timer.onTick()
    if not lfo.enabled then
        return
    end
    
    -- Calculate and send LFO value
    local output = calculateLFO()
    
    -- Send as CC message
    midi.sendControlChange(PORT_1, lfo.targetChannel, lfo.targetCC, output)
    
    -- Advance phase for next tick
    advancePhase()
end

-- LFO CONTROL FUNCTIONS
-- ============================================================================
-- These can be called from control callbacks

function enableLFO(valueObject, value)
    lfo.enabled = (value > 0)
    
    if lfo.enabled then
        lfo.phase = 0  -- Reset phase on enable
        timer.enable()
        info.setText("LFO ON")
        print("LFO enabled")
    else
        timer.disable()
        info.setText("LFO OFF")
        print("LFO disabled")
    end
end

function setLFORate(valueObject, value)
    -- Map 0-127 to 0.1-10 Hz (logarithmic feels better)
    lfo.rate = 0.1 * math.exp(value / 127 * math.log(100))
    print(string.format("LFO Rate: %.2f Hz", lfo.rate))
end

function setLFODepth(valueObject, value)
    lfo.depth = value / 2  -- 0-127 -> 0-63.5 (half range each direction)
    print(string.format("LFO Depth: %d", lfo.depth))
end

function setLFOWaveform(valueObject, value)
    lfo.waveform = value
    print("LFO Waveform: " .. waveformNames[value + 1])
end

function setLFOTargetCC(valueObject, value)
    lfo.targetCC = value
    print("LFO Target CC: " .. value)
end

function setLFOCenter(valueObject, value)
    lfo.centerValue = value
    print("LFO Center: " .. value)
end

-- VALUE FORMATTERS
-- ============================================================================

function formatLFORate(valueObject, value)
    local rate = 0.1 * math.exp(value / 127 * math.log(100))
    return string.format("%.1f Hz", rate)
end

function formatLFOWaveform(valueObject, value)
    return waveformNames[value + 1] or "?"
end

-- CUSTOM CONTROL: LFO VISUALIZER
-- ============================================================================
-- This draws the LFO waveform on a Custom control type

function drawLFOVisualizer(control, x, y, width, height)
    -- Background
    graphics.setColor(0x202020)
    graphics.fillRect(x, y, width, height)
    
    -- Border
    graphics.setColor(0x404040)
    graphics.drawRect(x, y, width, height)
    
    -- Center line
    graphics.setColor(0x606060)
    local centerY = y + height / 2
    graphics.drawLine(x, centerY, x + width, centerY)
    
    -- Draw waveform
    graphics.setColor(0x00FFFF)  -- Cyan
    
    local prevY = nil
    for i = 0, width - 1 do
        local phase = i / width
        local value = getWaveformValue(phase, lfo.waveform)
        local drawY = centerY - value * (height / 2 - 4)
        
        if prevY then
            graphics.drawLine(x + i - 1, prevY, x + i, drawY)
        end
        prevY = drawY
    end
    
    -- Draw current phase position
    local phaseX = x + lfo.phase * width
    graphics.setColor(0xFF0000)  -- Red playhead
    graphics.drawLine(phaseX, y + 2, phaseX, y + height - 2)
    
    -- Draw current output value as a dot
    local outputY = centerY - (lfo.lastOutput - 64) / 64 * (height / 2 - 4)
    graphics.setColor(0xFFFF00)  -- Yellow
    graphics.fillCircle(phaseX, outputY, 4)
end

-- Register the paint callback for a Custom control
-- (You'd call this in preset.onReady() with the control's ref ID)
function setupVisualizer(controlId)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setPaintCallback(function(control)
            local bounds = control:getBounds()
            drawLFOVisualizer(control, bounds[X], bounds[Y], 
                             bounds[WIDTH], bounds[HEIGHT])
        end)
        print("LFO Visualizer setup on control " .. controlId)
    end
end

-- Repaint the visualizer periodically
local repaintCounter = 0
local REPAINT_INTERVAL = 5  -- Every 5 timer ticks (100ms at 50Hz)

function timer.onTick()
    if not lfo.enabled then
        return
    end
    
    -- Calculate and send LFO value
    local output = calculateLFO()
    midi.sendControlChange(PORT_1, lfo.targetChannel, lfo.targetCC, output)
    
    -- Advance phase
    advancePhase()
    
    -- Repaint visualizer less frequently (for performance)
    repaintCounter = repaintCounter + 1
    if repaintCounter >= REPAINT_INTERVAL then
        repaintCounter = 0
        -- If you have a visualizer control, repaint it here
        -- local vizControl = controls.get(VISUALIZER_CONTROL_ID)
        -- if vizControl then vizControl:repaint() end
    end
end

-- PRESET INITIALIZATION
-- ============================================================================

function preset.onReady()
    print("MIDI LFO preset ready")
    
    -- Initialize timer at 50Hz (20ms period)
    timer.setPeriod(TIMER_PERIOD_MS)
    
    -- Create waveform overlay for list control
    overlays.create(1, {
        {value = 0, label = "Sine"},
        {value = 1, label = "Triangle"},
        {value = 2, label = "Saw Up"},
        {value = 3, label = "Square"},
        {value = 4, label = "Random"}
    })
    
    -- Setup visualizer if you have a Custom control for it
    -- setupVisualizer(YOUR_CUSTOM_CONTROL_ID)
    
    info.setText("LFO Ready")
end

-- ============================================================================
-- PRESET SETUP GUIDE:
-- 
-- Create these controls in the Preset Editor:
-- 1. PAD "Enable" - Function: enableLFO
-- 2. FADER "Rate" - Function: setLFORate, Formatter: formatLFORate
-- 3. FADER "Depth" - Function: setLFODepth
-- 4. LIST "Wave" - Function: setLFOWaveform, Overlay ID: 1
-- 5. FADER "Target CC" - Function: setLFOTargetCC, Min: 0, Max: 127
-- 6. FADER "Center" - Function: setLFOCenter, Default: 64
-- 7. (Optional) CUSTOM "Display" - for waveform visualization
--
-- All controls should use Device ID 1 (or create a virtual device)
-- ============================================================================

