#!/usr/bin/env bash
# Push EHX 95000 preset + Lua to Electra One, then switch to the slot.
#
# Usage:
#   ./projects/ehx_95000/push.sh
#   ./projects/ehx_95000/push.sh -b 0 -s 3
#
# Defaults: bank 0, slot 3 (slot 2 is the VLP-200 preset)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
JSON="$ROOT/presets/ehx_95000.json"
LUA="$ROOT/presets/ehx_95000.lua"
E1=(node "$ROOT/bin/e1.js")

BANK=0
SLOT=3

usage() {
  cat <<EOF
Usage: $(basename "$0") [-b|--bank N] [-s|--slot N]

  Push ehx_95000.json, then ehx_95000.lua, then switch to that slot.

Options:
  -b, --bank N   Target bank (default: 0)
  -s, --slot N   Target slot (default: 3)
  -h, --help     Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--bank)
      [[ $# -ge 2 ]] || { echo "error: $1 requires a value" >&2; exit 1; }
      BANK="$2"
      shift 2
      ;;
    -s|--slot)
      [[ $# -ge 2 ]] || { echo "error: $1 requires a value" >&2; exit 1; }
      SLOT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$JSON" ]]; then
  echo "error: missing $JSON — run: python3 projects/ehx_95000/generate.py" >&2
  exit 1
fi
if [[ ! -f "$LUA" ]]; then
  echo "error: missing $LUA" >&2
  exit 1
fi

echo "==> EHX 95000 → bank $BANK slot $SLOT"
echo "==> 1/3 push preset JSON"
"${E1[@]}" push "$JSON" -b "$BANK" -s "$SLOT"

echo "==> 2/3 push Lua"
"${E1[@]}" push "$LUA" -b "$BANK" -s "$SLOT"

echo "==> 3/3 switch to slot"
"${E1[@]}" switch -b "$BANK" -s "$SLOT"

echo "==> done (expect status: 95000 P1 ch1 MIDI_IO)"
