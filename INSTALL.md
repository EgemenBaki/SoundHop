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

## First launch: macOS may block the app

The current release is **ad-hoc signed but not notarized by Apple**. macOS
Gatekeeper may show a dialog saying:

> “SoundHop” Not Opened — Apple could not verify “SoundHop” is free of malware.

**This is expected. The app is not damaged.**

1. Click **Done**. Do **not** click “Move to Trash.”
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the **Security** section.
4. Find the message about **SoundHop** and click **Open Anyway**.
5. Confirm with Touch ID or your password, then click **Open**.
6. Open SoundHop again from Applications.

This only needs to be done once. After approval, SoundHop opens normally.

Do not disable Gatekeeper globally.

### Terminal alternative

If you are comfortable with Terminal, you can remove the quarantine flag from
this one app:

```sh
xattr -dr com.apple.quarantine /Applications/SoundHop.app
open /Applications/SoundHop.app
```

This does not change any global security setting.

### Why can't the app ask for permission itself?

macOS blocks the app **before any of its code runs**, so it cannot show its own
“please allow me” prompt. There is no public API for an app or installer to
request Gatekeeper approval. The approval must come from macOS and the user.

The only way to make the app open without this warning for every user is to
notarize it with Apple. That requires a paid Apple Developer Program membership
and a Developer ID certificate. This open-source build intentionally avoids
that cost, so the first-launch approval is required.

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
Applications. To clear remembered devices and preferences, remove the app’s
local container as well.
