# SoundHop

A macOS menu bar app for switching the default sound output device with a
global keyboard shortcut per device.

> Status: step 1 (Core Audio sandbox spike) complete, awaiting confirmation.

## Build

```sh
xcodebuild -project SoundHop.xcodeproj -scheme SoundHop -configuration Debug \
  -derivedDataPath /tmp/soundhop-derived build \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual
```

Or open `SoundHop.xcodeproj` in Xcode and press Run. The project is configured
for local ad-hoc signing so no development team is needed for the spike. A
distribution build will need a real signing identity and team.

## Sandbox spike

The app is sandboxed (`com.apple.security.app-sandbox`) and carries no other
entitlements. A temporary launch-argument harness exercises Core Audio without
going through the menu:

```sh
APP=/tmp/soundhop-derived/Build/Products/Debug/SoundHop.app/Contents/MacOS/SoundHop
"$APP" --spike-list
"$APP" --spike-switch BuiltInSpeakerDevice
"$APP" --spike-switch BuiltInSpeakerDevice --also-system
```

`--spike-switch` reads the default device back and prints whether the change
stuck. `--also-system` additionally sets
`kAudioHardwarePropertyDefaultSystemOutputDevice`.

Results on macOS 26.6.2 / Xcode 26.0:

- Device listing works inside the sandbox.
- Setting `kAudioHardwarePropertyDefaultOutputDevice` works and sticks.
- Setting `kAudioHardwarePropertyDefaultSystemOutputDevice` works.
- Bluetooth device names with non-ASCII characters (Turkish) round-trip
  correctly.
