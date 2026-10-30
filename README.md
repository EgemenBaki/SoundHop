# SoundHop

A tiny, open-source macOS menu bar app for switching your sound output device
with a global keyboard shortcut.

[Download the latest release](https://github.com/EgemenBaki/SoundHop/releases/latest) ·
[Website](https://egemenbaki.com.tr/soundhop) ·
[MIT licensed](LICENSE)

SoundHop lives in the menu bar. Press a shortcut and your Mac hops to the right
speakers, headphones, AirPods or Apple TV. Each shortcut is tied to the device's
persistent Core Audio UID, so it stays with the right device when you reconnect.

## Install

SoundHop requires **macOS 14 or later**.

See [INSTALL.md](INSTALL.md) for download, installation and first-launch
instructions.

The current release is **ad-hoc signed but not notarized** by Apple. macOS may
show a security warning on first launch. The install guide explains how to
approve the app in System Settings. This is the trade-off of publishing without
a paid Apple Developer Program membership.

## Features

- One global shortcut per output device
- Defaults are Control-Command-1 through 9, and any shortcut can be changed or
  cleared
- Live device add/remove and default-output updates
- Disconnected devices stay remembered with their shortcut
- Optional compact HUD
- Launch at login
- Also move alert sounds
- Free and open source, with no accounts, analytics or network access

## Build from source

Requirements:

- macOS 14 or later
- Xcode 26 or later
- Swift 6.4.1 toolchain (swiftly or the swift.org installer)

```sh
Scripts/build.sh
Scripts/test.sh
```

Or open `SoundHop.xcodeproj` in Xcode and press Run.

The project uses `~/Library/Developer/Toolchains/swift-6.4.1-RELEASE.xctoolchain`
through `Scripts/toolchain/swiftc` when it is available. The wrapper supplies
the environment Xcode 26.0 needs when resolving Swift package manifests with a
custom toolchain, and falls back to Xcode's default toolchain otherwise.

## Release

```sh
Scripts/package-release.sh
```

This builds a universal (`arm64` + `x86_64`) Release app, creates
`dist/SoundHop.dmg`, and writes a SHA-256 file. See [RELEASING.md](RELEASING.md).

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
