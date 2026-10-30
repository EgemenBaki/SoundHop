# Install SoundHop

SoundHop requires **macOS 14 or later**.

## Download

Download the latest release:

```text
https://github.com/EgemenBaki/SoundHop/releases/latest
```

1. Open `SoundHop.dmg`.
2. Drag **SoundHop** into the **Applications** folder.
3. Open SoundHop from Applications.
4. Click the speaker icon in the macOS menu bar.

SoundHop has no Dock icon and no main window. It lives in the menu bar.

## If macOS says it cannot verify the app

The current release is ad-hoc signed but not notarized by Apple. macOS may show
a warning the first time you open it.

1. Try to open SoundHop.
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the security message about SoundHop.
4. Click **Open Anyway**.
5. Confirm.

Do not disable Gatekeeper globally.

This warning exists because notarization requires a paid Apple Developer
Program membership. The source is public, so you can inspect it or build it
yourself.

## Build from source

Requirements: macOS 14+, Xcode 26 or later, and the Swift 6.4.1 toolchain.

```sh
git clone https://github.com/EgemenBaki/SoundHop.git
cd SoundHop
Scripts/build.sh
open .build/Build/Products/Debug/SoundHop.app
```

Run the tests with:

```sh
Scripts/test.sh
```

The app is sandboxed and uses Core Audio to change the default output device.
No Apple Developer account is needed to build it locally.

## Uninstall

Quit SoundHop from its menu bar menu, then delete `SoundHop.app` from
Applications. Remove its local data by deleting the app's container if you want
to clear remembered devices and preferences.
