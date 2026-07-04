-- ============================================================================
-- SCRIPT 1: Hello World & Basics
-- Purpose: Learn the Electra One Lua environment fundamentals
-- ============================================================================
-- This script demonstrates:
--   • print() for debugging via the web console
--   • Preset lifecycle callbacks (onLoad, onReady)
--   • Accessing controller info
--   • Basic timer usage
-- ============================================================================

-- SETUP SECTION - runs when script loads
-- ============================================================================
print("=== Electra One Lua Script Loaded ===")

-- Query controller information
local model = controller.getModel()
local firmware = controller.getFirmwareVersion()
print("Model: " .. model)
print("Firmware: " .. firmware)

-- Check uptime (milliseconds since power on)
local uptime = controller.uptime()
print("Uptime: " .. math.floor(uptime / 1000) .. " seconds")

-- PRESET CALLBACKS - key lifecycle hooks
-- ============================================================================

-- Called immediately after preset loads, BEFORE default values initialize
function preset.onLoad()
    print(">> preset.onLoad() - Preset is loading...")
    -- Good place for: variable initialization, pre-setup
end

-- Called when preset is fully ready (controls initialized, values set)
function preset.onReady()
    print(">> preset.onReady() - Preset ready to use!")
    -- Good place for: final setup, triggering initial MIDI, UI updates
    
    -- Show a message in the status bar
    info.setText("Hello from Lua!")
end

-- NOTE: onLoad and onReady are the only preset lifecycle callbacks.
-- (There is no onEnter/onLeave — switching presets reloads the script,
-- so onLoad/onReady fire again on every switch.)

-- TIMER DEMO - timed execution
-- ============================================================================
-- The timer fires onTick() at set intervals

local tickCount = 0
local maxTicks = 10  -- Only run 10 times for demo

function timer.onTick()
    tickCount = tickCount + 1
    print("Timer tick #" .. tickCount)
    
    -- Disable timer after max ticks (so it doesn't run forever)
    if tickCount >= maxTicks then
        timer.disable()
        print("Timer disabled after " .. maxTicks .. " ticks")
        info.setText("Timer demo complete!")
    end
end

-- Initialize timer: 500ms period (2 ticks per second)
function startTimerDemo()
    tickCount = 0
    timer.setPeriod(500)
    timer.enable()
    print("Timer started at 500ms period")
end

-- Call this from a control's "function" callback to start the demo
-- Or uncomment the next line to auto-start:
-- startTimerDemo()

-- ============================================================================
-- HOW TO USE THIS SCRIPT:
-- 1. Go to https://app.electra.one and create a new preset
-- 2. Add the Lua script in the Lua editor tab
-- 3. Open the Console log (bottom panel) to see print() output
-- 4. Upload to your Electra One Mini
-- ============================================================================
