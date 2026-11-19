# SoundHop

A tiny, open-source macOS menu bar app for switching your sound output device
with a global keyboard shortcut.

[Download the latest release](https://github.com/EgemenBaki/SoundHop/releases/latest) ·
[Website](https://soundhop.egemenbaki.com.tr/) ·
[MIT licensed](LICENSE)

SoundHop lives in the menu bar. Press a shortcut and your Mac hops to the right
speakers, headphones, AirPods or Apple TV. Each shortcut is tied to the device's
persistent Core Audio UID, so it stays with the right device when you reconnect.

## Install

SoundHop requires **macOS 14 or later**.

1. Download the latest release and open `SoundHop.dmg`.
2. Drag **SoundHop** into Applications.
3. Open SoundHop from Applications.

The release is **signed with a Developer ID certificate and notarized by
Apple**, so macOS opens it without a security warning.

You can confirm that yourself before installing:

```sh
spctl --assess --type open --context context:primary-signature -v SoundHop.dmg
codesign --verify --strict -v /Applications/SoundHop.app
```

See [INSTALL.md](INSTALL.md) for details and build instructions.

## Features

- One global shortcut per output device
- Defaults are Control-Command-1 through 9, and any shortcut can be changed or
  cleared
- Live device add/remove and default-output updates
- Connect or disconnect paired Bluetooth audio devices from the menu
- Disconnected devices stay remembered with their shortcut
- Optional compact HUD
- Launch at login
- Also move alert sounds
- Free and open source, with no accounts, analytics or network access

## Build from source

Requirements:

- macOS 14 or later
- Xcode 26 or later, with a Swift 6.4 toolchain (Xcode 27's bundled one works)

```sh
Scripts/build.sh
Scripts/test.sh
```

Or open `SoundHop.xcodeproj` in Xcode and press Run.

The project uses `~/Library/Developer/Toolchains/swift-6.4.1-RELEASE.xctoolchain`
through `Scripts/toolchain/swiftc` when it is available. The wrapper supplies
the environment Xcode 26.0 needs when resolving Swift package manifests with a
custom toolchain. When no swiftly toolchain is installed it uses Xcode's own
compiler, which matches the SDK, rather than the Command Line Tools'.

## Release

```sh
Scripts/package-release.sh
```

This builds a universal (`arm64` + `x86_64`) Release app, signs and notarizes
it with a Developer ID certificate, creates `dist/SoundHop.dmg`, signs and
notarizes that too, and writes a SHA-256 file. See [RELEASING.md](RELEASING.md).

The website download button points to:

```text
https://github.com/EgemenBaki/SoundHop/releases/latest/download/SoundHop.dmg
```

## Architecture

- `AudioDeviceService` — UI-free Core Audio HAL wrapper. Lists output devices,
  reads the default output, and sets the default output/system output. Switch
  results are verified by reading the default device back.
- `AudioDeviceMonitor` — `AudioObjectAddPropertyListenerBlock` listeners for
  device add/remove and default-output changes.
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
- `SettingsView` — SwiftUI Settings scene with per-device shortcut recorders,
  Forget actions, Launch at Login, HUD and alert-sound toggles.
- `HUDController` — borderless non-activating `NSPanel` with a SwiftUI material
  view, shown for 1.5 seconds.
- `SettingsOpener` — macOS 26 menu-bar workaround for opening the SwiftUI
  Settings scene reliably.
- `AboutWindowController` / `AboutView` — About window.

The only external dependency is
[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts), pinned
to 3.1.0.

## Privacy

SoundHop collects no data. See [PRIVACY.md](PRIVACY.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT © 2026 Egemen Baki
