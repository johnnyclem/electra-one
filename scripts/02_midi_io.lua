-- ============================================================================
-- SCRIPT 2: MIDI Input/Output
-- Purpose: Learn to send and receive MIDI messages
-- ============================================================================
-- This script demonstrates:
--   • Sending various MIDI message types
--   • Receiving and processing incoming MIDI
--   • MIDI callbacks for specific message types
--   • Working with SysEx
-- ============================================================================
-- Great for: Ableton Live integration, controlling hardware synths
-- ============================================================================

print("=== MIDI I/O Script Loaded ===")

-- SENDING MIDI MESSAGES
-- ============================================================================
-- PORT_1 = MIDI port 1, PORT_2 = MIDI port 2
-- For USB MIDI to Ableton, typically use PORT_1

-- Function to send a CC message (e.g., for Ableton device control)
function sendCC(channel, ccNumber, value)
    midi.sendControlChange(PORT_1, channel, ccNumber, value)
    print(string.format("Sent CC: ch=%d cc=%d val=%d", channel, ccNumber, value))
end

-- Function to send program change (switch patches on a synth)
function sendProgramChange(channel, program)
    midi.sendProgramChange(PORT_1, channel, program)
    print(string.format("Sent Program Change: ch=%d prog=%d", channel, program))
end

-- Function to send a note (useful for triggering clips in Ableton)
-- There is no blocking delay API in the Electra Lua environment, so the
-- note-off is scheduled with the timer instead of a sleep.
local pendingNoteOff = nil

function sendNote(channel, note, velocity, durationMs)
    midi.sendNoteOn(PORT_1, channel, note, velocity)
    print(string.format("Note ON: ch=%d note=%d vel=%d", channel, note, velocity))

    if durationMs and durationMs > 0 then
        pendingNoteOff = { channel = channel, note = note }
        timer.setPeriod(durationMs)
        timer.enable()
    end
end

-- Fires once per scheduled note-off, then disarms itself.
function timer.onTick()
    timer.disable()
    if pendingNoteOff then
        midi.sendNoteOff(PORT_1, pendingNoteOff.channel, pendingNoteOff.note, 0)
        print("Note OFF")
        pendingNoteOff = nil
    end
end

-- Send NRPN (14-bit high-res control - common on modern synths)
function sendNRPN(channel, paramNumber, value)
    -- lsbFirst=false, reset=true (sends RPN reset after)
    midi.sendNrpn(PORT_1, channel, paramNumber, value, false, true)
    print(string.format("Sent NRPN: param=%d val=%d", paramNumber, value))
end

-- Send 14-bit CC (for high-resolution control)
function sendCC14(channel, ccNumber, value)
    -- ccNumber should be 0-31 (MSB), LSB is automatically ccNumber+32
    midi.sendControlChange14Bit(PORT_1, channel, ccNumber, value, false)
    print(string.format("Sent 14-bit CC: cc=%d val=%d", ccNumber, value))
end

-- RECEIVING MIDI - Callbacks
-- ============================================================================
-- Define these functions to handle specific incoming MIDI types

-- Generic handler - catches ALL incoming MIDI
function midi.onMessage(midiInput, midiMessage)
    -- midiInput.interface tells us where it came from
    -- midiInput.port is the port number
    
    if midiMessage.type ~= CLOCK then  -- Filter out clock to reduce spam
        print(string.format("MIDI: type=%d ch=%d data1=%d data2=%d from=%s",
            midiMessage.type,
            midiMessage.channel or 0,
            midiMessage.data1 or 0,
            midiMessage.data2 or 0,
            midiInput.interface))
    end
end

-- Specific handler for Control Change
function midi.onControlChange(midiInput, channel, controllerNumber, value)
    print(string.format("CC received: ch=%d cc=%d val=%d", 
        channel, controllerNumber, value))
    
    -- Example: Echo received CC to status bar
    info.setText(string.format("CC %d = %d", controllerNumber, value))
    
    -- Example: Map incoming CC to a control value
    -- parameterMap.set(deviceId, PT_CC7, controllerNumber, value)
end

-- Specific handler for Note On
function midi.onNoteOn(midiInput, channel, noteNumber, velocity)
    print(string.format("Note ON: ch=%d note=%d vel=%d", 
        channel, noteNumber, velocity))
end

-- Specific handler for Note Off
function midi.onNoteOff(midiInput, channel, noteNumber, velocity)
    print(string.format("Note OFF: ch=%d note=%d", channel, noteNumber))
end

-- Specific handler for Program Change
function midi.onProgramChange(midiInput, channel, programNumber)
    print(string.format("Program Change: ch=%d prog=%d", channel, programNumber))
    info.setText("Program: " .. programNumber)
end

-- Specific handler for Pitch Bend
function midi.onPitchBend(midiInput, channel, value)
    -- value is -8192 to +8191, center is 0
    print(string.format("Pitch Bend: ch=%d val=%d", channel, value))
end

-- SysEx handler - for patch dumps, deep editing, etc.
function midi.onSysex(midiInput, sysexBlock)
    local length = sysexBlock:getLength()
    -- Byte 1 is the manufacturer id (sysexBlock excludes the F0/F7 framing).
    local mfgId = sysexBlock:peek(1)

    print(string.format("SysEx received: %d bytes, Manufacturer ID: %d",
        length, mfgId))

    -- Example: print first few bytes
    local preview = "Bytes: "
    for i = 1, math.min(10, length) do
        preview = preview .. string.format("%02X ", sysexBlock:peek(i))
    end
    print(preview)
end

-- MIDI CLOCK & TRANSPORT
-- ============================================================================
-- Use transport module for external clock sync (better than timer for sync)

-- Enable to receive transport messages
transport.enable()

function transport.onStart(midiInput)
    print("TRANSPORT: Start")
    info.setText("▶ Playing")
end

function transport.onStop(midiInput)
    print("TRANSPORT: Stop")
    info.setText("■ Stopped")
end

function transport.onContinue(midiInput)
    print("TRANSPORT: Continue")
end

-- Clock is called 24 times per quarter note
local clockPulseCount = 0
function transport.onClock(midiInput)
    clockPulseCount = clockPulseCount + 1
    
    -- Log every beat (24 pulses = 1 quarter note)
    if clockPulseCount % 24 == 0 then
        print("Beat: " .. (clockPulseCount / 24))
    end
end

-- EXAMPLE: Preset ready hook to send initial MIDI
-- ============================================================================
function preset.onReady()
    print("MIDI I/O preset ready")
    
    -- Example: Request all notes off on channel 1 (CC 123)
    -- midi.sendControlChange(PORT_1, 1, 123, 0)
    
    info.setText("MIDI I/O Ready")
end

-- ============================================================================
-- TEST FUNCTIONS - call these from control callbacks
-- ============================================================================

-- Trigger a C3 note for 200ms
function testNote()
    sendNote(1, 60, 100, 200)
end

-- Send a test CC sweep. The values go out back-to-back; if the receiver
-- needs pacing, step the sweep from timer.onTick instead.
function testCCSweep()
    for i = 0, 127, 16 do
        sendCC(1, 1, i)  -- Mod wheel sweep
    end
end

-- ============================================================================
-- NOTES FOR ABLETON LIVE:
-- 1. Set Electra One as a MIDI input in Live's preferences
-- 2. Enable "Remote" for the Electra One port
-- 3. Use MIDI Map mode to assign CC messages to parameters
-- 4. For transport sync, ensure Live is sending MIDI clock
-- ============================================================================

