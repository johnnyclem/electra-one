import Foundation

/// A curated set of known-good Electra One Lua scripts that ship with the app to
/// seed the user's Script Library. Each one is written against the real Electra
/// One Lua API (see the `wiki/` knowledge base and `docs/API-LuaExtension.pdf`)
/// and is exercised by `ExampleScriptsTests` through the offline `LuaEngine` so
/// they always at least load, syntax-check, and run in the simulator.
///
/// The visual examples drive the display via `graphics` paint callbacks or
/// `control:setColor`; the MIDI examples send/receive via `midi.*`. Paint-based
/// examples note in their comments that the target preset needs a Custom control.
///
/// Kept as plain `(name, source)` data in ElectraKit — free of any UI types — so
/// both the app (which wraps them in `LibraryScript`) and the test target can use
/// the exact same sources.
public enum ExampleLuaScripts {
    public struct Example: Sendable {
        public let name: String
        public let source: String
    }

    public static let all: [Example] = [
        hello,
        midiMonitor,
        noteEcho,
        arpeggiator,
        lfoToCC,
        scaleQuantizer,
        channelFanout,
        velocityCurve,
        midiClock,
        vuMeter,
        valueReadout,
        adsrVisualizer,
        bouncingBall,
        rainbow,
        noteLights,
    ]

    // ── Basics ────────────────────────────────────────────────────────────────

    static let hello = Example(name: "Hello World (example)", source: """
    -- Electra One Lua. Build to syntax-check, Run to preview here.
    -- Device APIs (controls, midi, parameterMap, timer, …) are mocked offline.
    print("Hello from Electra One!")

    function onReady()
      print("controller:", controller.getModel())
      info.setText("ready")
    end
    """)

    // ── MIDI ──────────────────────────────────────────────────────────────────

    static let midiMonitor = Example(name: "MIDI Monitor", source: """
    -- MIDI Monitor — shows the last incoming MIDI message on the status bar and
    -- in the Console. Push to any preset, then send MIDI to Electra One.
    info.setText("MIDI monitor ready")

    function midi.onMessage(midiInput, msg)
      local text = string.format("ch%d  type=%d  %d / %d",
        msg.channel, msg.type, msg.data1 or 0, msg.data2 or 0)
      info.setText(text)
      print("MIDI:", text)
    end
    """)

    static let noteEcho = Example(name: "Note Echo (+12)", source: """
    -- Note Echo — echoes every incoming note one octave up on PORT_1.
    -- A minimal MIDI-processing template: receive a note, send a new one.
    info.setText("Note echo +12")

    function midi.onNoteOn(midiInput, channel, note, velocity)
      midi.sendNoteOn(PORT_1, channel, note + 12, velocity)
    end

    function midi.onNoteOff(midiInput, channel, note, velocity)
      midi.sendNoteOff(PORT_1, channel, note + 12, velocity)
    end
    """)

    static let arpeggiator = Example(name: "Arpeggiator", source: """
    -- Simple Arpeggiator — hold notes on the input and Electra One plays them in
    -- ascending order, timed to the built-in BPM timer (240 BPM = 8th notes @120).
    local held = {}       -- set of currently-held note numbers
    local step = 0
    local sounding = nil  -- the note currently playing, so we can stop it
    local channel = 1

    timer.setBpm(240)

    function midi.onNoteOn(midiInput, ch, note, velocity)
      if velocity == 0 then held[note] = nil else held[note] = true end
    end

    function midi.onNoteOff(midiInput, ch, note, velocity)
      held[note] = nil
    end

    function timer.onTick()
      if sounding then
        midi.sendNoteOff(PORT_1, channel, sounding, 0)
        sounding = nil
      end
      local notes = {}
      for n in pairs(held) do notes[#notes + 1] = n end
      table.sort(notes)
      if #notes == 0 then return end
      step = (step % #notes) + 1
      sounding = notes[step]
      midi.sendNoteOn(PORT_1, channel, sounding, 100)
    end

    timer.enable()
    info.setText("Arp running (240 bpm)")
    """)

    static let lfoToCC = Example(name: "LFO → CC", source: """
    -- CC LFO — sweeps a Control Change with a sine wave using the timer.
    -- Assign CC 1 (mod wheel) on channel 1 to something on the receiving synth.
    local phase = 0
    local cc = 1
    local channel = 1

    timer.setPeriod(40)   -- ~25 updates per second

    function timer.onTick()
      phase = phase + 0.08
      if phase > math.pi * 2 then phase = phase - math.pi * 2 end
      local value = math.floor((math.sin(phase) * 0.5 + 0.5) * 127 + 0.5)
      midi.sendControlChange(PORT_1, channel, cc, value)
    end

    timer.enable()
    info.setText("LFO -> CC" .. cc)
    print("LFO running on CC " .. cc)
    """)

