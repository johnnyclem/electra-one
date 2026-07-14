# Valeton VLP-200 — Electra One Mini controller

Compact Electra One **Mini** preset for the Valeton VLP-200 dual-track looper / multi-track sampler.

## Important MIDI note

The official VLP-200 user manual (firmware V1.0.7) only documents **MIDI clock sync** on the 1/8″ TRS MIDI jacks — not a CC map.

This preset uses the **Valeton looper family MIDI CC scheme** published in the **VLP-400** manual (shared product line). VLP-200 **firmware 1.1+** is expected to accept the same core CCs (volumes, project up/down, footswitch actions).  

**Update the VLP-200 firmware** via Valeton’s software before relying on CC control. Features marked *400-only* (STACK, ONCE, etc.) may no-op on the 200 — pads are included as optional extras.

## Files

| Path | Role |
|------|------|
| `presets/valeton_vlp200.json` | Device preset (Mini layout) |
| `presets/valeton_vlp200.lua` | Companion Lua (project PC helpers) |
| `projects/valeton_vlp200/generate.py` | Regenerator |
| `projects/valeton_vlp200/lua/vlp200.lua` | Lua source |
| `projects/valeton_vlp200.eproj` | Editor overview |

## MIDI map (channel 1 default)

| CC | Range | Function |
|----|-------|----------|
| **2** | 0–127 | LOOP 1 playback volume |
| **3** | 0–127 | LOOP 2 playback volume |
| **4** | 0–127 | DRUM playback volume |
| **5** | 0 | Project UP |
| **6** | 0 | Project DOWN |
| **1** | action id | Footswitch action (see below) |
| **PC** | 0–98 | Project recall P01–P99 |

### Footswitch Action (CC#1 data)

| Data | Action |
|------|--------|
| 0 | Play/Stop All (L1 + L2 + Drum) |
| 1 | DRUM Play/Stop |
| 2 | Tap Tempo |
| 3 | LOOP 1 Rec/Overdub |
| 4 | LOOP 1 STACK *(400-oriented)* |
| 5 | LOOP 1 Play/Stop |
| 6 | LOOP 1 Undo/Redo |
| 7 | LOOP 2 Rec/Overdub |
| 8 | LOOP 2 STACK *(400-oriented)* |
| 9 | LOOP 2 Play/Stop |
| 10 | LOOP 2 Undo/Redo |
| 21 | LOOP 1 ONCE *(400-oriented)* |
| 22 | LOOP 2 ONCE *(400-oriented)* |

MIDI channel select on the unit (VLP-400 method; 200 may match after update): hold LOOP 2 + power on → rotate MEMORY to C01–C16 → reboot.

## Pages (Mini: 6 pots max, ≤480×320)

| # | Name | Controls |
|---|------|----------|
| 1 | **Loops** | LOOP 1/2/DRUM volumes (pots 1–3), STOP ALL / DRUM / TAP pads + soft keys |
| 2 | **Loop Pads** | **2×4 encoders** (pots 1–8): L1/L2 REC·PLAY·UNDO·ONCE; soft keys: STACK / ALL PLAY / ALL STOP / TAP |
| 3 | **Drums** | Drum volume, DRUM toggle, TAP, STOP ALL + soft keys |
| 4 | **Project** | Project list (PC), PROJ UP / DN + soft keys |
| 5 | **Transport** | Large STOP ALL / L1–L2 PLAY / DRUM / L1–L2 REC + soft keys |

### Soft buttons (Mini)

Electra Mini does **not** support a JSON `buttonId` field. Hardware soft
buttons **0–1** are reserved (page / control-set). The four free keys **2–5**
are bound via factory pot aliases **9–12** (Mini has only 8 physical encoders;
pots 9–12 map to those soft keys — same pattern as the demo START/STOP pads):

| Soft button | potId | Action |
|-------------|-------|--------|
| 2 | 9 | L1 STACK |
| 3 | 10 | ALL PLAY |
| 4 | 11 | ALL STOP |
| 5 | 12 | TAP |

These four pads are cloned onto **every page**. On-screen touch also works.
`userFunctions` (`L1 STACK` / `ALL PLAY` / `ALL STOP` / `TAP`) remain available
for **Preset Menu → Assign Buttons** if you want a custom mapping.

Layout rules (enforced by generator):

- encoder pots **1–8** for main controls; soft keys use **9–12**
- **unique potId per page**
- **no overlapping bounds**
- bounds inside Mini canvas

## Wiring

1. Electra Mini **TRS MIDI OUT** → VLP-200 **MIDI IN** (3.5 mm stereo).
   - Mini has **one** TRS MIDI pair = logical **Port 1 / MIDI IO 1**.
   - Do **not** put the device on Port 2 — Port 2 only fans out to USB Host/Device
     on Mini (no physical MIDI IO 2), which is why you only saw USB LEDs.
2. **MIDI channel 1** on both ends.
   - Preset + Lua force **port 1 / ch 1** and Lua pad traffic targets **MIDI_IO**.
3. Prefer VLP-200 firmware **≥ 1.1** for CC control (if your unit has it).
4. After load, status bar should show something like `VLP-200 P1 ch1 MIDI_IO`.
5. When you turn a volume or hit a pad, the Mini **MIDI IO** activity LED should
   flash (not only USB Host / USB Device).

## Buttons / toggles

Pads use a **unique dummy CC carrier + Lua** that pulses the real `CC#1` action.
Do **not** put every action on JSON `CC1` with different `onValue`s — Electra’s
parameter map merges those and buttons stop working.

Volumes stay as normal continuous CCs (those work without Lua).

**You must push the Lua file** or pads will light but send nothing useful.

On Mini, pads are also bound to encoders where noted — **touch the pad** or
**turn/push the bound encoder** (status bar should flash e.g. `L1 REC`).

## Push (always both, in this order)

```sh
# one-shot (defaults: bank 0, slot 2)
./projects/valeton_vlp200/push.sh

# custom bank / slot
./projects/valeton_vlp200/push.sh -b 0 -s 2
./projects/valeton_vlp200/push.sh --bank 1 --slot 5
```

Manual equivalent:

```sh
node bin/e1.js push presets/valeton_vlp200.json -b 0 -s 2
node bin/e1.js push presets/valeton_vlp200.lua -b 0 -s 2   # required: buttons + port fix
node bin/e1.js switch -b 0 -s 2   # reload so Lua onReady runs
```

Always push **JSON then Lua then switch** so device port and Lua `MIDI_IO`
sends stay in sync. Do not leave the slot with only the JSON pushed.

If the Mini MIDI router still lists VLP-200 on a wrong port, set it to
**PORT 1 / channel 1**, then re-push.

## Regenerate

```sh
python3 projects/valeton_vlp200/generate.py
```

## Gaps / roadmap

Not documented on VLP-200 V1.0.7 (no known CC yet):

- [ ] Rhythm pattern select
- [ ] Direct BPM set (use Tap / external clock)
- [ ] SERIAL / FREE mode toggle
- [ ] Auto/Manual record mode
- [ ] Confirm VLP-200 1.1 CC parity with VLP-400 (adjust `ACTION` / CCs in `generate.py` if Valeton publishes a 200-specific chart)

## References

- Local manual: `/Users/johnnyclem/Desktop/valeton_VLP200_manual.pdf` (V1.0.7)
- VLP-400 MIDI Control tables (family CC scheme)
- Valeton firmware: https://www.valeton.net/firmware.html
