#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$PROJECT_DIR/build/ImageConverter.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
ICONSET="$PROJECT_DIR/build/AppIcon.iconset"
rm -rf "$ICONSET"
swift "$PROJECT_DIR/src/make_icon.swift" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>ImageConverter</string>
<key>CFBundleIdentifier</key><string>local.imageconverter.app</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleName</key><string>ImageConverter</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
</dict></plist>
PLIST
clang++ -std=c++17 -fobjc-arc -framework Cocoa -framework ImageIO -framework UniformTypeIdentifiers \
  "$PROJECT_DIR/src/main.mm" -o "$APP/Contents/MacOS/ImageConverter"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
echo "Готово: $APP"
open "$APP"
