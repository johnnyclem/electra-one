-- ============================================================================
-- SCRIPT 3: Control Manipulation & Dynamic UI
-- Purpose: Learn to modify controls, pages, and groups at runtime
-- ============================================================================
-- This script demonstrates:
--   • Getting and modifying control properties
--   • Showing/hiding controls dynamically
--   • Changing control positions (slots)
--   • Working with pages and groups
--   • Value callbacks and formatters
-- ============================================================================
-- Use case: Context-sensitive interfaces that change based on synth state
-- ============================================================================

print("=== Control Manipulation Script Loaded ===")

-- CONTROL ACCESS
-- ============================================================================
-- controls.get(refId) retrieves a control by its reference number
-- Find ref numbers in the Preset Editor's control properties panel

-- Example: Get a control and print its properties
function inspectControl(refId)
    local ctrl = controls.get(refId)
    if ctrl then
        print("--- Control " .. refId .. " ---")
        print("  Name: " .. ctrl:getName())
        print("  Visible: " .. tostring(ctrl:isVisible()))
        print("  Color: " .. string.format("0x%06X", ctrl:getColor()))
        
        -- Get bounds (position and size)
        local bounds = ctrl:getBounds()
        print(string.format("  Position: x=%d y=%d w=%d h=%d",
            bounds[X], bounds[Y], bounds[WIDTH], bounds[HEIGHT]))
        
        -- List value IDs
        local valueIds = ctrl:getValueIds()
        print("  Values: " .. table.concat(valueIds, ", "))
    end
end

-- DYNAMIC VISIBILITY
-- ============================================================================
-- Show/hide controls based on context (e.g., synth mode selection)

-- Hide all controls in a list
function hideControls(controlIds)
    for _, id in ipairs(controlIds) do
        local ctrl = controls.get(id)
        if ctrl then
            ctrl:setVisible(false)
        end
    end
end

-- Show all controls in a list
function showControls(controlIds)
    for _, id in ipairs(controlIds) do
        local ctrl = controls.get(id)
        if ctrl then
            ctrl:setVisible(true)
        end
    end
end

-- Example: Define control groups for different synth modes
-- (Replace with your actual control ref IDs)
local oscillatorControls = {1, 2, 3, 4}      -- OSC parameters
local filterControls = {5, 6, 7, 8}          -- Filter parameters
local envelopeControls = {9, 10, 11, 12}     -- Envelope parameters

-- Switch display mode (call from a List control)
function switchMode(valueObject, value)
    -- value 0 = OSC, 1 = Filter, 2 = Envelope
    
    -- Hide all
    hideControls(oscillatorControls)
    hideControls(filterControls)
    hideControls(envelopeControls)
    
    -- Show selected group
    if value == 0 then
        showControls(oscillatorControls)
        info.setText("OSC Mode")
    elseif value == 1 then
        showControls(filterControls)
        info.setText("Filter Mode")
    elseif value == 2 then
        showControls(envelopeControls)
        info.setText("Envelope Mode")
    end
end

-- MOVING CONTROLS
-- ============================================================================
-- Reassign controls to different slots on the grid

-- Move a control to a specific slot (1-36 on mkII, varies on Mini)
function moveToSlot(controlId, slot)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setSlot(slot)
        print("Moved control " .. controlId .. " to slot " .. slot)
    end
end

-- Move control to slot on specific page
function moveToSlotOnPage(controlId, slot, pageId)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setSlot(slot, pageId)
    end
end

-- Manual positioning with pixel coordinates
function setControlPosition(controlId, x, y, width, height)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setBounds({x, y, width, height})
    end
end

-- CONTROL PROPERTIES
-- ============================================================================

-- Change control name dynamically
function setControlName(controlId, newName)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setName(newName)
    end
end

-- Change control color
function setControlColor(controlId, color)
    -- color is 24-bit RGB, e.g., 0xFF0000 = red
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setColor(color)
    end
end

-- Example: Flash a control red briefly (for alerts).
-- There is no blocking delay API, so the restore is scheduled with the timer.
local flashRestore = nil

function flashControl(controlId)
    local ctrl = controls.get(controlId)
    if ctrl then
        flashRestore = { ctrl = ctrl, color = ctrl:getColor() }
        ctrl:setColor(0xFF0000)
        timer.setPeriod(200)
        timer.enable()
    end
