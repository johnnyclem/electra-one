#!/usr/bin/env python3
"""Electra One Mini preset for Valeton VLP-200.

Button/toggle strategy
----------------------
Pads do NOT share CC#1 in the JSON (parameterMap would merge them and break
actions). Each pad uses a unique dummy carrier CC + onValue 127, and a Lua
function that pulses the real CC#1 action (or CC5/6 for project step).

Volumes stay as normal continuous CC faders (those already work).

Mini constraints: pots 1–6 only, bounds inside 480×320, unique pots per page.
"""

from __future__ import annotations

import json
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LUA_PATH = Path(__file__).resolve().parent / "lua" / "vlp200.lua"

# Electra One front-panel layout (also works on Mini when pots exist):
#   pots 1–4  = top encoder row
#   pots 5–8  = bottom encoder row
#   pots 9–12 = third row (unused on Loop Pads)
#   soft buttons 0–5 under the encoders (0–1 reserved by system)
#
# Use the factory 4-column cell size so two rows of four line up with
# the physical encoders.
ORIGIN_X, ORIGIN_Y = 20, 20
CELL_W, CELL_H = 196, 100
CTRL_W, CTRL_H = 175, 80
PAD_W, PAD_H = 175, 72
LIST_W = 175
# Soft-button strip under the 2 encoder rows (fits Mini ~320px height).
# Mini soft keys 3–6 mirror these pot-less pads (Martin pattern).
BTN_Y = 230
BTN_W, BTN_H = 150, 52
BTN_GAP = 158
BTN_ORIGIN_X = 20

C_L1 = "22C55E"
C_L2 = "3B82F6"
C_DRUM = "F59E0B"
C_STOP = "EF4444"
C_PROJ = "A78BFA"
C_WHT = "FFFFFF"
C_DIM = "94A3B8"
C_REC = "F97316"

# Dummy carrier CCs for pads (must be unique across the whole preset;
# real action MIDI is sent from Lua). Stay in 40–119 but never wrap.
_next_carrier = 40


