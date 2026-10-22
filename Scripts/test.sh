#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ -x "$ROOT/Scripts/toolchain/swiftc" ]; then
    export SWIFT_EXEC="$ROOT/Scripts/toolchain/swiftc"
fi

exec xcodebuild \
    -project "$ROOT/SoundHop.xcodeproj" \
    -scheme SoundHop \
    -configuration Debug \
    -derivedDataPath "$ROOT/.build" \
    test \
    "$@"
