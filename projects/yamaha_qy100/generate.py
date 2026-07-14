#!/usr/bin/env python3
"""Generate a device-valid Electra One preset for the Yamaha QY100.

Layout follows the factory demo grid (4 columns × large cells) so controls
do not stack or spill off-screen. Electra’s usable area is roughly 1000×480.

Outputs:
  presets/yamaha_qy100.json
  presets/yamaha_qy100.lua
  projects/yamaha_qy100.eproj
"""

from __future__ import annotations

import json
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LUA_PATH = Path(__file__).resolve().parent / "lua" / "qy100.lua"

# Factory-demo style 4-column grid (from b0_s00_Demo_Preset.json)
#   fader cell: 175×122  ·  origin (20, 36)  ·  step (196, 162)
#   pad/list:   146×56   ·  bottom band y=363
CELL_W, CELL_H = 196, 162
ORIGIN_X, ORIGIN_Y = 20, 36
CTRL_W, CTRL_H = 175, 122
PAD_W, PAD_H = 146, 56
LIST_W, LIST_H = 175, 56
LIST_WIDE_W = 370  # 2 columns
BOTTOM_Y = 363

C_PLAY = "22C55E"
C_STOP = "EF4444"
C_SEC = "F59E0B"
C_MIX = "06B6D4"
C_PART = "A3E635"
C_TONE = "EAB308"
C_SEND = "8B5CF6"
C_FX = "C084FC"
C_SYS = "E5E7EB"
C_WHT = "FFFFFF"
C_DIM = "94A3B8"

LUA_CC = 20  # unused CC carrier for Lua-driven params


def uid() -> str:
    return str(uuid.uuid4())


def cell(col: int, row: int, w: int = CTRL_W, h: int = CTRL_H) -> list[int]:
    """Place a control in the 4-col demo grid (col/row 0-based)."""
    return [ORIGIN_X + col * CELL_W, ORIGIN_Y + row * CELL_H, w, h]


def bottom(col: int, w: int = PAD_W, h: int = PAD_H) -> list[int]:
    """Bottom action band (pads / short lists), 6 slots across."""
    step = 160
    return [20 + col * step, BOTTOM_Y, w, h]


def pot(n: int) -> list[dict]:
    return [{"potId": n, "valueId": "value"}]


def fader(
    cid: int,
    name: str,
    page: int,
    col: int,
    row: int,
    *,
    device_id: int,
    param: int,
    color: str = C_MIX,
    pot_id: int | None = None,
    default: int = 100,
    min_v: int = 0,
    max_v: int = 127,
    msg_type: str = "cc7",
    function: str | None = None,
    control_set: int = 1,
    variant: str = "thin",
) -> dict:
    msg = {
        "deviceId": device_id,
        "type": msg_type,
        "parameterNumber": param,
        "min": 0,
        "max": 127,
    }
    val: dict = {
        "id": "value",
        "min": min_v,
        "max": max_v,
        "defaultValue": default,
        "message": msg,
    }
    if function:
        val["function"] = function
    ctrl: dict = {
        "id": cid,
        "type": "fader",
        "visible": True,
        "variant": variant,
        "name": name[:14],
        "color": color,
        "bounds": cell(col, row),
        "pageId": page,
        "controlSetId": control_set,
        "values": [val],
    }
    if pot_id is not None:
        ctrl["inputs"] = pot(pot_id)
    return ctrl


