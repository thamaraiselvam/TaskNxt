#!/bin/bash
# Builds TaskNxt and packages it as a real, double-clickable TaskNxt.app
# bundle (Contents/MacOS + Contents/Resources/AppIcon.icns), instead of
# just running the bare SwiftPM executable produced by `swift build`.
#
# Why this exists: a bare Mach-O binary has nowhere for macOS to look up
# a custom app icon from -- CFBundleIconFile (set in Info.plist) only
# resolves against a real bundle's Contents/Resources/ directory. Without
# this wrapping step, the app always shows a generic/old icon in the Dock,
# Finder, and the Settings window's title bar no matter what's in
# AppIcon.appiconset, since nothing ever converts those PNGs into an
# .icns or places them where the OS actually looks.
set -euo pipefail

CONFIGURATION="${1:-release}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/.."
BUILD_DIR="$APP_DIR/.build/$CONFIGURATION"
APP_BUNDLE="$APP_DIR/.build/TaskNxt.app"
ICONSET_SRC="$APP_DIR/Resources/Assets.xcassets/AppIcon.appiconset"

echo "==> Building TaskNxt ($CONFIGURATION)"
(cd "$APP_DIR" && swift build -c "$CONFIGURATION")

echo "==> Assembling TaskNxt.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/TaskNxt" "$APP_BUNDLE/Contents/MacOS/TaskNxt"
cp "$APP_DIR/Sources/TaskNxt/App/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy any SwiftPM-generated resource bundle(s) (e.g. the raw
# Assets.xcassets folder copied for other in-app image lookups) alongside
# the executable, matching where Bundle.module expects to find them.
for res in "$BUILD_DIR"/*.bundle; do
    [ -e "$res" ] && cp -R "$res" "$APP_BUNDLE/Contents/Resources/"
done

echo "==> Generating AppIcon.icns"
ICONSET_TMP="$(mktemp -d)/AppIcon.iconset"
cp -R "$ICONSET_SRC" "$ICONSET_TMP"
rm -f "$ICONSET_TMP/Contents.json"
iconutil -c icns "$ICONSET_TMP" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$ICONSET_TMP")"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP_BUNDLE"

# Nudge Launch Services / the Dock to drop any cached icon for this
# bundle path so the new one actually shows up without a reboot.
touch "$APP_BUNDLE"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE" >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true

echo "==> Done: $APP_BUNDLE"
echo "    open \"$APP_BUNDLE\""
