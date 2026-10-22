# SoundHop

A macOS menu bar app for switching the default sound output device with a
global keyboard shortcut per device.

> Status: steps 1–4 complete. Core Audio sandboxing, UID-bound shortcuts,
> remembered devices, Settings, the HUD, Launch at Login and the StoreKit tip
> jar are implemented. Final docs, App Store metadata and polish are next.

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

`Scripts/test.sh` runs 14 unit tests covering UID matching, remembered devices,
default shortcut assignment, shortcut-name encoding, StoreKit product loading
and a local consumable purchase.

## Launching

SoundHop is a menu bar app (`LSUIElement`), so it has no Dock icon and opens no
main window. After launching, click the speaker icon in the menu bar.

```sh
open .build/Build/Products/Debug/SoundHop.app
```

## Using it

- Click the menu bar icon to see connected output devices, each with its
  shortcut and a checkmark on the current output.
- Press **Control+Command+1** through **Control+Command+9** to switch.
- Open **Settings…** to record or clear a shortcut, forget disconnected
  devices, enable Launch at Login, toggle the HUD or move alert sounds.
- Press **Delete** while a shortcut recorder is focused to clear that shortcut.
- Open **About & Tip Jar…** to see app information and the three tip options.
- A non-activating HUD appears near the top of the screen for 1.5 seconds after
  a switch. It can be disabled in Settings.

## Tip jar

The app uses StoreKit 2 only. There are three consumable products:

| Product ID | Price |
| --- | --- |
| `com.egemenbaki.soundhop.tip.small` | $1.99 |
| `com.egemenbaki.soundhop.tip.medium` | $4.99 |
| `com.egemenbaki.soundhop.tip.large` | $9.99 |

Tips unlock nothing. Purchases are handled entirely by the App Store. The app
contains no external payment links.

### Testing tips locally

`SoundHop.storekit` is a local StoreKit configuration containing all three
products. It is selected in the shared **SoundHop** scheme's Run action.

To test without App Store Connect:

1. Open `SoundHop.xcodeproj` in Xcode.
2. Select the **SoundHop** scheme and **My Mac**.
3. Press **⌘R** to launch the app from Xcode.
4. Open the menu bar icon → **About & Tip Jar…**.
5. Buy a tip. The StoreKit test purchase dialog appears; no money is charged.
6. The tip jar shows the thank-you state.

If you launch the already-built `.app` directly from Finder or Terminal, Xcode
does not inject the local StoreKit configuration, so the tip jar will report
that tips are unavailable. That is expected. Use Xcode's Run action for local
StoreKit testing.

### Collecting real tips

Real tips can only be collected through the Mac App Store. Before release:

1. Join the paid Apple Developer Program.
2. Create the app record with bundle ID `com.egemenbaki.soundhop` in App Store
   Connect.
3. Create the three **Consumable** in-app purchases with the exact product IDs
   above and the intended prices.
4. Complete the Paid Applications agreement plus banking and tax information.
5. Upload a signed build, attach the in-app purchases to the version and submit
   it for review.

Until the app is live in the App Store with those products approved, there is
no way to take real money. The local `.storekit` configuration is only a
simulator.

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
- `TipJarStore` — StoreKit 2 product loading, verified purchases and purchase
  state.
- `AboutWindowController` / `AboutView` — About and tip jar window, with a
  primarily AppKit window hosting a SwiftUI view.

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
"$APP" --spike-settings
"$APP" --spike-about
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
- The Settings and About windows open through their activation-policy flow.
- StoreKit tests load the three local products and complete a consumable
  purchase with a thank-you state.

## Current limitations

- The app icon is a placeholder.
- Final App Store metadata, privacy policy and manual test checklist are pending.
- Settings and About temporarily show a Dock icon while their windows are open
  because of the macOS 26 SwiftUI activation workaround.