def pad(
    cid: int,
    name: str,
    page: int,
    *,
    bounds: list[int],
    device_id: int,
    color: str,
    msg_type: str = "cc7",
    param: int = 0,
    function: str | None = None,
    sysex: list[int] | None = None,
    pot_id: int | None = None,
    control_set: int = 1,
) -> dict:
    """Build a pad.

    Electra state controls only transmit when onValue is set (except native
    start/stop/tune). Match the factory demo:
      - start/stop: message type only, no defaultValue
      - cc7 / SysEx action pads: onValue=127 + defaultValue "off"
    Prefer a Lua function for transport/sections so presses always fire.
    """
    if msg_type in ("start", "stop", "tune") and function is None and sysex is None:
        # Pure transport pad (demo style)
        msg: dict = {"deviceId": device_id, "type": msg_type}
        val: dict = {"id": "value", "message": msg}
    elif sysex is not None:
        # Fixed SysEx payload; onValue required or the pad never transmits
        msg = {
            "deviceId": device_id,
            "type": "SysEx",
            "data": sysex,
            "onValue": 127,
        }
        val = {"id": "value", "message": msg, "defaultValue": "off"}
    else:
        # Momentary CC (or CC + Lua) — same pattern as demo REWIND
        msg = {
            "deviceId": device_id,
            "type": "cc7",
            "parameterNumber": param,
            "onValue": 127,
        }
        val = {"id": "value", "message": msg, "defaultValue": "off"}

    if function:
        val["function"] = function

    ctrl: dict = {
        "id": cid,
        "type": "pad",
        "mode": "momentary",
        "visible": True,
        "name": name[:14],
        "color": color,
        "bounds": bounds,
        "pageId": page,
        "controlSetId": control_set,
        "values": [val],
    }
    if pot_id is not None:
        ctrl["inputs"] = pot(pot_id)
    return ctrl


def list_ctrl(
    cid: int,
    name: str,
    page: int,
    *,
    bounds: list[int],
    device_id: int,
    overlay_id: int,
    param: int,
    msg_type: str = "cc7",
    function: str | None = None,
    min_v: int = 0,
    max_v: int = 127,
    default: int = 0,
    color: str = C_WHT,
    pot_id: int | None = None,
    control_set: int = 1,
) -> dict:
    msg = {
        "deviceId": device_id,
        "type": msg_type,
        "parameterNumber": param,
        "min": min_v,
        "max": max_v,
    }
    val: dict = {
        "id": "value",
        "min": min_v,
        "max": max_v,
        "defaultValue": default,
        "overlayId": overlay_id,
        "message": msg,
    }
    if function:
        val["function"] = function
    ctrl: dict = {
        "id": cid,
        "type": "list",
        "visible": True,
        "variant": "valueOnly",
        "name": name[:14],
        "color": color,
        "bounds": bounds,
        "pageId": page,
        "controlSetId": control_set,
        "values": [val],
    }
    if pot_id is not None:
        ctrl["inputs"] = pot(pot_id)
    return ctrl


def overlay(oid: int, items: list[tuple[int, str]]) -> dict:
    return {"id": oid, "items": [{"value": v, "label": lab[:20]} for v, lab in items]}


