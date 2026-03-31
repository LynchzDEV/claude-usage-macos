#!/bin/bash
set -e
cd "$(dirname "$0")"

swift build 2>&1 | grep -v "^Build complete"

APP=.build/debug/ClaudeBar.app
mkdir -p "$APP/Contents/MacOS"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.claudebar.app</string>
    <key>CFBundleName</key>
    <string>ClaudeBar</string>
    <key>CFBundleExecutable</key>
    <string>ClaudeBar</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

cp .build/debug/ClaudeBar "$APP/Contents/MacOS/ClaudeBar"

pkill ClaudeBar 2>/dev/null || true
sleep 0.5
open "$APP"
echo "ClaudeBar launched."
