#!/usr/bin/env python3
"""Electra One Mini preset for Electro-Harmonix 95000 Performance Loop Laboratory.

MIDI map from EHX 95000 User Reference Manual v1.0 (pp.35–37):
  Continuous CCs go out as JSON cc7.
  Buttons / footswitches go out as Program Change via Lua (PC 100–127).
  Loop select: CC115 0–99 (or PC 0–99).

Mini routing: Port 1 + MIDI_IO (single TRS pair). Soft keys 2–5 = potIds 9–12.
"""

from __future__ import annotations

import json
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LUA_PATH = Path(__file__).resolve().parent / "lua" / "ehx95000.lua"

ORIGIN_X, ORIGIN_Y = 20, 20
CELL_W, CELL_H = 196, 100
CTRL_W, CTRL_H = 175, 80
PAD_W, PAD_H = 175, 72
LIST_W = 175

BTN_Y = 230
BTN_W, BTN_H = 150, 52
BTN_GAP = 158
BTN_ORIGIN_X = 20

C_REC = "F97316"
C_PLAY = "22C55E"
C_UNDO = "A78BFA"
C_TRK = "3B82F6"
C_STOP = "EF4444"
C_DIM = "94A3B8"
C_MIX = "F59E0B"
C_WHT = "FFFFFF"
C_FX = "EC4899"
C_LOOP = "06B6D4"

_next_carrier = 40


def next_carrier() -> int:
    global _next_carrier
    if _next_carrier > 119:
        raise RuntimeError(f"pad carrier overflow at {_next_carrier}")
    c = _next_carrier
    _next_carrier += 1
    return c


def uid() -> str:
    return str(uuid.uuid4())


def cell(col: int, row: int, w: int = CTRL_W, h: int = CTRL_H) -> list[int]:
    return [ORIGIN_X + col * CELL_W, ORIGIN_Y + row * CELL_H, w, h]


def pot(n: int) -> list[dict]:
    assert 1 <= n <= 12, n
    return [{"potId": n, "valueId": "value"}]


def fader(
    cid: int,
    name: str,
    page: int,
    col: int,
    row: int,
    *,
    param: int,
    color: str,
    pot_id: int | None = None,
    default: int = 100,
    min_v: int = 0,
    max_v: int = 127,
    msg_type: str = "cc7",
    function: str | None = None,
) -> dict:
    value: dict = {
        "id": "value",
        "min": min_v,
        "max": max_v,
        "defaultValue": default,
        "message": {
            "deviceId": 1,
            "type": msg_type,
            "parameterNumber": param,
            "min": min_v,
            "max": max_v,
        },
    }
    if function is not None:
        value["function"] = function
    ctrl: dict = {
        "id": cid,
        "type": "fader",
        "visible": True,
        "variant": "thin",
        "name": name[:14],
        "color": color,
        "bounds": cell(col, row),
        "pageId": page,
        "controlSetId": 1,
        "values": [value],
    }
    if pot_id is not None:
        ctrl["inputs"] = pot(pot_id)
    return ctrl


def action_pad(
    cid: int,
    name: str,
    page: int,
    col: int,
    row: int,
    *,
    color: str,
    function: str,
    pot_id: int | None = None,
    bounds: list[int] | None = None,
    w: int = PAD_W,
    h: int = PAD_H,
) -> dict:
    carrier = next_carrier()
    ctrl: dict = {
        "id": cid,
        "type": "pad",
        "mode": "momentary",
        "visible": True,
        # Pads are wide enough for longer labels (e.g. "Start MIDI Clock").
        "name": name[:20],
        "color": color,
        "bounds": bounds if bounds is not None else cell(col, row, w, h),
        "pageId": page,
        "controlSetId": 1,
        "values": [{
            "id": "value",
            "defaultValue": "off",
            "function": function,
            "message": {
                "deviceId": 1,
                "type": "cc7",
                "parameterNumber": carrier,
                "onValue": 127,
            },
        }],
    }
    if pot_id is not None:
        ctrl["inputs"] = pot(pot_id)
    return ctrl