def build_overlays() -> list[dict]:
    parts = [(i, f"Part {i + 1}") for i in range(16)]
    songs = [(i, f"Song {i + 1:02d}") for i in range(20)]
    patterns = [(i, f"Pat {i + 1:03d}") for i in range(64)]
    bank_msb = [
        (0, "XG Normal"),
        (64, "SFX Normal"),
        (126, "SFX Kit"),
        (127, "XG Drum"),
    ]
    drums = [
        (0, "1 Standard"), (1, "2 Standard2"), (2, "3 Dry"), (3, "4 Bright"),
        (8, "5 Room"), (9, "6 Dark"), (16, "7 Rock"), (17, "8 Rock2"),
        (24, "9 Electro"), (25, "10 Analog"), (26, "11 Analog2"), (27, "12 Dance"),
        (28, "13 HipHop"), (29, "14 Jungle"), (32, "15 Jazz"), (33, "16 Jazz2"),
        (40, "17 Brush"), (48, "18 Symphony"), (112, "19 R&B"), (113, "20 Rock3"),
    ]
    gm = [
        "GrandPno", "BritePno", "El.Grand", "HnkyTonk", "E.Piano1", "E.Piano2",
        "Harpsi", "Clavi", "Celesta", "Glocken", "MusicBox", "Vibes",
        "Marimba", "Xylophon", "TubulBel", "Dulcimer", "DrawOrgn", "PercOrgn",
        "RockOrgn", "ChrchOrg", "ReedOrgn", "Acordion", "Harmnica", "TangoAcd",
        "NylonGtr", "SteelGtr", "Jazz Gtr", "CleanGtr", "Mute.Gtr", "Ovrdrive",
        "Dist.Gtr", "GtrHarmo", "Aco.Bass", "FngrBass", "PickBass", "Fretless",
        "SlapBas1", "SlapBas2", "SynBass1", "SynBass2", "Violin", "Viola",
        "Cello", "Contrabs", "Trem.Str", "Pizz.Str", "Harp", "Timpani",
        "Strings1", "Strings2", "Syn Str1", "Syn Str2", "ChoirAah", "VoiceOoh",
        "SynVoice", "Orch.Hit", "Trumpet", "Trombone", "Tuba", "Mute Trp",
        "Fr.Horn", "BrssSect", "SynBrss1", "SynBrss2", "SprnoSax", "Alto Sax",
        "TenorSax", "Bari.Sax", "Oboe", "Eng.Horn", "Bassoon", "Clarinet",
        "Piccolo", "Flute", "Recorder", "PanFlute", "Bottle", "Shakhchi",
        "Whistle", "Ocarina", "SquareLd", "Saw Ld", "CaliopLd", "Chiff Ld",
        "CharanLd", "Voice Ld", "Fifth Ld", "Bass&Ld", "NewAgePd", "Warm Pad",
        "PolySyPd", "ChoirPad", "BowedPad", "MetalPad", "Halo Pad", "SweepPad",
        "Rain", "SoundTrk", "Crystal", "Atmosphr", "Bright", "Goblins",
        "Echoes", "Sci-Fi", "Sitar", "Banjo", "Shamisen", "Koto",
        "Kalimba", "Bagpipe", "Fiddle", "Shanai", "TnklBell", "Agogo",
        "SteelDrm", "Woodblok", "TaikoDrm", "MelodTom", "Syn Drum", "RevCymbl",
        "FretNoiz", "BrthNoiz", "Seashore", "Tweet", "Telphone", "Helicptr",
        "Applause", "Gunshot",
    ]
    programs = [(i, f"{i + 1:03d} {gm[i]}") for i in range(128)]
    reverb = [
        (0, "Off"), (1, "Hall1"), (2, "Hall2"), (3, "Room1"), (4, "Room2"),
        (5, "Room3"), (6, "Stage1"), (7, "Stage2"), (8, "Plate"),
        (9, "White Room"), (10, "Tunnel"), (11, "Basement"),
    ]
    chorus = [
        (0, "Off"), (1, "Chorus1"), (2, "Chorus2"), (3, "Chorus3"), (4, "Chorus4"),
        (5, "Celeste1"), (6, "Celeste2"), (7, "Celeste3"), (8, "Celeste4"),
        (9, "Flanger1"), (10, "Flanger2"), (11, "Flanger3"),
    ]
    variation = [
        (0, "Off"), (1, "Delay LCR"), (2, "Delay LR"), (3, "Echo"),
        (4, "Cross Delay"), (5, "Chorus1"), (6, "Flanger1"), (7, "Symphonic"),
        (8, "Rotary"), (9, "Tremolo"), (10, "Auto Pan"), (11, "Phaser1"),
        (12, "Distortion"), (13, "Overdrive"), (14, "Amp Sim"),
        (15, "Auto Wah"), (16, "Thru"),
    ]
    var_conn = [(0, "Insertion"), (1, "System")]
    return [
        overlay(1, parts),
        overlay(2, songs),
        overlay(3, patterns),
        overlay(4, bank_msb),
        overlay(5, drums),
        overlay(6, programs),
        overlay(7, reverb),
        overlay(8, chorus),
        overlay(9, variation),
        overlay(10, var_conn),
    ]


def build_devices() -> list[dict]:
    return [
        {"id": i, "name": f"QY Part {i}", "port": 1, "channel": i, "rate": 20}
        for i in range(1, 17)
    ]