end

function timer.onTick()
    timer.disable()
    if flashRestore then
        flashRestore.ctrl:setColor(flashRestore.color)
        flashRestore = nil
    end
end

-- PAGE MANAGEMENT
-- ============================================================================

-- Switch to a different page
function goToPage(pageId)
    pages.display(pageId)
    print("Switched to page " .. pageId)
end

-- Page change callback
function events.onPageChange(newPageId, oldPageId)
    print(string.format("Page changed: %d -> %d", oldPageId, newPageId))
    info.setText("Page " .. newPageId)
end

-- GROUP MANAGEMENT
-- ============================================================================
-- Groups are visual containers for organizing controls

function setGroupLabel(groupId, label)
    local group = groups.get(groupId)
    if group then
        group:setLabel(label)
    end
end

function setGroupColor(groupId, color)
    local group = groups.get(groupId)
    if group then
        group:setColor(color)
    end
end

-- VALUE CALLBACKS
-- ============================================================================
-- Assign these to controls in the preset editor's "Function" field

-- Example: Called when a fader value changes
-- The valueObject lets you access the control and message
function onValueChange(valueObject, value)
    local control = valueObject:getControl()
    local message = valueObject:getMessage()
    
    print(string.format("%s changed to %d (MIDI: %d)",
        control:getName(),
        value,
        message:getValue()))
end

-- Example: Change color based on value threshold
function colorByValue(valueObject, value)
    local control = valueObject:getControl()
    
    if value > 100 then
        control:setColor(0xFF0000)  -- Red = hot
    elseif value > 50 then
        control:setColor(0xFFFF00)  -- Yellow = warm
    else
        control:setColor(0x00FF00)  -- Green = cool
    end
end

-- VALUE FORMATTERS
-- ============================================================================
-- Return a string to display instead of the raw value

-- Example: Display as percentage
function formatPercent(valueObject, value)
    return string.format("%d%%", value)
end

-- Example: Display as dB
function formatDb(valueObject, value)
    -- Assuming 0-127 maps to -inf to +6dB
    if value == 0 then
        return "-∞ dB"
    else
        local db = (value / 127) * 6 - 6  -- -6 to 0 range example
        return string.format("%.1f dB", db)
    end
end

-- Example: Display note names
local noteNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
function formatNote(valueObject, value)
    local octave = math.floor(value / 12) - 2
    local note = noteNames[(value % 12) + 1]
    return note .. octave
end

-- Example: Display frequency (for filter cutoff)
function formatFrequency(valueObject, value)
    -- Assuming exponential mapping 20Hz to 20kHz over 0-127
    local freq = 20 * math.exp(value / 127 * math.log(1000))
    if freq >= 1000 then
        return string.format("%.1f kHz", freq / 1000)
    else
        return string.format("%.0f Hz", freq)
    end
end

-- OVERLAYS (List Items)
-- ============================================================================
-- Create dynamic lists for controls

function createWaveformOverlay()
    local waveforms = {
        {value = 0, label = "Sine"},
        {value = 1, label = "Triangle"},
        {value = 2, label = "Saw"},
        {value = 3, label = "Square"},
        {value = 4, label = "Noise"}
    }
    
    overlays.create(100, waveforms)  -- ID 100
    print("Created waveform overlay")
end

-- Assign overlay to a control's value
function assignOverlay(controlId, overlayId)
    local ctrl = controls.get(controlId)
    if ctrl then
        local value = ctrl:getValue("value")
        value:setOverlayId(overlayId)
    end
end

-- PRESET READY
-- ============================================================================
function preset.onReady()
    print("Control Manipulation preset ready")
    
    -- Create custom overlays
    -- createWaveformOverlay()
    
    -- Initial UI setup
    -- hideControls(filterControls)
    -- hideControls(envelopeControls)
    
    info.setText("Controls Ready")
end

-- ============================================================================
-- USAGE IN PRESET EDITOR:
-- 1. Create controls with sequential ref IDs
-- 2. In a List control's "Function" field, enter: switchMode
-- 3. In Fader "Function" fields, enter callback names like: colorByValue
-- 4. In "Formatter" fields, enter: formatPercent, formatDb, etc.
-- ============================================================================

