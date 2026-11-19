#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Xcode 26+ is required. If the full Xcode is installed but xcode-select still
# points at the Command Line Tools, use Xcode for this build.
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    export DEVELOPER_DIR
fi

BUILD_DIR="$ROOT/.release-build"
DIST_DIR="$ROOT/dist"
STAGING_DIR="$DIST_DIR/staging"
APP="$BUILD_DIR/Build/Products/Release/SoundHop.app"
DMG="$DIST_DIR/SoundHop.dmg"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' SoundHop/Support/Info.plist 2>/dev/null || echo 1.0)"

NOTARY_PROFILE="${NOTARY_PROFILE:-SoundHop-notary}"

# A Developer ID Application certificate is required to sign for distribution
# outside the App Store. Override with SIGN_IDENTITY to pick a specific one.
IDENTITY="${SIGN_IDENTITY:-}"
if [ -z "$IDENTITY" ]; then
    IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
        | sed -n 's/^[[:space:]]*[0-9][0-9]*) [0-9A-F]*[[:space:]]*"\(Developer ID Application: .*\)"$/\1/p' \
        | head -n 1)"
fi

SIGNED=0
if [ -n "$IDENTITY" ]; then
    TEAM_ID="${TEAM_ID:-$(printf '%s\n' "$IDENTITY" | sed -n 's/.*(\([A-Z0-9]\{10\}\))$/\1/p')}"
    if [ -z "$TEAM_ID" ]; then
        echo "Could not read the team ID from \"$IDENTITY\"." >&2
        echo "Set TEAM_ID=XXXXXXXXXX and run again." >&2
        exit 1
    fi
    # Two certificates can share a name, which makes `codesign` fail as
    # ambiguous. Resolve the identity to its SHA-1 hash for command-line use.
    IDENTITY_HASH="${SIGN_IDENTITY_HASH:-$(security find-identity -v -p codesigning 2>/dev/null \
        | sed -n 's/^[[:space:]]*[0-9][0-9]*) \([0-9A-F]*\)[[:space:]]*"Developer ID Application: .*"$/\1/p' \
        | head -n 1)}"
    SIGNED=1
    echo "Signing with: $IDENTITY"
    echo "Identity:     ${IDENTITY_HASH:-$IDENTITY}"
    echo "Team ID:      $TEAM_ID"
else
    echo "No Developer ID Application certificate found."
    echo "Falling back to an ad-hoc signed, not notarized build."
    echo "See RELEASING.md to set up signing and notarization."
fi

notarize() {
    # $1: a .zip containing the app, or a .dmg
    echo ""
    echo "Submitting $(basename "$1") to Apple for notarization (this can take a few minutes)…"
    OUTPUT="$(xcrun notarytool submit "$1" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)" || {
        printf '%s\n' "$OUTPUT" >&2
        echo "" >&2
        echo "Notarization request failed." >&2
        echo "Store credentials once with:" >&2
        echo "  xcrun notarytool store-credentials \"$NOTARY_PROFILE\" --apple-id <your Apple ID> --team-id $TEAM_ID" >&2
        exit 1
    }
    printf '%s\n' "$OUTPUT"
    case "$OUTPUT" in
        *"status: Accepted"*) ;;
        *)
            echo "" >&2
            echo "Apple rejected the submission. Inspect the log with:" >&2
            echo "  xcrun notarytool log <submission-id> --keychain-profile \"$NOTARY_PROFILE\"" >&2
            exit 1
            ;;
    esac
}

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR" "$STAGING_DIR"

echo ""
echo "Building SoundHop $VERSION (universal)…"

set -- \
    -project "$ROOT/SoundHop.xcodeproj" \
    -scheme SoundHop \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    build

if [ "$SIGNED" -eq 1 ]; then
    set -- "$@" CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM="$TEAM_ID" OTHER_CODE_SIGN_FLAGS="--timestamp"
else
    set -- "$@" CODE_SIGN_IDENTITY=-
fi

xcodebuild "$@"

if [ ! -d "$APP" ]; then
    echo "Build finished but $APP is missing." >&2
    exit 1
fi

echo ""
echo "Architectures:"
lipo -info "$APP/Contents/MacOS/SoundHop"

if [ "$SIGNED" -eq 1 ]; then
    echo ""
    echo "Verifying signature…"
    codesign --verify --deep --strict --verbose=2 "$APP"

    ZIP="$DIST_DIR/SoundHop-notarize.zip"
    ditto -c -k --keepParent "$APP" "$ZIP"
    notarize "$ZIP"
    rm -f "$ZIP"

    echo ""
    echo "Stapling the ticket to the app…"
    xcrun stapler staple "$APP"
    xcrun stapler validate "$APP"
    spctl -a -vvv --type execute "$APP"
fi

ditto "$APP" "$STAGING_DIR/SoundHop.app"
ln -s /Applications "$STAGING_DIR/Applications"

if [ "$SIGNED" -eq 1 ]; then
    cat > "$STAGING_DIR/Read Me.txt" <<EOF
SoundHop $VERSION

1. Drag SoundHop to the Applications folder.
2. Open SoundHop from Applications.
3. Click the speaker icon in the menu bar.

SoundHop requires macOS 14 or later.

This build is signed with a Developer ID certificate and notarized by Apple,
so macOS opens it without a security warning.

Full installation notes:
https://github.com/EgemenBaki/SoundHop/blob/main/INSTALL.md
EOF
else
    cat > "$STAGING_DIR/Read Me.txt" <<EOF
SoundHop $VERSION

1. Drag SoundHop to the Applications folder.
2. Open SoundHop from Applications.
3. Click the speaker icon in the menu bar.

SoundHop requires macOS 14 or later.

This build is ad-hoc signed and not notarized by Apple. On first launch macOS
may show "SoundHop Not Opened." This is expected.

1. Click Done. Do NOT click Move to Trash.
2. Open System Settings → Privacy & Security.
3. Find the SoundHop message under Security and click Open Anyway.
4. Confirm, then open SoundHop from Applications.

This only needs to be done once. Do not disable Gatekeeper globally.

Full installation notes:
https://github.com/EgemenBaki/SoundHop/blob/main/INSTALL.md
EOF
fi

rm -f "$DMG" "$DMG.sha256"

hdiutil create \
    -volname "SoundHop" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG" >/dev/null

if [ "$SIGNED" -eq 1 ]; then
    echo ""
    echo "Signing the disk image…"
    codesign --force --sign "${IDENTITY_HASH:-$IDENTITY}" --timestamp "$DMG"

    notarize "$DMG"

    echo ""
    echo "Stapling the ticket to the disk image…"
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
    spctl -a -vvv --type open --context context:primary-signature "$DMG"
fi

# Hash after signing and stapling: both change the DMG bytes.
(
    cd "$DIST_DIR"
    shasum -a 256 SoundHop.dmg > SoundHop.dmg.sha256
)

rm -rf "$STAGING_DIR"

echo ""
if [ "$SIGNED" -eq 1 ]; then
    echo "Signature:"
    codesign -dv --verbose=2 "$APP" 2>&1 | sed -n '1,12p'
    echo ""
else
    echo "Signing:"
    codesign -dv --verbose=2 "$APP" 2>&1 | sed -n '1,10p'
    echo ""
    echo "This build is NOT notarized. Do not describe it as notarized."
    echo ""
fi

echo "Created:"
ls -lh "$DMG" "$DMG.sha256"
echo ""
cat "$DMG.sha256"