def build_pages() -> list[dict]:
    # Max 12 pages. System is three *real* pages (no Lua overlay hacks) so
    # pots never multi-bind. Expression lives on Part page only.
    return [
        {"id": 1, "name": "Transport"},
        {"id": 2, "name": "Vol 1-8"},
        {"id": 3, "name": "Vol 9-16"},
        {"id": 4, "name": "Pan 1-8"},
        {"id": 5, "name": "Pan 9-16"},
        {"id": 6, "name": "Part"},
        {"id": 7, "name": "Tone"},
        {"id": 8, "name": "Sends"},
        {"id": 9, "name": "FX"},
        {"id": 10, "name": "Sys Levels"},
        {"id": 11, "name": "Sys Mode"},
        {"id": 12, "name": "Sys Panic"},
    ]


def mix_grid(
    controls: list[dict],
    *,
    page: int,
    parts: range,
    cid_base: int,
    name_fmt: str,
    param: int,
    color: str,
    default: int,
    msg_type: str = "cc7",
) -> None:
    """2×4 grid of faders for 8 consecutive parts. pot 1–8 left→right top then bottom."""
    for i, part in enumerate(parts):
        col = i % 4
        row = i // 4
        pot_id = i + 1  # 1..8
        controls.append(
            fader(
                cid_base + part,
                name_fmt.format(part),
                page,
                col,
                row,
                device_id=part,
                param=param,
                color=color,
                pot_id=pot_id,
                default=default,
                msg_type=msg_type,
            )
        )


