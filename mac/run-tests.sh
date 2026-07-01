#!/usr/bin/env bash
#
# Run the ElectraKit / LuaKit unit tests (swift-testing).
#
# Under a full Xcode install `swift test` finds the testing library on its own.
# With only the Command Line Tools, swift-testing ships as a framework that is
# not on the default search/rpath, so we point the compiler and dynamic loader
# at it explicitly. This script papers over that difference.
set -euo pipefail
cd "$(dirname "$0")"

DEV="$(xcode-select -p)"
FWDIR="$DEV/Library/Developer/Frameworks"
LIBDIR="$DEV/Library/Developer/usr/lib"

if [ -d "$FWDIR/Testing.framework" ]; then
  exec swift test \
    -Xswiftc -F -Xswiftc "$FWDIR" \
    -Xlinker -rpath -Xlinker "$FWDIR" \
    -Xlinker -rpath -Xlinker "$LIBDIR" "$@"
else
  exec swift test "$@"
fi
