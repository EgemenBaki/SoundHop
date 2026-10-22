# SoundHop

A macOS menu bar app for switching the default sound output device with a
global keyboard shortcut per device.

> Status: steps 1–2 complete. Core Audio sandbox spike passed; UID-based
> remembered devices and global shortcuts are implemented. Settings and HUD
> are next.

## Requirements

- macOS 14 or later
- Xcode 26.0 or later
- Swift 6.4.1 toolchain (installed with swiftly or the swift.org installer)

The project is set to use `~/Library/Developer/Toolchains/swift-6.4.1-RELEASE.xctoolchain`
through `Scripts/toolchain/swiftc`. The wrapper exists because Xcode 26.0
launches Swift package manifest tools with a nearly empty environment when a
custom toolchain is selected. If the toolchain is not installed, the wrapper
falls back to Xcode's default toolchain so the project still opens and builds.

## Build and test

Open `SoundHop.xcodeproj` and press Run. The app is ad-hoc signed for local
development, so no development team is required.

From Terminal:

```sh
Scripts/build.sh
Scripts/test.sh
```

`Scripts/test.sh` runs the 12 unit tests for UID matching, remembered devices,
default shortcut assignment and shortcut-name encoding.

## Architecture

- `AudioDeviceService` — UI-free Core Audio HAL wrapper. Lists output devices,
  reads the default output, and sets the default output/system output. Switch
  results are verified by reading the default device back.
- `AudioDeviceMonitor` — `AudioObjectAddPropertyListenerBlock` listeners for
  device add/remove and default-output changes. Callbacks are delivered on the
  main queue.
- `AudioDevice` — connected device value type; identity is the persistent
  `kAudioDevicePropertyDeviceUID`.
- `DeviceLibrary` — persisted list of every device ever seen, matched only by
  UID. Devices stay remembered when disconnected. First-seen ordinals drive the
  one-time default shortcut assignment.
- `DeviceShortcuts` — encodes UIDs into dot-free `KeyboardShortcuts.Name`
  values, and defines Control+Command+1 through Control+Command+9.
- `DeviceStore` — observable app state; reconciles live devices with the
  library, installs defaults once, registers global hotkeys by UID, and performs
  verified switches.
- `Preferences` — UserDefaults-backed settings. “Also move alert sounds” is on
  by default.

Only the KeyboardShortcuts Swift package is used
(`https://github.com/sindresorhus/KeyboardShortcuts`, pinned to 3.1.0).

## Sandbox spike

The app is sandboxed (`com.apple.security.app-sandbox`) and carries no other
entitlements. The temporary launch-argument harness still works:

```sh
APP=.build/Build/Products/Debug/SoundHop.app/Contents/MacOS/SoundHop
"$APP" --spike-list
"$APP" --spike-shortcuts
"$APP" --spike-switch BuiltInSpeakerDevice
"$APP" --spike-switch BuiltInSpeakerDevice --also-system
```

`--spike-switch` reads the default device back and prints whether the change
stuck. `--also-system` additionally sets
`kAudioHardwarePropertyDefaultSystemOutputDevice`.

Verified on macOS 26.6.2:

- Listing devices works inside the sandbox.
- Setting the default output and system output works and sticks.
- Bluetooth names with non-ASCII characters (Turkish) round-trip correctly.
- Control+Command+1/2 are installed for the first two devices seen, and
  `KeyboardShortcuts.isEnabled(for:)` reports both as active.

## Current limitations

- Settings window, HUD and the shortcut recorder UI are not built yet.
- Launch at login, the tip jar, the About screen and final App Store assets are
  not built yet.
