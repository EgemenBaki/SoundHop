# Install SoundHop

SoundHop requires **macOS 14 or later**.

## Download

Download the latest release:

```text
https://github.com/EgemenBaki/SoundHop/releases/latest
```

1. Open `SoundHop.dmg`.
2. Drag **SoundHop** into the **Applications** folder.
3. Eject the DMG.
4. Open SoundHop from Applications.
5. Click the speaker icon in the macOS menu bar.

SoundHop has no Dock icon and no main window. It lives in the menu bar.

## First launch

SoundHop is signed with a Developer ID certificate and notarized by Apple.
macOS verifies the download and opens the app normally: there is no Gatekeeper
warning and no approval step. Just open it from Applications and click the
speaker icon in the menu bar.

If macOS ever refuses to open your copy, it is old or has been modified. Delete
it and download the latest release again instead of overriding the warning.

## Verify the download

If you want to check the build before trusting it, run:

```sh
spctl --assess --type open --context context:primary-signature -v SoundHop.dmg
codesign --verify --strict -v /Applications/SoundHop.app
```

`spctl` should report `accepted`, and `codesign` should finish without errors.


## Build from source

Requirements: macOS 14+ and Xcode 26 or later. Xcode's bundled Swift toolchain
is used when no swiftly toolchain is installed.

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
Applications. To clear remembered devices and preferences, remove the app’s
local container as well.