def list_ctrl(
    cid: int,
    name: str,
    page: int,
    col: int,
    row: int,
    *,
    overlay_id: int,
    min_v: int = 0,
    max_v: int = 99,
    color: str = C_WHT,
    pot_id: int | None = None,
    w: int = LIST_W,
    h: int = 76,
    function: str = "onLoopSelect",
) -> dict:
    # Dummy carrier + Lua: LOOP UP/DN work via Program Change, so direct
    # select also sends PC 0-99 (and CC115) from onLoopSelect. Pure JSON
    # CC115 alone did not load loops on the unit under test.
    carrier = next_carrier()
    val: dict = {
        "id": "value",
        "min": min_v,
        "max": max_v,
        "defaultValue": 0,
        "overlayId": overlay_id,
        "function": function,
        "message": {
            "deviceId": 1,
            "type": "cc7",
            "parameterNumber": carrier,
            "min": min_v,
            "max": max_v,
        },
    }
    ctrl: dict = {
        "id": cid,
        "type": "list",
        "visible": True,
        "variant": "valueOnly",
        "name": name[:14],
        "color": color,
        "bounds": cell(col, row, w, h),
        "pageId": page,
        "controlSetId": 1,
        "values": [val],
    }
    if pot_id is not None:
        ctrl["inputs"] = pot(pot_id)
    return ctrl


def overlay(oid: int, items: list[tuple[int, str]]) -> dict:
    return {"id": oid, "items": [{"value": v, "label": lab[:20]} for v, lab in items]}


def build_overlays() -> list[dict]:
    loops = [(i, f"L{i:02d}") for i in range(100)]
    return [overlay(1, loops)]


def build_pages() -> list[dict]:
    return [
        {"id": 1, "name": "Mixer"},
        {"id": 2, "name": "Transport"},
        {"id": 3, "name": "Tracks"},
        {"id": 4, "name": "Loop"},
        {"id": 5, "name": "Modes"},
    ]


def build_devices() -> list[dict]:
    # Mini TRS = MIDI IO 1 = Port 1. Channel 1 (set 95000 to ch1 or OMNI).
    return [{
        "id": 1,
        "name": "EHX 95000",
        "port": 1,
        "channel": 1,
        "rate": 15,
    }]


def soft_button_pads(c: list[dict], page: int, id_base: int) -> None:
    """Soft keys 2–5 via potIds 9–12 (Mini factory alias)."""
    specs = [
        (0, "PLAY/STOP", "onPlayStop", C_PLAY, 9),
        (1, "RECORD", "onRecord", C_REC, 10),
        (2, "UNDO", "onUndo", C_UNDO, 11),
        (3, "TAP", "onTap", C_DIM, 12),
    ]
    for col, name, fn, color, pot_id in specs:
        c.append(action_pad(
            id_base + col, name, page, col, 0,
            color=color, function=fn, pot_id=pot_id,
            bounds=[BTN_ORIGIN_X + col * BTN_GAP, BTN_Y, BTN_W, BTN_H],
            w=BTN_W, h=BTN_H,
        ))


