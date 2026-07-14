# EHX 95000 — Electra One Mini controller

Electra One **Mini** preset for the **Electro-Harmonix 95000** Performance Loop Laboratory.

MIDI map is from the official *95000 User Reference Manual* v1.0 (pp. 35–37). A copy of the manual is in this folder: `95000-manual.pdf`.

## Why not VLP-200?

The Valeton VLP-200 only supports **MIDI clock sync** on its TRS jacks (other control is CTRL/expression style). The **95000** responds to full **CC + Program Change** on standard MIDI IN — a much better Electra target.

## Files

| Path | Role |
|------|------|
| `presets/ehx_95000.json` | Preset (pages / controls / device) |
| `presets/ehx_95000.lua` | Button/footswitch PC sends + MIDI routing |
| `projects/ehx_95000/generate.py` | Regenerator |
| `projects/ehx_95000/push.sh` | JSON → Lua → switch |
| `projects/ehx_95000.eproj` | Optional editor project |

## Wiring

1. Electra Mini **TRS MIDI OUT** → 95000 **MIDI IN** (use the Mini’s TRS→DIN adapter if needed).
2. Mini device routing: **Port 1 / channel 1** (Mini’s only physical MIDI IO).
3. On the 95000: **PAGE → MIDI CH/SYNC**, set channel to **01** (or **OM** omni).
4. After load, status bar should show `95000 P1 ch1 MIDI_IO`.
5. Activity: Mini **MIDI IO** LED should flash when you turn a fader or hit a pad.

## Pages

| # | Name | Controls |
|---|------|----------|
| 1 | **Mixer** | Track 1–6 volumes (CC20–25), pots 1–6 |
| 2 | **Transport** | **Play/Pause/Stop** · **Record** (amber/red) · UNDO · TRACK FSW · LOOP DN · LOOP UP |
| 3 | **Tracks** | Track 1–6 select (PC 110–115) |
| 4 | **Loop** | Loop list (CC115 0–99), MIX VOL, MASTER, NEW LOOP, MIXDOWN, REVERSE |
| 5 | **Modes** | OCT · PUNCH · QUANTIZE · **EXT IN/XT/BX** · **TEMPO** (BPM) · **Start/Stop MIDI Clock** |

### Soft buttons (every page)

| Soft button | potId | Action |
|-------------|-------|--------|
| 2 | 9 | **Play** / **Pause** / **Stop** (stateful label) |
| 3 | 10 | **Record** (amber idle → red while recording) |
| 4 | 11 | UNDO |
| 5 | 12 | TAP |

Buttons **0–1** stay system-reserved.

## MIDI map (summary)

### Continuous (JSON CC)

| CC | Parameter |
|----|-----------|
| 7 | MASTER LVL |
| 9 | CLIX LVL *(not on layout; available via map)* |
| 14 / 15 | DRY OUT L / R |
| 20–25 | Track 1–6 volume |
| 26 | MIXDOWN volume |
| 27 | TEMPO slider |
| 85–90 | Track pans |
| 102–108 | Overdub (DUB) feedback |
| 115 | Loop direct select 0–99 |

### Buttons (Lua → Program Change)

| PC | Function |
|----|----------|
| 0–99 | Select loop 00–99 |
| 100 | TRACK footswitch |
| 101 | UNDO |
| 102 | RECORD |
| 103 | PLAY/STOP |
| 104 / 105 | LOOP DOWN / UP |
| 106 | NEW LOOP |
| 107 | REVERSE |
| 108 | OCT |
| 109 | TAP |
| 110–115 | Track 1–6 select |
| 116 | MIXDOWN button |
| 117 | PUNCH |
| 118 | QUANTIZE |
| 119 | PAGE |
| 120–126 | Mute/unmute tracks / mix *(in Lua; assign via userFunctions if needed)* |
| 127 | EXT. CLOCK |

Manual note: **≥ 300 ms** between button-push messages (enforced in Lua).

## Push

```sh
# defaults: bank 0, slot 3
./projects/ehx_95000/push.sh

# custom slot
./projects/ehx_95000/push.sh -b 0 -s 3
```

Always push **JSON then Lua then switch** so routing + button script load together.

## Regenerate

```sh
python3 projects/ehx_95000/generate.py
```

## Tips

### Transport labels (Play / Pause / Stop + Record color)

Optimistic UI on **all** Play/Record pads (Transport page + soft keys every page). The 95000 still has one PLAY footswitch (PC 103) and one RECORD (PC 102); Electra just shows clearer labels.

