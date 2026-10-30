#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD_DIR="$ROOT/.release-build"
DIST_DIR="$ROOT/dist"
STAGING_DIR="$DIST_DIR/staging"
APP="$BUILD_DIR/Build/Products/Release/SoundHop.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' SoundHop/Support/Info.plist 2>/dev/null || echo 1.0)"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR" "$STAGING_DIR"

echo "Building SoundHop $VERSION (universal)…"

xcodebuild \
    -project "$ROOT/SoundHop.xcodeproj" \
    -scheme SoundHop \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    CODE_SIGN_STYLE=Manual \
    build

if [ ! -d "$APP" ]; then
    echo "Build finished but $APP is missing." >&2
    exit 1
fi

echo "Architectures:"
lipo -info "$APP/Contents/MacOS/SoundHop"

echo "Signing:"
codesign -dv --verbose=2 "$APP" 2>&1 | sed -n '1,10p'

ditto "$APP" "$STAGING_DIR/SoundHop.app"
ln -s /Applications "$STAGING_DIR/Applications"

cat > "$STAGING_DIR/Read Me.txt" <<EOF
SoundHop $VERSION

1. Drag SoundHop to the Applications folder.
2. Open SoundHop from Applications.
3. Click the speaker icon in the menu bar.

SoundHop requires macOS 14 or later.

This build is ad-hoc signed and not notarized by Apple. On first launch macOS
may block it. Open System Settings → Privacy & Security, find the message
about SoundHop, and click "Open Anyway".

Source and installation notes:
https://github.com/EgemenBaki/SoundHop
EOF

rm -f "$DIST_DIR/SoundHop.dmg" "$DIST_DIR/SoundHop.dmg.sha256"

hdiutil create \
    -volname "SoundHop" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DIST_DIR/SoundHop.dmg" >/dev/null

(
    cd "$DIST_DIR"
    shasum -a 256 SoundHop.dmg > SoundHop.dmg.sha256
)

rm -rf "$STAGING_DIR"

echo ""
echo "Created:"
ls -lh "$DIST_DIR/SoundHop.dmg" "$DIST_DIR/SoundHop.dmg.sha256"
echo ""
cat "$DIST_DIR/SoundHop.dmg.sha256"