def build_controls() -> list[dict]:
    c: list[dict] = []
    D = 1

    # =====================================================================
    # Page 1 — Transport
    #   pot1 free / sections use touch
    #   pot2 = Song, pot3 = Pattern  (user request)
    #   PLAY / STOP = touch pads (no encoder)
    # =====================================================================
    # PLAY / STOP: native realtime + Lua so presses always emit FA / FC
    c.append(
        pad(
            1, "PLAY", 1,
            bounds=cell(0, 0, PAD_W, 80),
            device_id=D, color=C_PLAY,
            msg_type="cc7", param=LUA_CC + 30, function="onPlay",
            pot_id=11,
        )
    )
    c.append(
        pad(
            2, "STOP", 1,
            bounds=cell(1, 0, PAD_W, 80),
            device_id=D, color=C_STOP,
            msg_type="cc7", param=LUA_CC + 31, function="onStop",
            pot_id=12,
        )
    )
    # potId is 1-based; physical "encoder N" (0-based) == potId N+1
    # Song → encoder 2 → pot 3; Pattern → encoder 3 → pot 4
    c.append(
        list_ctrl(
            4, "Song", 1,
            bounds=cell(2, 0, LIST_W, LIST_H + 24),
            device_id=D, overlay_id=2, param=LUA_CC + 1,
            function="onSongSelect", min_v=0, max_v=19,
            color=C_WHT, pot_id=3,
        )
    )
    c.append(
        list_ctrl(
            5, "Pattern", 1,
            bounds=cell(3, 0, LIST_W, LIST_H + 24),
            device_id=D, overlay_id=3, param=LUA_CC + 2,
            function="onPatternSelect", min_v=0, max_v=63,
            color=C_DIM, pot_id=4,
        )
    )

    # Style sections — SysEx (with onValue) + Lua handlers
    # F0 43 7E 00 ss 7F F7  ·  ss: 08 Intro … 0E Blank
    sections = [
        (10, "INTRO", 0x08, "sectionIntro", 0, 1),
        (11, "MAIN A", 0x09, "sectionMainA", 1, 1),
        (12, "MAIN B", 0x0A, "sectionMainB", 2, 1),
        (13, "FILL AB", 0x0B, "sectionFillAB", 3, 1),
        (14, "FILL BA", 0x0C, "sectionFillBA", 0, 2),
        (15, "ENDING", 0x0D, "sectionEnding", 1, 2),
        (16, "BLANK", 0x0E, "sectionBlank", 2, 2),
    ]
    for cid, name, ss, fn, col, row in sections:
        c.append(
            pad(
                cid, name, 1,
                bounds=cell(col, row, PAD_W, 70),
                device_id=D, color=C_SEC,
                sysex=[0x43, 0x7E, 0x00, ss, 0x7F],
                function=fn,
            )
        )

    # Master vol on encoder 0 (pot 1) — left side of bottom row of pots
    c.append(
        fader(
            20, "Mst Vol", 1, 3, 2,
            device_id=D, param=LUA_CC + 3, color=C_SYS,
            pot_id=1, default=127, function="onMasterVolume",
        )
    )

    # =====================================================================
    # Pages 2–5 — Mix grids (2×4 = 8 parts, demo cell size)
    # =====================================================================
    mix_grid(c, page=2, parts=range(1, 9), cid_base=100,
             name_fmt="P{} Vol", param=7, color=C_MIX, default=100)
    mix_grid(c, page=3, parts=range(9, 17), cid_base=100,
             name_fmt="P{} Vol", param=7, color=C_MIX, default=100)
    mix_grid(c, page=4, parts=range(1, 9), cid_base=200,
             name_fmt="P{} Pan", param=10, color=C_PART, default=64)
    mix_grid(c, page=5, parts=range(9, 17), cid_base=200,
             name_fmt="P{} Pan", param=10, color=C_PART, default=64)

    # =====================================================================
    # Page 6 — Focused Part voice
    # =====================================================================
    c.append(list_ctrl(
        700, "Part", 6,
        bounds=cell(0, 0, LIST_W, LIST_H + 20),
        device_id=D, overlay_id=1, param=LUA_CC + 4,
        function="onPartSelect", min_v=0, max_v=15, color=C_PART, pot_id=1,
    ))
    c.append(list_ctrl(
        701, "Bank MSB", 6,
        bounds=cell(1, 0, LIST_W, LIST_H + 20),
        device_id=1, overlay_id=4, param=0,
        msg_type="cc7", min_v=0, max_v=127, color=C_PART, pot_id=2,
    ))
    c.append(fader(
        702, "Bank LSB", 6, 2, 0,
        device_id=1, param=32, color=C_PART, pot_id=3, default=0,
    ))
    c.append(list_ctrl(
        703, "Program", 6,
        bounds=cell(0, 1, LIST_WIDE_W, LIST_H + 20),
        device_id=1, overlay_id=6, param=0,
        msg_type="program", min_v=0, max_v=127, color=C_PART, pot_id=4,
    ))
    c.append(list_ctrl(
        730, "Drum Kit", 6,
        bounds=cell(2, 1, LIST_WIDE_W, LIST_H + 20),
        device_id=1, overlay_id=5, param=0,
        msg_type="program", min_v=0, max_v=127, color=C_SEC, pot_id=5,
    ))
    c.append(fader(704, "Volume", 6, 0, 2, device_id=1, param=7,
                   color=C_MIX, pot_id=6, default=100))
    c.append(fader(705, "Pan", 6, 1, 2, device_id=1, param=10,
                   color=C_MIX, pot_id=7, default=64))
    c.append(fader(706, "Express", 6, 2, 2, device_id=1, param=11,
                   color=C_MIX, pot_id=8, default=127))

    # =====================================================================
    # Page 7 — Tone
    # =====================================================================
    c.append(list_ctrl(
        740, "Part", 7,
        bounds=cell(0, 0, LIST_W, LIST_H + 20),
        device_id=D, overlay_id=1, param=LUA_CC + 5,
        function="onPartSelect", min_v=0, max_v=15, color=C_TONE, pot_id=1,
    ))
    tone_cc = [
        (710, "Harmonic", 71, 1, 0, 2, 64),
        (711, "Bright", 74, 2, 0, 3, 64),
        (712, "Attack", 73, 3, 0, 4, 64),
        (713, "Release", 72, 0, 1, 5, 64),
    ]
    for cid, name, cc, col, row, pot_id, default in tone_cc:
        c.append(fader(cid, name, 7, col, row, device_id=1, param=cc,
                       color=C_TONE, pot_id=pot_id, default=default))
    nrpns = [
        (714, "Vib Rate", (0x01 << 7) | 0x08, 1, 1, 6),
        (715, "VibDepth", (0x01 << 7) | 0x09, 2, 1, 7),
        (716, "Cutoff", (0x01 << 7) | 0x20, 3, 1, 8),
        (717, "Reso", (0x01 << 7) | 0x21, 0, 2, 9),
        (718, "EG Atk", (0x01 << 7) | 0x63, 1, 2, 10),
        (719, "EG Dec", (0x01 << 7) | 0x64, 2, 2, 11),
        (720, "EG Rel", (0x01 << 7) | 0x66, 3, 2, 12),
    ]
    for cid, name, pnum, col, row, pot_id in nrpns:
        c.append(fader(cid, name, 7, col, row, device_id=1, param=pnum,
                       color=C_TONE, pot_id=pot_id, default=64, msg_type="nrpn"))

    # =====================================================================
    # Page 8 — Sends
    # =====================================================================
    c.append(list_ctrl(
        750, "Part", 8,
        bounds=cell(0, 0, LIST_W, LIST_H + 20),
        device_id=D, overlay_id=1, param=LUA_CC + 6,
        function="onPartSelect", min_v=0, max_v=15, color=C_SEND, pot_id=1,
    ))
    c.append(fader(707, "Rev Send", 8, 1, 0, device_id=1, param=91,
                   color=C_SEND, pot_id=2, default=40))
    c.append(fader(708, "Cho Send", 8, 2, 0, device_id=1, param=93,
                   color=C_SEND, pot_id=3, default=0))
    c.append(fader(709, "Var Send", 8, 3, 0, device_id=1, param=94,
                   color=C_SEND, pot_id=4, default=0))
    for i, part in enumerate(range(1, 9)):
        col, row = i % 4, 1 + i // 4
        c.append(fader(
            800 + part, f"P{part} Rev", 8, col, row,
            device_id=part, param=91, color=C_DIM,
            pot_id=5 + i if i < 8 else None, default=40,
        ))

    # =====================================================================
    # Page 9 — FX (one family per row + routing on bottom-right)
    # =====================================================================
    c.append(list_ctrl(
        900, "Reverb", 9,
        bounds=cell(0, 0, LIST_W, LIST_H + 20),
        device_id=D, overlay_id=7, param=LUA_CC + 10,
        function="onReverbType", min_v=0, max_v=11, color=C_FX, pot_id=1,
    ))
    c.append(fader(901, "Rev Ret", 9, 1, 0, device_id=D, param=LUA_CC + 11,
                   color=C_FX, pot_id=2, default=64, function="onReverbReturn"))
    c.append(fader(902, "Rev Pan", 9, 2, 0, device_id=D, param=LUA_CC + 12,
                   color=C_FX, pot_id=3, default=64, function="onReverbPan"))
    c.append(list_ctrl(
        910, "Chorus", 9,
        bounds=cell(0, 1, LIST_W, LIST_H + 20),
        device_id=D, overlay_id=8, param=LUA_CC + 13,
        function="onChorusType", min_v=0, max_v=11, color=C_FX, pot_id=4,
    ))
    c.append(fader(911, "Cho Ret", 9, 1, 1, device_id=D, param=LUA_CC + 14,
                   color=C_FX, pot_id=5, default=64, function="onChorusReturn"))
    c.append(fader(912, "Cho Pan", 9, 2, 1, device_id=D, param=LUA_CC + 15,
                   color=C_FX, pot_id=6, default=64, function="onChorusPan"))
    c.append(fader(913, "Cho>Rev", 9, 3, 1, device_id=D, param=LUA_CC + 16,
                   color=C_FX, pot_id=7, default=0, function="onChorusToRev"))
    c.append(list_ctrl(
        920, "Variation", 9,
        bounds=cell(0, 2, LIST_W, LIST_H + 20),
        device_id=D, overlay_id=9, param=LUA_CC + 17,
        function="onVarType", min_v=0, max_v=16, color=C_FX, pot_id=8,
    ))
    c.append(fader(921, "Var Ret", 9, 1, 2, device_id=D, param=LUA_CC + 18,
                   color=C_FX, pot_id=9, default=64, function="onVarReturn"))
    c.append(fader(924, "Var>Rev", 9, 2, 2, device_id=D, param=LUA_CC + 21,
                   color=C_FX, pot_id=10, default=0, function="onVarToRev"))
    c.append(fader(925, "Var>Cho", 9, 3, 2, device_id=D, param=LUA_CC + 22,
                   color=C_FX, pot_id=11, default=0, function="onVarToCho"))

    # =====================================================================
    # Page 10 — Sys Levels  (ONLY master volume + transpose)
    # =====================================================================
    c.append(fader(
        1000, "Mst Vol", 10, 0, 0,
        device_id=D, param=LUA_CC + 3, color=C_SYS,
        pot_id=1, default=127, function="onMasterVolume",
    ))
    c.append(fader(
        1001, "Transpos", 10, 1, 0,
        device_id=D, param=LUA_CC + 23, color=C_SYS,
        pot_id=2, default=0, min_v=-24, max_v=24, function="onTranspose",
    ))

    # =====================================================================
    # Page 11 — Sys Mode  (ONLY XG / GM pads — no encoders, no other faders)
    # =====================================================================
    c.append(pad(
        1010, "XG ON", 11,
        bounds=cell(0, 0, 175, 122),
        device_id=D, color=C_PLAY,
        sysex=[0x43, 0x10, 0x4C, 0x00, 0x00, 0x7E, 0x00],
        function="onXgOn",
    ))
    c.append(pad(
        1011, "GM ON", 11,
        bounds=cell(1, 0, 175, 122),
        device_id=D, color=C_PLAY,
        sysex=[0x7E, 0x7F, 0x09, 0x01],
        function="onGmOn",
    ))

    # =====================================================================
    # Page 12 — Sys Panic  (ONLY four one-shot pads)
    # =====================================================================
    c.append(pad(
        1012, "SND OFF", 12,
        bounds=cell(0, 0, 175, 122),
        device_id=D, color=C_STOP,
        msg_type="cc7", param=120, function="onAllSoundOff",
    ))
    c.append(pad(
        1013, "NOTE OFF", 12,
        bounds=cell(1, 0, 175, 122),
        device_id=D, color=C_STOP,
        msg_type="cc7", param=123, function="onAllNotesOff",
    ))
    c.append(pad(
        1014, "RST CTRL", 12,
        bounds=cell(0, 1, 175, 122),
        device_id=D, color=C_SEC,
        msg_type="cc7", param=121, function="onResetControllers",
    ))
    c.append(pad(
        1015, "ALL RST", 12,
        bounds=cell(1, 1, 175, 122),
        device_id=D, color=C_STOP,
        sysex=[0x43, 0x10, 0x4C, 0x00, 0x00, 0x7F, 0x00],
        function="onAllParamReset",
    ))

    return c


