-- ============================================================================
-- SCRIPT 5: SysEx Patch Handler
-- Purpose: Request a patch dump from a synth and unpack it into controls
-- ============================================================================
-- This script demonstrates:
--   • patch.onRequest — responding to the [PATCH REQUEST] action
--   • midi.onSysex + SysexBlock — parsing incoming SysEx byte-by-byte
--   • parameterMap — pushing parsed patch data into on-screen controls
--   • midi.sendSysex — building outgoing SysEx from a plain byte table
-- ============================================================================
-- Perfect for: Synths that answer a dump request with their full patch state
-- ============================================================================

print("=== SysEx Patch Handler Loaded ===")

-- SYNTH DEFINITION
-- ============================================================================
-- Byte layout of the (example) synth's patch dump:
--
--   F0 <mfr> <dev> 10 <p1> <p2> ... <pN> F7
--
-- Adjust MANUFACTURER_ID / DUMP_HEADER / PARAM_TABLE for your hardware.

local MANUFACTURER_ID = 0x42      -- example: single-byte manufacturer id
local DUMP_REQUEST    = 0x11      -- command byte: "send me the edit buffer"
local DUMP_RESPONSE   = 0x10      -- command byte: "here is the edit buffer"

-- Which dump bytes map to which controls. offset is the position of the
-- parameter inside the dump payload (1 = first byte after the command byte).
local PARAM_TABLE = {
    { offset = 1, parameterNumber = 1, name = "Cutoff"    },
    { offset = 2, parameterNumber = 2, name = "Resonance" },
    { offset = 3, parameterNumber = 3, name = "Env Amount" },
    { offset = 4, parameterNumber = 4, name = "LFO Rate"  },
}

local DEVICE_ID = 1               -- the preset's device this patch belongs to

-- REQUESTING A DUMP
-- ============================================================================
-- Called by the firmware when the user triggers [PATCH REQUEST] for a device.

function patch.onRequest(device)
    print("Patch request for device " .. device.id)

    -- Ask the synth for its edit buffer.
    midi.sendSysex(PORT_1, { MANUFACTURER_ID, device.id - 1, DUMP_REQUEST })
    info.setText("Patch requested")
end

-- PARSING THE RESPONSE
-- ============================================================================
-- All incoming SysEx arrives here. sysexBlock exposes the raw message
-- (without F0/F7) via getLength() and peek(position).

function midi.onSysex(midiInput, sysexBlock)
    local length = sysexBlock:getLength()

    -- Too short to be our dump? (mfr + dev + cmd + params)
    if length < 3 + #PARAM_TABLE then
        print("SysEx ignored: only " .. length .. " bytes")
        return
    end

    -- Byte 1: manufacturer, byte 3: command.
    if sysexBlock:peek(1) ~= MANUFACTURER_ID then
        return -- someone else's SysEx — not an error
    end
    if sysexBlock:peek(3) ~= DUMP_RESPONSE then
        print(string.format("SysEx command 0x%02X ignored", sysexBlock:peek(3)))
        return
    end

    print("Patch dump received (" .. length .. " bytes)")
    applyDump(sysexBlock)
end

-- Copy the parameter bytes out of the dump and into the parameter map,
-- which updates every control bound to those parameter numbers.
function applyDump(sysexBlock)
    local applied = 0

    for _, param in ipairs(PARAM_TABLE) do
        -- Dump payload starts after mfr + dev + cmd (3 bytes).
        local position = 3 + param.offset
        if position <= sysexBlock:getLength() then
            local value = sysexBlock:peek(position)
            parameterMap.set(DEVICE_ID, PT_CC7, param.parameterNumber, value)
            print(string.format("  %-10s = %3d", param.name, value))
            applied = applied + 1
        end
    end

    info.setText("Patch loaded")
    print("Applied " .. applied .. " of " .. #PARAM_TABLE .. " parameters")
end

-- SENDING EDITS BACK
-- ============================================================================
-- Attach this as the Function of any fader to echo edits to the synth as
-- parameter-change SysEx instead of plain CC.

function sendParamEdit(valueObject, value)
    local message = valueObject:getMessage()
    local parameterNumber = message:getParameterNumber()

    midi.sendSysex(PORT_1, {
        MANUFACTURER_ID,
        0x00,                 -- device number
        0x20,                 -- command: single parameter change
        parameterNumber,
        value,
    })
end

-- PRESET INITIALIZATION
-- ============================================================================

function preset.onReady()
    print("SysEx patch handler ready")
    info.setText("Press [PATCH REQUEST]")
end

-- ============================================================================
-- PRESET SETUP GUIDE:
--
-- 1. Create a device (ID 1) pointed at your synth's port/channel.
-- 2. Create FADERs with parameter numbers matching PARAM_TABLE
--    (CC 1 Cutoff, CC 2 Resonance, CC 3 Env Amount, CC 4 LFO Rate).
-- 3. Adjust MANUFACTURER_ID / DUMP_REQUEST / DUMP_RESPONSE / PARAM_TABLE
--    to your synth's SysEx implementation chart.
-- 4. Trigger [PATCH REQUEST] from the device menu — the dump lands in the
--    controls automatically.
-- ============================================================================