    static let scaleQuantizer = Example(name: "Scale Quantizer (C minor)", source: """
    -- Scale Quantizer — snaps incoming notes down to the nearest C natural-minor
    -- scale tone before passing them through. Put it in front of a sequencer.
    local scale = { [0]=true, [2]=true, [3]=true, [5]=true, [7]=true, [8]=true, [10]=true }
    local channel = 1

    local function quantize(note)
      local pc = note % 12
      for i = 0, 11 do
        if scale[(pc - i) % 12] then return note - i end
      end
      return note
    end

    function midi.onNoteOn(midiInput, ch, note, velocity)
      midi.sendNoteOn(PORT_1, channel, quantize(note), velocity)
    end

    function midi.onNoteOff(midiInput, ch, note, velocity)
      midi.sendNoteOff(PORT_1, channel, quantize(note), velocity)
    end

    info.setText("Quantize: C minor")
    """)

    static let channelFanout = Example(name: "Channel Fan-out", source: """
    -- Channel Fan-out — copies every incoming note onto MIDI channels 1..4 so a
    -- single keyboard drives four synths in unison. Edit FANOUT to taste.
    local FANOUT = { 1, 2, 3, 4 }

    function midi.onNoteOn(midiInput, ch, note, velocity)
      for _, c in ipairs(FANOUT) do
        midi.sendNoteOn(PORT_1, c, note, velocity)
      end
    end

    function midi.onNoteOff(midiInput, ch, note, velocity)
      for _, c in ipairs(FANOUT) do
        midi.sendNoteOff(PORT_1, c, note, velocity)
      end
    end

    info.setText("Fan-out ch 1-4")
    """)

    static let velocityCurve = Example(name: "Velocity Curve", source: """
    -- Velocity Curve — reshapes note velocity with a gamma curve before passing
    -- notes through. GAMMA < 1 = softer/easier, GAMMA > 1 = harder to reach top.
    local GAMMA = 0.6
    local channel = 1

    local function shape(v)
      local out = math.floor((v / 127) ^ GAMMA * 127 + 0.5)
      if out < 1 then out = 1 end
      return out
    end

    function midi.onNoteOn(midiInput, ch, note, velocity)
      if velocity == 0 then
        midi.sendNoteOff(PORT_1, channel, note, 0)
      else
        midi.sendNoteOn(PORT_1, channel, note, shape(velocity))
      end
    end

    function midi.onNoteOff(midiInput, ch, note, velocity)
      midi.sendNoteOff(PORT_1, channel, note, velocity)
    end

    info.setText("Velocity curve " .. GAMMA)
    """)

    static let midiClock = Example(name: "MIDI Clock Generator", source: """
    -- MIDI Clock — generates 24 PPQN MIDI clock plus Start/Stop on PORT_1 from
    -- Electra's timer. Send CC 118 on ch 1 (127 = start, 0 = stop) to toggle it.
    local running = false

    timer.setBpm(120 * 24)   -- 24 clock pulses per quarter note

    function timer.onTick()
      if running then midi.sendClock(PORT_1) end
    end

    function midi.onControlChange(midiInput, ch, cc, value)
      if cc ~= 118 then return end
      if value > 0 then
        running = true
        midi.sendStart(PORT_1)
        info.setText("Clock: running")
      else
        running = false
        midi.sendStop(PORT_1)
        info.setText("Clock: stopped")
      end
    end

    timer.enable()
    info.setText("Clock ready (CC118 to start)")
    """)

    // ── Visual (graphics paint callbacks) ──────────────────────────────────────
    // These require the target preset to have a *Custom* control at id 1.

    static let vuMeter = Example(name: "VU Meter (visual)", source: """
    -- VU Meter — draws a horizontal level bar on a Custom control (id 1).
    -- Add a Custom control to the preset, push this script, then send CC 7 on
    -- channel 1; the bar tracks the value and turns red when it peaks.
    local level = 0                 -- 0..127
    local meter = controls.get(1)   -- expects a Custom control at id 1

    local function paintMeter(displayObject)
      local bounds = displayObject:getBounds()
      local w, h = bounds[WIDTH], bounds[HEIGHT]
      graphics.setColor(0x202020)
      graphics.fillRect(0, 0, w, h)
      local filled = math.floor(w * level / 127)
      graphics.setColor(level > 100 and RED or GREEN)
      graphics.fillRect(0, 0, filled, h)
      graphics.setColor(WHITE)
      graphics.print(0, h / 2 - 6, tostring(level), w, CENTER)
      return true
    end

    if meter then meter:setPaintCallback(paintMeter) end

    function midi.onControlChange(midiInput, channel, cc, value)
      if cc == 7 then
        level = value
        if meter then meter:repaint() end
      end
    end

    info.setText("VU meter on control 1")
    """)