def build_controls() -> list[dict]:
    global _next_carrier
    _next_carrier = 40
    c: list[dict] = []

    # Soft keys on every page
    for page, base in ((1, 100), (2, 200), (3, 300), (4, 400), (5, 500)):
        soft_button_pads(c, page=page, id_base=base)

    # ----- Page 1: Mixer — track volumes (pots 1–6) + soft keys -----
    # T1 T2 T3 T4
    # T5 T6
    for i in range(4):
        c.append(fader(
            1 + i, f"TRK {i + 1}", 1, i, 0,
            param=20 + i, color=C_TRK, pot_id=1 + i, default=100,
        ))
    c.append(fader(5, "TRK 5", 1, 0, 1, param=24, color=C_TRK, pot_id=5, default=100))
    c.append(fader(6, "TRK 6", 1, 1, 1, param=25, color=C_TRK, pot_id=6, default=100))

    # ----- Page 2: Transport (pots 1–6) -----
    # PLAY | RECORD | UNDO | TRACK
    # LOOP DN | LOOP UP
    c.append(action_pad(20, "PLAY/STOP", 2, 0, 0, color=C_PLAY, function="onPlayStop", pot_id=1))
    c.append(action_pad(21, "RECORD", 2, 1, 0, color=C_REC, function="onRecord", pot_id=2))
    c.append(action_pad(22, "UNDO", 2, 2, 0, color=C_UNDO, function="onUndo", pot_id=3))
    c.append(action_pad(23, "TRACK FSW", 2, 3, 0, color=C_TRK, function="onTrackFsw", pot_id=4))
    c.append(action_pad(24, "LOOP DN", 2, 0, 1, color=C_LOOP, function="onLoopDown", pot_id=5))
    c.append(action_pad(25, "LOOP UP", 2, 1, 1, color=C_LOOP, function="onLoopUp", pot_id=6))

    # ----- Page 3: Track select + mute -----
    # T1 T2 T3 T4
    # T5 T6 MIX MUTE-M
    c.append(action_pad(30, "TRK 1", 3, 0, 0, color=C_TRK, function="onTrack1", pot_id=1))
    c.append(action_pad(31, "TRK 2", 3, 1, 0, color=C_TRK, function="onTrack2", pot_id=2))
    c.append(action_pad(32, "TRK 3", 3, 2, 0, color=C_TRK, function="onTrack3", pot_id=3))
    c.append(action_pad(33, "TRK 4", 3, 3, 0, color=C_TRK, function="onTrack4", pot_id=4))
    c.append(action_pad(34, "TRK 5", 3, 0, 1, color=C_TRK, function="onTrack5", pot_id=5))
    c.append(action_pad(35, "TRK 6", 3, 1, 1, color=C_TRK, function="onTrack6", pot_id=6))
    # touch-only extras under soft-key row would overflow Mini height;
    # MIXDOWN select & mute live on Modes / Loop pages

    # ----- Page 4: Loop + master mix -----
    # LOOP list (wide) | MIX VOL | MASTER
    # NEW LOOP | MIXDOWN | REVERSE | OCT
    c.append(list_ctrl(
        40, "LOOP", 4, 0, 0,
        overlay_id=1,
        color=C_LOOP, pot_id=1,
        # Span two columns without overlapping col-2 MIX VOL
        w=CELL_W + CTRL_W,
    ))
    c.append(fader(41, "MIX VOL", 4, 2, 0, param=26, color=C_MIX, pot_id=2, default=100))
    c.append(fader(42, "MASTER", 4, 3, 0, param=7, color=C_WHT, pot_id=3, default=100))
    c.append(action_pad(43, "NEW LOOP", 4, 0, 1, color=C_REC, function="onNewLoop", pot_id=4))
    c.append(action_pad(44, "MIXDOWN", 4, 1, 1, color=C_MIX, function="onMixdownBtn", pot_id=5))
    c.append(action_pad(45, "REVERSE", 4, 2, 1, color=C_FX, function="onReverse", pot_id=6))
    # OCT on Modes page (pot budget full)

    # ----- Page 5: Modes / FX + MIDI clock master -----
    # OCT | PUNCH | QUANTIZE | EXT CLK
    # TEMPO (BPM) | CLK RUN
    # EXT CLOCK (PC 127) puts the 95000 in XT/BX slave mode.
    # TEMPO dials the Electra master BPM; CLK RUN starts/stops 24-PPQN
    # MIDI Clock + Start/Stop out the Mini TRS jack.
    # TAP stays on soft key 5 (pot 12); PAGE remains in Lua if reassigned.
    c.append(action_pad(50, "OCT", 5, 0, 0, color=C_FX, function="onOct", pot_id=1))
    c.append(action_pad(51, "PUNCH", 5, 1, 0, color=C_REC, function="onPunch", pot_id=2))
    c.append(action_pad(52, "QUANTIZE", 5, 2, 0, color=C_LOOP, function="onQuantize", pot_id=3))
    # EXT CLOCK is 3-state on hardware (IN / XT / BX); Lua renames + recolors.
    c.append(action_pad(53, "EXT IN", 5, 3, 0, color=C_DIM, function="onExtClock", pot_id=4))
    c.append(fader(
        54, "TEMPO", 5, 0, 1,
        param=next_carrier(), color=C_MIX, pot_id=5,
        default=120, min_v=40, max_v=240,
        msg_type="virtual", function="onTempo",
    ))
    # Labels swap at runtime via Lua setName (Start / Stop MIDI Clock).
    c.append(action_pad(
        55, "Start MIDI Clock", 5, 1, 1,
        color=C_PLAY, function="onClockRun", pot_id=6,
    ))

    return c


def build_preset() -> dict:
    return {
        "version": 2,
        "name": "EHX 95000",
        "projectId": "ehx-95000",
        "pages": build_pages(),
        "devices": build_devices(),
        "overlays": build_overlays(),
        "controls": build_controls(),
    }


