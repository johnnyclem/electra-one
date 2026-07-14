# Yamaha QY100 — Electra One controller

Full-surface Electra One preset for the **Yamaha QY100** music sequencer / XG tone generator.

MIDI map is taken from the official **QY100 Data List** (`QY100E2.pdf`).

## Files

| Path | Role |
|------|------|
| `presets/yamaha_qy100.json` | Device-ready multi-page preset (push with `e1`) |
| `projects/yamaha_qy100.eproj` | Editor project (overview page + Lua) |
| `projects/yamaha_qy100/lua/qy100.lua` | Companion Lua (source of truth for scripts) |
| `projects/yamaha_qy100/generate.py` | Regenerates preset + eproj from Lua + layout |

## Pages

Layout uses the factory demo **4-column grid** (175×122 cells) so nothing stacks or spills.

| # | Name | What it controls |
|---|------|------------------|
| 1 | **Transport** | PLAY / STOP, Song (enc 2), Pattern (enc 3), style sections, master vol (enc 0) |
| 2 | **Vol 1-8** | Parts 1–8 volume (2×4 grid) |
| 3 | **Vol 9-16** | Parts 9–16 volume |
| 4 | **Pan 1-8** | Parts 1–8 pan |
| 5 | **Pan 9-16** | Parts 9–16 pan |
| 6 | **Part** | Focused part: bank / program / drum kit / vol / pan / exp |
| 7 | **Tone** | Focused part tone (CC + NRPN) |
| 8 | **Sends** | Focused rev/cho/var + per-part rev quick sends |
| 9 | **FX** | Reverb / chorus / variation + Var→Rev / Var→Cho |
| 10 | **Sys Levels** | Master volume + transpose only (2 faders, 2 pots) |
| 11 | **Sys Mode** | XG ON / GM ON pads only |
| 12 | **Sys Panic** | Sound off / notes off / reset ctrl / all-param reset pads |

Transport no longer has a CONT pad.

## Devices

16 Electra devices map 1:1 to QY100 parts / MIDI channels 1–16 (`QY Part 1` … `QY Part 16`). Mixer pages send standard CCs on those channels. Focused Part / Tone / Sends pages use Lua and the **Part** selector so one set of knobs follows the active channel.

## MIDI highlights

| Feature | Implementation |
|---------|----------------|
| Transport | MIDI Start / Stop; Continue via Lua `0xFB` |
| Song / Pattern | Song Select `F3` via Lua |
| Style sections | Yamaha SysEx `F0 43 7E 00 ss 7F F7` (ss = 08–0E) |
| Part mixer | CC7 volume, CC10 pan, CC11 expression |
| Effect sends | CC91 reverb, CC93 chorus, CC94 variation |
| Tone (relative) | CC71 harmonic, CC74 brightness, CC73 attack, CC72 release |
| Tone (NRPN) | Vibrato / filter / EG (XG NRPN map) |
| FX types & returns | XG parameter change `F0 43 1n 4C …` |
| Master volume | Universal realtime `F0 7F 7F 04 01 …` |
| XG / GM | XG System On + GM Mode On SysEx |

## Wiring

1. Electra One **PORT 1** → QY100 **MIDI IN** (or TO HOST if configured for MIDI).
2. On the QY100, turn **MIDI Control** reception **On** (utility / MIDI setup).  
   Start/Stop (`FA`/`FC`) and section SysEx are ignored when this is off.
3. For style sections (Intro / Main A–B / Fills / Ending), use **Pattern Play** (or Song with a style). Sections do nothing in pure Song-track edit modes.
4. PLAY / STOP / section pads send via Lua + MIDI; push **both** the JSON and the `.lua` file or the buttons will look fine but not fire.

## Push to device

```sh
# list ports / confirm Electra is visible
node bin/e1.js ports

# 1) preset JSON (device format — no embedded Lua)
node bin/e1.js push presets/yamaha_qy100.json -b 0 -s 1

# 2) companion Lua (required for sections helpers, FX types, part focus, master vol)
node bin/e1.js push presets/yamaha_qy100.lua -b 0 -s 1
# same file: projects/yamaha_qy100/lua/qy100.lua

node bin/e1.js switch -b 0 -s 1
```

**Important:** Electra firmware presets cannot use editor-only `message.type: "virtual"`
and cannot embed Lua in the JSON. Mixer pages work with the JSON alone; Part focus,
global FX, and master volume need the Lua upload.

## Regenerate

After editing `lua/qy100.lua` or `generate.py`:

```sh
python3 projects/yamaha_qy100/generate.py
```

## Coverage notes / roadmap

This preset targets **live performance and mix control**, not bulk dump of entire songs/patterns.

Still open if you want to go deeper:

- [ ] XG multi-part SysEx for every part parameter (not just CCs/NRPNs)
- [ ] Drum-instrument NRPNs (per-note level/pan/filter)
- [ ] Full variation effect parameter lists per type
- [ ] Song / pattern bulk dump request + name display
- [ ] Guitar effect block (QY100-specific model ID `5F`)
- [ ] Tempo via SysEx / external clock UI
- [ ] Complete preset style name overlay (100+ styles from the data list)

## Reference

- Yamaha QY100 Data List: https://data.yamaha.com/files/download/other_assets/0/318130/QY100E2.pdf
- Electra One preset format: `docs/JSON-PresetFormat.pdf`
- Electra One Lua API: `docs/API-LuaExtension.pdf`