    static let valueReadout = Example(name: "Big Value Readout (visual)", source: """
    -- Big Value Readout — shows a single value as large centered text on a Custom
    -- control (id 1). Good as a tempo/patch display. Driven by CC 20 on channel 1.
    local value = 0
    local display = controls.get(1)

    local function paint(displayObject)
      local b = displayObject:getBounds()
      graphics.setColor(0x000000)
      graphics.fillRect(0, 0, b[WIDTH], b[HEIGHT])
      graphics.setColor(ORANGE)
      graphics.print(0, b[HEIGHT] / 2 - 12, string.format("%3d", value), b[WIDTH], CENTER)
      return true
    end

    if display then display:setPaintCallback(paint) end

    function midi.onControlChange(midiInput, channel, cc, val)
      if cc == 20 then
        value = val
        if display then display:repaint() end
      end
    end

    info.setText("Value readout on control 1")
    """)

    static let adsrVisualizer = Example(name: "ADSR Visualizer (visual)", source: """
    -- ADSR Visualizer — draws an amplitude envelope from four CCs on a Custom
    -- control (id 1). CC 70=Attack 71=Decay 72=Sustain 73=Release, channel 1.
    local a, d, s, r = 20, 40, 90, 40
    local env = controls.get(1)

    local function paintEnv(displayObject)
      local b = displayObject:getBounds()
      local w, h = b[WIDTH], b[HEIGHT]
      graphics.setColor(0x101018)
      graphics.fillRect(0, 0, w, h)
      local seg = w / 4
      local ax = seg * (a / 127)
      local dx = ax + seg * (d / 127)
      local sy = h - (h * (s / 127))
      local sx = dx + seg
      local rx = sx + seg * (r / 127)
      graphics.setColor(GREEN)
      graphics.drawLine(0, h, ax, 0)      -- attack ramp
      graphics.drawLine(ax, 0, dx, sy)    -- decay
      graphics.drawLine(dx, sy, sx, sy)   -- sustain hold
      graphics.drawLine(sx, sy, rx, h)    -- release
      return true
    end

    if env then env:setPaintCallback(paintEnv) end

    function midi.onControlChange(midiInput, channel, cc, value)
      if     cc == 70 then a = value
      elseif cc == 71 then d = value
      elseif cc == 72 then s = value
      elseif cc == 73 then r = value
      else return end
      if env then env:repaint() end
    end

    info.setText("ADSR visualizer on control 1")
    """)

    static let bouncingBall = Example(name: "Bouncing Ball (visual)", source: """
    -- Bouncing Ball — a small timer-driven animation on a Custom control (id 1).
    -- Purely visual; a handy starting point for scopes and meters.
    local x, y = 20, 20
    local dx, dy = 3, 2
    local ball = controls.get(1)

    local function paintBall(displayObject)
      local b = displayObject:getBounds()
      local w, h = b[WIDTH], b[HEIGHT]
      if x < 6 or x > w - 6 then dx = -dx end
      if y < 6 or y > h - 6 then dy = -dy end
      x = x + dx
      y = y + dy
      graphics.setColor(0x000000)
      graphics.fillRect(0, 0, w, h)
      graphics.setColor(BLUE)
      graphics.fillCircle(x, y, 6)
      return true
    end

    if ball then ball:setPaintCallback(paintBall) end

    timer.setPeriod(33)   -- ~30 fps
    function timer.onTick()
      if ball then ball:repaint() end
    end
    timer.enable()

    info.setText("Bouncing ball on control 1")
    """)

    static let rainbow = Example(name: "Rainbow Colors (visual)", source: """
    -- Rainbow — cycles the colors of controls 1..6 on a timer. Works on ANY
    -- preset with a few controls; no Custom control needed. A quick way to
    -- confirm that Lua is really driving the display.
    local palette = { RED, ORANGE, GREEN, BLUE, PURPLE, WHITE }
    local offset = 0

    timer.setPeriod(500)
    function timer.onTick()
      offset = offset + 1
      for i = 1, 6 do
        local c = controls.get(i)
        if c then c:setColor(palette[((i + offset) % #palette) + 1]) end
      end
    end
    timer.enable()

    info.setText("Rainbow colors")
    """)

    static let noteLights = Example(name: "Note Lights (visual + MIDI)", source: """
    -- Note Lights — recolors control 1 based on the pitch class of incoming notes
    -- and shows the note number on the status bar. Combines MIDI input with a
    -- visual response; works on any preset that has a control at id 1.
    local wheel = { RED, ORANGE, 0xFFFF00, GREEN, BLUE, PURPLE }
    local pad = controls.get(1)

    function midi.onNoteOn(midiInput, channel, note, velocity)
      if velocity == 0 then return end
      if pad then pad:setColor(wheel[(note % #wheel) + 1]) end
      info.setText("note " .. note)
    end

    info.setText("Play a note...")
    """)
}
