# SoundHop

A macOS menu bar app for switching the default sound output device with a
global keyboard shortcut per device.

> Status: steps 1–3 complete. Core Audio sandboxing, UID-bound shortcuts,
> remembered devices, Settings, Launch at Login and the HUD are implemented.
> The tip jar and About screen are next.

## Requirements

- macOS 14 or later
- Xcode 26.0 or later
- Swift 6.4.1 toolchain (installed with swiftly or the swift.org installer)

The project uses `~/Library/Developer/Toolchains/swift-6.4.1-RELEASE.xctoolchain`
through `Scripts/toolchain/swiftc`. The wrapper exists because Xcode 26.0
launches Swift package manifest tools with a nearly empty environment when a
custom toolchain is selected. If the toolchain is not installed, the wrapper
falls back to Xcode's default toolchain.

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

## Launching

SoundHop is a menu bar app (`LSUIElement`), so it has no Dock icon and opens no
main window. After launching, click the speaker icon in the menu bar.

```sh
open .build/Build/Products/Debug/SoundHop.app
```

## Using it

- Click the menu bar icon to see connected output devices, each with its
  shortcut and a checkmark on the current output.
- Press **Control+Command+1** through **Control+Command+9** to switch to the
  devices that received default shortcuts.
- Open **Settings…** to record or clear a shortcut, forget disconnected
  devices, enable Launch at Login, toggle the HUD or move alert sounds.
- Press **Delete** while a shortcut recorder is focused to clear that shortcut.
- A non-activating HUD appears near the top of the screen for 1.5 seconds after
  a switch. It can be disabled in Settings.

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
- `SettingsOpener` — macOS 26 menu-bar workaround: a hidden SwiftUI window
  provides the render tree required by `openSettings`, and the activation policy
  temporarily switches to `.regular` while Settings is open. It returns to
  `.accessory` when the Settings window closes.

Only the KeyboardShortcuts Swift package is used
(`https://github.com/sindresorhus/KeyboardShortcuts`, pinned to 3.1.0).

## Sandbox spike

The app is sandboxed (`com.apple.security.app-sandbox`) and carries no other
entitlements. The temporary launch-argument harness still works:

```sh
APP=.build/Build/Products/Debug/SoundHop.app/Contents/MacOS/SoundHop
"$APP" --spike-list
"$APP" --spike-shortcuts
"$APP" --spike-watch
"$APP" --spike-hud
"$APP" --spike-switch BuiltInSpeakerDevice
"$APP" --spike-switch BuiltInSpeakerDevice --also-system
```

Verified on macOS 26.6.2:

- Listing devices works inside the sandbox.
- Setting the default output and system output works and sticks.
- Bluetooth names with non-ASCII characters (Turkish) round-trip correctly.
- Control+Command+1/2 are installed for the first two devices seen, and
  `KeyboardShortcuts.isEnabled(for:)` reports both as active.
- HAL change notifications arrive when the default output changes.
- The HUD appears as a 320×92 non-activating panel and disappears after 1.5 s.
- The HUD is suppressed when “Show HUD” is disabled.
- The Settings window opens through the hidden-window workaround.

## Current limitations

- The tip jar and About & Tip Jar screen are not built yet.
- The app icon is a placeholder.
- Final App Store metadata, privacy policy and manual test checklist are pending.
