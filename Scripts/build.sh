#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Use the full Xcode even when xcode-select still points at the Command Line
# Tools, which cannot build an app.
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    export DEVELOPER_DIR
fi

if [ -x "$ROOT/Scripts/toolchain/swiftc" ]; then
    export SWIFT_EXEC="$ROOT/Scripts/toolchain/swiftc"
fi

exec xcodebuild \
    -project "$ROOT/SoundHop.xcodeproj" \
    -scheme SoundHop \
    -configuration Debug \
    -derivedDataPath "$ROOT/.build" \
    "$@"