def build_preset() -> dict:
    return {
        "version": 2,
        "name": "Yamaha QY100",
        "projectId": "yamaha-qy100",
        "pages": build_pages(),
        "devices": build_devices(),
        "overlays": build_overlays(),
        "controls": build_controls(),
    }


def build_eproj(lua: str) -> dict:
    tiles = []
    for ref, slot, typ, name, color in [
        (1, 1, "pad", "PLAY", C_PLAY),
        (2, 2, "pad", "STOP", C_STOP),
        (3, 3, "list", "Song", C_WHT),
        (4, 4, "list", "Pattern", C_DIM),
        (5, 5, "fader", "P1 Vol", C_MIX),
        (6, 6, "fader", "P2 Vol", C_MIX),
        (7, 7, "fader", "P3 Vol", C_MIX),
        (8, 8, "fader", "P4 Vol", C_MIX),
        (9, 9, "list", "Part", C_PART),
        (10, 10, "list", "Program", C_PART),
        (11, 11, "list", "Mode", C_PLAY),
        (12, 12, "list", "Panic", C_STOP),
    ]:
        msg = {
            "type": "start" if name == "PLAY" else "stop" if name == "STOP" else "cc7",
            "deviceId": 1,
            "parameterNumber": 0,
            "min": 0,
            "max": 127,
        }
        if name in ("PLAY", "STOP"):
            msg = {"type": name.lower() if name != "PLAY" else "start", "deviceId": 1}
            if name == "STOP":
                msg = {"type": "stop", "deviceId": 1}
        tiles.append({
            "id": uid(),
            "reference": ref,
            "slotId": slot,
            "type": typ,
            "deviceId": 1,
            "color": color,
            "name": name[:14],
            "categoryId": "control",
            "values": [{"message": msg}],
            "visible": True,
            "variant": "thin" if typ == "fader" else "",
            "mode": "momentary" if typ == "pad" else "",
        })
    return {
        "schemaVersion": 2,
        "id": "yamaha-qy100-eproj",
        "name": "YAMAHA QY100",
        "description": (
            "Electra One controller for Yamaha QY100.\n"
            "Device: presets/yamaha_qy100.json\n"
            "Lua: presets/yamaha_qy100.lua\n"
        ),
        "lua": lua.replace("\n", "\r\n"),
        "devices": [{
            "id": 1, "name": "Yamaha QY100",
            "instrumentId": "generic-controls", "port": 1, "channel": 1,
        }],
        "tiles": tiles,
        "pages": [{"id": 1, "name": "QY100 Overview"}],
        "categories": [],
        "firstPageId": 1,
    }