def next_carrier() -> int:
    global _next_carrier
    if _next_carrier > 119:
        raise RuntimeError(f"pad carrier overflow at {_next_carrier} (max 119)")
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
) -> dict:
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
        "values": [{
            "id": "value",
            "min": 0,
            "max": 127,
            "defaultValue": default,
            "message": {
                "deviceId": 1,
                "type": "cc7",
                "parameterNumber": param,
                "min": 0,
                "max": 127,
            },
        }],
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
    soft_button: bool = False,
) -> dict:
    """Momentary pad → unique carrier CC + Lua handler.

    Matches working widget / Martin Mini soft-button pattern:
      onValue=127, no offValue (release ignored), function=...

    Electra Mini soft buttons (hw 2–5) are NOT assigned via `buttonId`
    (unsupported in the preset schema). Mini maps free soft buttons to
    potIds 9–12 (factory alias — Mini has only 8 physical encoders).
    """
    carrier = next_carrier()
    val: dict = {
        "id": "value",
        "defaultValue": "off",
        "function": function,
        "message": {
            "deviceId": 1,
            # unique carrier so parameterMap never merges pads
            "type": "cc7",
            "parameterNumber": carrier,
            "onValue": 127,
            # deliberately no offValue → press only
        },
    }
    ctrl: dict = {
        "id": cid,
        "type": "pad",
        "mode": "momentary",
        "visible": True,
        "name": name[:14],
        "color": color,
        "bounds": bounds if bounds is not None else cell(col, row, w, h),
        "pageId": page,
        "controlSetId": 1,
        "values": [val],
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
    function: str,
    min_v: int = 0,
    max_v: int = 98,
    color: str = C_WHT,
    pot_id: int | None = None,
    w: int = LIST_W,
    h: int = 76,
) -> dict:
    val: dict = {
        "id": "value",
        "min": min_v,
        "max": max_v,
        "defaultValue": 0,
        "overlayId": overlay_id,
        "function": function,
        "message": {
            "deviceId": 1,
            "type": "program",
            "parameterNumber": 0,
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
    projects = [(i, f"P{i + 1:02d}") for i in range(99)]
    return [overlay(1, projects)]


def build_pages() -> list[dict]:
    return [
        {"id": 1, "name": "Loops"},
        {"id": 2, "name": "Loop Pads"},
        {"id": 3, "name": "Drums"},
        {"id": 4, "name": "Project"},
        {"id": 5, "name": "Transport"},
    ]


def build_devices() -> list[dict]:
    # Electra Mini has one TRS MIDI pair = MIDI IO 1 = logical Port 1.
    # Port 2 only bridges USB Host/Device 2 — no physical MIDI IO 2 on Mini.
    # Volumes (JSON) and pads (Lua → MIDI_IO interface) both use this device.
    return [{
        "id": 1,
        "name": "VLP-200",
        "port": 1,
        "channel": 1,
        "rate": 10,
    }]


def soft_button_pads(c: list[dict], page: int, id_base: int) -> None:
    """Soft-key pads for Mini hw buttons 2–5 via potIds 9–12.

    Electra Mini has 8 physical encoders (pots 1–8). Pots 9–12 are the
    factory alias for the four free soft buttons under the display
    (buttons 0–1 stay reserved for system page/control-set nav).

    Order left→right MUST match hardware soft keys:
      pot9 / btn2 → L1 STACK
      pot10 / btn3 → ALL PLAY
      pot11 / btn4 → ALL STOP
      pot12 / btn5 → TAP

    Same four pads on every page so soft keys stay live after page changes.
    Use the proven action_pad carrier (unique cc7 + Lua), not pot-less virtual
    pads — those only fire when touched, not when a soft key is pressed.
    """
    specs = [
        (0, "L1 STACK", "onL1Stack", C_DIM, 9),
        (1, "ALL PLAY", "onAllPlay", C_L1, 10),
        (2, "ALL STOP", "onAllStop", C_STOP, 11),
        (3, "TAP", "onTapTempo", C_DIM, 12),
    ]
    for col, name, fn, color, pot_id in specs:
        c.append(action_pad(
            id_base + col,
            name,
            page,
            col,
            0,
            color=color,
            function=fn,
            pot_id=pot_id,
            bounds=[BTN_ORIGIN_X + col * BTN_GAP, BTN_Y, BTN_W, BTN_H],
            w=BTN_W,
            h=BTN_H,
        ))


def build_controls() -> list[dict]:
    global _next_carrier
    _next_carrier = 40
    c: list[dict] = []

    # Soft-key pads (pot 9–12 → Mini soft buttons 2–5). Cloned onto every
    # page so the four free soft keys stay live after page changes.
    soft_button_pads(c, page=1, id_base=100)
    soft_button_pads(c, page=2, id_base=200)
    soft_button_pads(c, page=3, id_base=300)
    soft_button_pads(c, page=4, id_base=400)
    soft_button_pads(c, page=5, id_base=500)

    # ----- Page 1: Volumes + quick actions (4-encoder rows) -----
    #   LOOP 1 | LOOP 2 | DRUM | STOP ALL   (pots 1–4)
    #   DRUM TOG | TAP TMP |        |       (pots 5–6)
    c.append(fader(1, "LOOP 1", 1, 0, 0, param=2, color=C_L1, pot_id=1, default=100))
    c.append(fader(2, "LOOP 2", 1, 1, 0, param=3, color=C_L2, pot_id=2, default=100))
    c.append(fader(3, "DRUM", 1, 2, 0, param=4, color=C_DRUM, pot_id=3, default=90))
    c.append(action_pad(10, "STOP ALL", 1, 3, 0, color=C_STOP, function="onPlayStopAll", pot_id=4))
    c.append(action_pad(11, "DRUM TOG", 1, 0, 1, color=C_DRUM, function="onDrumToggle", pot_id=5))
    c.append(action_pad(12, "TAP TMP", 1, 1, 1, color=C_DIM, function="onTapTempo", pot_id=6))

    # ----- Page 2: Loop Pads — 2×4 encoders (pots 1–8) -----
    #   pot1 L1 REC   pot2 L1 PLAY   pot3 L1 UNDO   pot4 L2 REC
    #   pot5 L2 PLAY  pot6 L2 UNDO   pot7 L1 ONCE   pot8 L2 ONCE
    # Soft keys (bottom strip, all pages): L1 STACK · ALL PLAY · ALL STOP · TAP
    c.append(action_pad(20, "L1 REC", 2, 0, 0, color=C_REC, function="onL1Rec", pot_id=1))
    c.append(action_pad(21, "L1 PLAY", 2, 1, 0, color=C_L1, function="onL1Play", pot_id=2))
    c.append(action_pad(22, "L1 UNDO", 2, 2, 0, color=C_DIM, function="onL1Undo", pot_id=3))
    c.append(action_pad(23, "L2 REC", 2, 3, 0, color=C_REC, function="onL2Rec", pot_id=4))
    c.append(action_pad(24, "L2 PLAY", 2, 0, 1, color=C_L2, function="onL2Play", pot_id=5))
    c.append(action_pad(25, "L2 UNDO", 2, 1, 1, color=C_DIM, function="onL2Undo", pot_id=6))
    c.append(action_pad(26, "L1 ONCE", 2, 2, 1, color=C_L1, function="onL1Once", pot_id=7))
    c.append(action_pad(27, "L2 ONCE", 2, 3, 1, color=C_L2, function="onL2Once", pot_id=8))

    # ----- Page 3: Drums (4-wide top row) -----
    #   DRUM VOL | DRUM TOG | TAP TMP | STOP ALL  (pots 1–4)
    c.append(fader(30, "DRUM VOL", 3, 0, 0, param=4, color=C_DRUM, pot_id=1, default=90))
    c.append(action_pad(31, "DRUM TOG", 3, 1, 0, color=C_DRUM, function="onDrumToggle", pot_id=2))
    c.append(action_pad(32, "TAP TMP", 3, 2, 0, color=C_DIM, function="onTapTempo", pot_id=3))
    c.append(action_pad(33, "STOP ALL", 3, 3, 0, color=C_STOP, function="onPlayStopAll", pot_id=4))

    # ----- Page 4: Project -----
    c.append(list_ctrl(
        40, "Project", 4, 0, 0,
        overlay_id=1, function="onProjectSelect",
        color=C_PROJ, pot_id=1,
        w=CELL_W * 2 + (CELL_W - CTRL_W),
    ))
    c.append(action_pad(41, "PROJ UP", 4, 0, 1, color=C_PROJ, function="onProjectUp", pot_id=2))
    c.append(action_pad(42, "PROJ DN", 4, 1, 1, color=C_PROJ, function="onProjectDown", pot_id=3))

    # ----- Page 5: Transport — align to 4-encoder rows -----
    # Top row (pots 1–4): fill all four before wrapping
    # Bottom row (pots 5–6): remaining two, left-aligned
    #   STOP ALL | L1 PLAY | L2 PLAY | DRUM TOG
    #   L1 REC   | L2 REC  |         |
    c.append(action_pad(50, "STOP ALL", 5, 0, 0, color=C_STOP, function="onPlayStopAll", pot_id=1))
    c.append(action_pad(51, "L1 PLAY", 5, 1, 0, color=C_L1, function="onL1Play", pot_id=2))
    c.append(action_pad(52, "L2 PLAY", 5, 2, 0, color=C_L2, function="onL2Play", pot_id=3))
    c.append(action_pad(53, "DRUM TOG", 5, 3, 0, color=C_DRUM, function="onDrumToggle", pot_id=4))
    c.append(action_pad(54, "L1 REC", 5, 0, 1, color=C_REC, function="onL1Rec", pot_id=5))
    c.append(action_pad(55, "L2 REC", 5, 1, 1, color=C_REC, function="onL2Rec", pot_id=6))

    return c


def build_preset() -> dict:
    return {
        "version": 2,
        "name": "Valeton VLP-200",
        "projectId": "valeton-vlp200",
        "pages": build_pages(),
        "devices": build_devices(),
        "overlays": build_overlays(),
        "controls": build_controls(),
    }


def build_eproj(lua: str) -> dict:
    tiles = []
    for ref, slot, typ, name, color in [
        (1, 1, "fader", "LOOP 1", C_L1),
        (2, 2, "fader", "LOOP 2", C_L2),
        (3, 3, "fader", "DRUM", C_DRUM),
        (4, 4, "pad", "STOP ALL", C_STOP),
        (5, 5, "pad", "L1 REC", C_REC),
        (6, 6, "pad", "L1 PLAY", C_L1),
        (7, 7, "pad", "L2 REC", C_REC),
        (8, 8, "pad", "L2 PLAY", C_L2),
        (9, 9, "list", "Project", C_PROJ),
        (10, 10, "pad", "DRUM", C_DRUM),
        (11, 11, "pad", "TAP", C_DIM),
        (12, 12, "pad", "L1 UNDO", C_DIM),
    ]:
        if typ == "pad":
            msg = {
                "type": "cc7", "deviceId": 1,
                "parameterNumber": 80 + ref, "onValue": 127, "min": 0, "max": 127,
            }
        elif typ == "list":
            msg = {"type": "program", "deviceId": 1, "parameterNumber": 0, "min": 0, "max": 98}
        else:
            msg = {"type": "cc7", "deviceId": 1, "parameterNumber": ref + 1, "min": 0, "max": 127}
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
        "id": "valeton-vlp200-eproj",
        "name": "VALETON VLP-200",
        "description": "Electra One Mini controller for Valeton VLP-200 (Lua action pads).",
        "lua": lua.replace("\n", "\r\n"),
        "devices": [{
            "id": 1, "name": "VLP-200",
            "instrumentId": "generic-controls", "port": 1, "channel": 1,
        }],
        "tiles": tiles,
        "pages": [{"id": 1, "name": "VLP-200"}],
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

    # Pad carriers must be unique (parameterMap merge breaks multi-action pads).
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
                assert m.get("onValue") not in (None, 0), (
                    f"pad {c['name']} onValue must be non-zero (got {m.get('onValue')})"
                )
                key = (m["deviceId"], m["type"], m.get("parameterNumber"))
                if key in pad_carriers:
                    raise AssertionError(
                        f"pad carrier clash {key}: {pad_carriers[key]!r} and {c['name']!r}"
                    )
                pad_carriers[key] = c["name"]

    # Soft keys: every page must expose pots 9–12 (Mini soft buttons 2–5).
    for page, ctrls in by_page.items():
        soft_pots = {
            (a.get("inputs") or [{}])[0].get("potId")
            for a in ctrls
            if (a.get("inputs") or [{}])[0].get("potId") in (9, 10, 11, 12)
        }
        assert soft_pots == {9, 10, 11, 12}, (
            f"page {page} missing soft-key pots 9–12 (have {sorted(soft_pots)})"
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

    (ROOT / "presets" / "valeton_vlp200.json").write_text(
        json.dumps(preset, indent=2) + "\n", encoding="utf-8"
    )
    (ROOT / "presets" / "valeton_vlp200.lua").write_text(lua, encoding="utf-8")
    (ROOT / "projects" / "valeton_vlp200.eproj").write_text(
        json.dumps(eproj, indent=2) + "\n", encoding="utf-8"
    )
    print("Wrote presets/valeton_vlp200.json + .lua + eproj")
    print("Pages:", [p["name"] for p in preset["pages"]])


if __name__ == "__main__":
    main()