| Transport mode | Play pad | Record pad |
|----------------|----------|------------|
| Stopped | **Play** (green) | **Record** (amber) |
| Playing | **Pause** (green) | **Record** (amber) |
| Recording / overdub | **Stop** (soft red) | **Record** (**red**) |
| Armed (NEW LOOP) | **Play** (green) | **Record** (orange) |

State machine (manual p.11–12):

| Press | From | To |
|-------|------|-----|
| Play | stopped / armed | playing |
| Pause (Play pad) | playing | stopped |
| Stop (Play pad) | recording | stopped |
| Record | stopped / playing / armed | recording |
| Record | recording | playing (exit overdub) |
| NEW LOOP | not armed | armed |
| NEW LOOP | armed | stopped |

There is **no true Pause** on the 95000 — Pause = idle/stop. Empty-loop PLAY is a no-op on the device; Electra may still flip to Play optimistically.

RECORD is still multi-mode hardware (not pure rec-arm):

| Current mode | RECORD does |
|--------------|-------------|
| Idle, empty loop | Start recording a New Loop |
| Idle, loop has audio | Start **overdub** |
| Playback | Enter **overdub** |
| Overdubbing | Exit to **playback** |

Discrete workflows:

1. **Arm then record:** `NEW LOOP` → orange Record → `Record` to capture.
2. **Play only:** use **Play** — does not enter overdub.
3. **End overdub:** press **Record** again (→ playback / Pause label) or **Stop** on the Play pad (→ idle).

### Loop select

- **LOOP DN / LOOP UP** = PC 104 / 105 (step).
- **LOOP list** = PC 0–99 + CC115 (direct load). Status bar shows `Loop NN` when it fires.

### Toggle state tracking

Pads that act as toggles on the 95000 keep **local latch state** on the Mini (label + color):

| Pad | States (UI) | Device LED |
|-----|-------------|------------|
| **OCT** | OCT → OCT ON | off / lit |
| **PUNCH** | PUNCH → PUNCH ON | off / lit |
| **QUANTIZE** | QUANTIZE → QNTZ ON | off / lit |
| **REVERSE** | REVERSE → REV ON | off / lit |
| **MIXDOWN** | MIXDOWN → MIX NORM → MIX CT | off / solid / blink |
| **EXT CLOCK** | **EXT IN** → **EXT XT** → **EXT BX** | off / solid green / rapid blink |

Each Electra press sends the matching PC and advances the UI optimistically.

**Important (manual p.35):** the 95000 **only receives** CC/PC — it does **not** transmit button state. So:

- Presses on the **Electra** update Electra’s pad state.
- Presses on the **95000 hardware** do **not** send MIDI back, so Electra cannot follow them.
- If something *does* send PC 107/108/116–118/127 (or CC3 with the same data) into the Mini, Electra will advance the matching toggle (and will ignore its own thru-echoes when EXT modes enable MIDI THRU).

On load, toggles assume power-up defaults (all off / **EXT IN**). If the hardware was left mid-cycle, press the pad until Electra and the 95000 LEDs match.

### EXT. CLOCK modes (not USB vs DIN)

Both external modes use the **DIN MIDI IN** jack for clock. The difference is transport handling (manual p.12–13, 32):

| Mode | Pad label | LED | Behavior |
|------|-----------|-----|----------|
| **IN** | EXT IN | off | Internal clock; 95000 is MIDI Clock **master** on MIDI OUT |
| **XT** | EXT XT | solid green | Full **slave**: MIDI Clock + Start/Stop/SPP |
| **BX** | EXT BX | rapid blink | Beat-sync **slave**: MIDI Clock only; **ignores Start** |

### MIDI clock master (Electra → 95000)

When the 95000 is in **XT** or **BX**, tempo comes from **MIDI Clock** on its MIDI IN — not from the TEMPO slider / CC27. The Mini can be that clock master:

1. **Modes** → press **EXT** until pad shows **EXT XT** (or **EXT BX**) and the 95000 LED matches.
2. Dial **TEMPO** (40–240 BPM, default 120).
3. Press **Start MIDI Clock** → Mini sends **Start** + 24-PPQN **Clock**. Pad becomes **Stop MIDI Clock**; status `CLK 120 ON`.
4. Press **Stop MIDI Clock** → **Stop** + halt generator; status `CLK 120 OFF`.

Tips:

- Enable **QUANTIZE** when using external clock (manual recommendation).
- Changing **TEMPO** while the clock is running updates the rate live.
- Soft-key **TAP** still sends PC 109 (useful in internal / IN mode only).

### Other

- Input level and headphone knobs are **analog-only** — not MIDI controllable.
- Track mutes (PC 120–126) are in Lua; wire via **Assign Buttons** if you want them on soft keys.
- **PAGE** (PC 119) remains in Lua (`onPage`) if you reassign a control.