VALID_MSG = {
    "cc7", "cc14", "nrpn", "rpn", "SysEx", "note", "program",
    "start", "stop", "tune", "atpoly", "atchannel", "pitchbend", "spp",
}


def validate(preset: dict) -> None:
    assert "lua" not in preset
    assert preset["controls"]
    ids = [c["id"] for c in preset["controls"]]
    assert len(ids) == len(set(ids)), "duplicate control ids"

    by_page: dict[int, list] = {}
    for c in preset["controls"]:
        by_page.setdefault(c["pageId"], []).append(c)

    for page, ctrls in by_page.items():
        # Unique pot bindings per page (root cause of multi-control knobs)
        pot_owners: dict[int, str] = {}
        for a in ctrls:
            ax, ay, aw, ah = a["bounds"]
            assert ax + aw <= 1024, f"page {page} {a['name']} spills x"
            assert ay + ah <= 520, f"page {page} {a['name']} spills y ({ay+ah})"
            for inp in a.get("inputs") or []:
                pid = inp.get("potId")
                if pid is None:
                    continue
                assert pid not in pot_owners, (
                    f"page {page}: pot {pid} shared by "
                    f"{pot_owners[pid]!r} and {a['name']!r}"
                )
                pot_owners[pid] = a["name"]

        for i, a in enumerate(ctrls):
            ax, ay, aw, ah = a["bounds"]
            for b in ctrls[i + 1:]:
                bx, by, bw, bh = b["bounds"]
                ox = ax < bx + bw and bx < ax + aw
                oy = ay < by + bh and by < ay + ah
                assert not (ox and oy), (
                    f"overlap page {page}: {a['name']}{a['bounds']} vs "
                    f"{b['name']}{b['bounds']}"
                )

    for c in preset["controls"]:
        for v in c["values"]:
            m = v["message"]
            assert m["type"] in VALID_MSG, m["type"]
    print(
        f"validate OK: {len(preset['controls'])} controls, "
        f"{len(preset['pages'])} pages, unique pots, no overlaps"
    )


def main() -> None:
    lua = LUA_PATH.read_text(encoding="utf-8")
    preset = build_preset()
    validate(preset)
    eproj = build_eproj(lua)

    out_preset = ROOT / "presets" / "yamaha_qy100.json"
    out_eproj = ROOT / "projects" / "yamaha_qy100.eproj"
    out_lua = ROOT / "presets" / "yamaha_qy100.lua"
    out_preset.write_text(json.dumps(preset, indent=2) + "\n", encoding="utf-8")
    out_eproj.write_text(json.dumps(eproj, indent=2) + "\n", encoding="utf-8")
    out_lua.write_text(lua, encoding="utf-8")
    print(f"Wrote {out_preset.relative_to(ROOT)}")
    print(f"Wrote {out_eproj.relative_to(ROOT)}")
    print(f"Wrote {out_lua.relative_to(ROOT)}")
    print("Pages:", [p["name"] for p in preset["pages"]])


if __name__ == "__main__":
    main()
