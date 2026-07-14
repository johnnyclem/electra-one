#!/usr/bin/env bash
# Push Valeton VLP-200 preset + Lua to Electra One, then switch to the slot.
#
# Usage:
#   ./projects/valeton_vlp200/push.sh
#   ./projects/valeton_vlp200/push.sh -b 0 -s 2
#   ./projects/valeton_vlp200/push.sh --bank 0 --slot 2
#
# Defaults: bank 0, slot 2

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
JSON="$ROOT/presets/valeton_vlp200.json"
LUA="$ROOT/presets/valeton_vlp200.lua"
E1=(node "$ROOT/bin/e1.js")

BANK=0
SLOT=2

usage() {
  cat <<EOF
Usage: $(basename "$0") [-b|--bank N] [-s|--slot N]

  Push valeton_vlp200.json, then valeton_vlp200.lua, then switch to that slot.

Options:
  -b, --bank N   Target bank (default: 0)
  -s, --slot N   Target slot (default: 2)
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
  echo "error: missing $JSON" >&2
  exit 1
fi
if [[ ! -f "$LUA" ]]; then
  echo "error: missing $LUA" >&2
  exit 1
fi

echo "==> VLP-200 → bank $BANK slot $SLOT"
echo "==> 1/3 push preset JSON"
"${E1[@]}" push "$JSON" -b "$BANK" -s "$SLOT"

echo "==> 2/3 push Lua"
"${E1[@]}" push "$LUA" -b "$BANK" -s "$SLOT"

echo "==> 3/3 switch to slot"
"${E1[@]}" switch -b "$BANK" -s "$SLOT"

echo "==> done (expect status: VLP-200 P1 ch1 MIDI_IO)"