def build_eproj(lua: str) -> dict:
    tiles = []
    for ref, slot, typ, name, color, param in [
        (1, 1, "fader", "TRK 1", C_TRK, 20),
        (2, 2, "fader", "TRK 2", C_TRK, 21),
        (3, 3, "fader", "TRK 3", C_TRK, 22),
        (4, 4, "fader", "TRK 4", C_TRK, 23),
        (5, 5, "pad", "PLAY", C_PLAY, 80),
        (6, 6, "pad", "RECORD", C_REC, 81),
        (7, 7, "pad", "UNDO", C_UNDO, 82),
        (8, 8, "pad", "TAP", C_DIM, 83),
        (9, 9, "list", "LOOP", C_LOOP, 115),
        (10, 10, "fader", "MIX", C_MIX, 26),
        (11, 11, "fader", "MASTER", C_WHT, 7),
        (12, 12, "pad", "NEW LOOP", C_REC, 84),
    ]:
        if typ == "pad":
            msg = {
                "type": "cc7", "deviceId": 1,
                "parameterNumber": param, "onValue": 127, "min": 0, "max": 127,
            }
        elif typ == "list":
            msg = {
                "type": "cc7", "deviceId": 1,
                "parameterNumber": 115, "min": 0, "max": 99,
            }
        else:
            msg = {
                "type": "cc7", "deviceId": 1,
                "parameterNumber": param, "min": 0, "max": 127,
            }
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
        "id": "ehx-95000-eproj",
        "name": "EHX 95000",
        "description": "Electra One Mini controller for EHX 95000 looper (Lua PC buttons + CC mix).",
        "lua": lua.replace("\n", "\r\n"),
        "devices": [{
            "id": 1, "name": "EHX 95000",
            "instrumentId": "generic-controls", "port": 1, "channel": 1,
        }],
        "tiles": tiles,
        "pages": [{"id": 1, "name": "95000"}],
        "categories": [],
        "firstPageId": 1,
    }


VALID_MSG = {
    "cc7", "cc14", "nrpn", "rpn", "SysEx", "note", "program",
    "start", "stop", "tune", "atpoly", "atchannel", "pitchbend", "spp",
}


def validate(preset: dict) -> None:
    assert "lua" not in preset
    ids = [c["id"] for c in preset["controls"]]
    assert len(ids) == len(set(ids))

    VALID = VALID_MSG | {"virtual"}
    pad_carriers: dict[tuple, str] = {}
    by_page: dict[int, list] = {}
    for c in preset["controls"]:
        by_page.setdefault(c["pageId"], []).append(c)
        for v in c["values"]:
            m = v["message"]
            assert m["type"] in VALID, m["type"]
            if c["type"] == "pad":
                assert "function" in v, f"pad {c['name']} missing Lua function"
                assert m.get("onValue") not in (None, 0), c["name"]
                key = (m["deviceId"], m["type"], m.get("parameterNumber"))
                if key in pad_carriers:
                    raise AssertionError(
                        f"pad carrier clash {key}: {pad_carriers[key]!r} and {c['name']!r}"
                    )
                pad_carriers[key] = c["name"]

    for page, ctrls in by_page.items():
        soft_pots = {
            (a.get("inputs") or [{}])[0].get("potId")
            for a in ctrls
            if (a.get("inputs") or [{}])[0].get("potId") in (9, 10, 11, 12)
        }
        assert soft_pots == {9, 10, 11, 12}, (
            f"page {page} missing soft-key pots 9–12 (have {sorted(p for p in soft_pots if p)})"
        )

    for page, ctrls in by_page.items():
        pot_owners: dict[int, str] = {}
        for a in ctrls:
            ax, ay, aw, ah = a["bounds"]
            assert ax + aw <= 1024, f"spill x {a['name']}"
            assert ay + ah <= 560, f"spill y {a['name']}"
            for inp in a.get("inputs") or []:
                if "potId" in inp:
                    pid = inp["potId"]
                    assert 1 <= pid <= 12
                    assert pid not in pot_owners, (
                        f"page {page} pot {pid}: {pot_owners[pid]} vs {a['name']}"
                    )
                    pot_owners[pid] = a["name"]
        for i, a in enumerate(ctrls):
            ax, ay, aw, ah = a["bounds"]
            for b in ctrls[i + 1:]:
                bx, by, bw, bh = b["bounds"]
                if ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah:
                    raise AssertionError(f"overlap {a['name']} vs {b['name']}")

    print(
        f"validate OK: {len(preset['controls'])} controls, "
        f"{len(preset['pages'])} pages, unique pots/buttons"
    )


def main() -> None:
    lua = LUA_PATH.read_text(encoding="utf-8")
    preset = build_preset()
    validate(preset)
    eproj = build_eproj(lua)

    (ROOT / "presets" / "ehx_95000.json").write_text(
        json.dumps(preset, indent=2) + "\n", encoding="utf-8"
    )
    (ROOT / "presets" / "ehx_95000.lua").write_text(lua, encoding="utf-8")
    (ROOT / "projects" / "ehx_95000.eproj").write_text(
        json.dumps(eproj, indent=2) + "\n", encoding="utf-8"
    )
    print("Wrote presets/ehx_95000.json + .lua + eproj")
    print("Pages:", [p["name"] for p in preset["pages"]])


if __name__ == "__main__":
    main()
