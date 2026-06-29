#!/bin/bash
# Build ElectraOne.app — a double-clickable macOS app bundle.
#
# Usage: ./build-app.sh            (release build into ./ElectraOne.app)
#        open ./ElectraOne.app     (launch it)
set -euo pipefail

cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP="ElectraOne.app"
BUNDLE_ID="one.electra.companion"

echo "▶ swift build -c $CONFIG"
swift build -c "$CONFIG" --product ElectraOneApp

BIN="$(swift build -c "$CONFIG" --product ElectraOneApp --show-bin-path)/ElectraOneApp"

echo "▶ assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ElectraOne"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>Electra One</string>
    <key>CFBundleDisplayName</key>     <string>Electra One</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleExecutable</key>      <string>ElectraOne</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>LSApplicationCategoryType</key><string>public.app-category.music</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so Gatekeeper lets it run locally.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || echo "  (codesign skipped)"

echo "✓ built $APP"
echo "  launch with:  open $(pwd)/$APP"
