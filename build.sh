#!/bin/zsh
# Builds LinkManager.app and installs it to ~/Applications.
# Pass --no-install to only build into ./build (used by CI).
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
APP="build/LinkManager.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/LinkManager "$APP/Contents/MacOS/LinkManager"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>be.studiohyperdrive.LinkManager</string>
  <key>CFBundleName</key><string>Link Manager</string>
  <key>CFBundleExecutable</key><string>LinkManager</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"

[[ "${1:-}" == "--no-install" ]] && { echo "Built $APP"; exit 0; }

mkdir -p ~/Applications
pkill -x LinkManager 2>/dev/null || true
rm -rf ~/Applications/LinkManager.app
cp -R "$APP" ~/Applications/
open ~/Applications/LinkManager.app
echo "Installed to ~/Applications/LinkManager.app"
