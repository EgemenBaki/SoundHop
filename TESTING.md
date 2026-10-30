# Manual test checklist

Use this before publishing a release.

## Install

- [ ] Download `SoundHop.dmg` from the latest GitHub release.
- [ ] Open the DMG and drag SoundHop to Applications.
- [ ] First launch on a quarantined download shows the expected macOS security
      message.
- [ ] System Settings → Privacy & Security → Open Anyway launches the app.
- [ ] No Dock icon appears.
- [ ] The speaker icon appears in the menu bar.

## Devices and shortcuts

- [ ] Built-in speakers are listed with a checkmark when current.
- [ ] Bluetooth headphones are listed and switching works.
- [ ] Pressing a shortcut switches the output.
- [ ] Changing a default shortcut works and persists after relaunch.
- [ ] Clearing a shortcut with Delete works.
- [ ] Connecting a new device assigns the next default shortcut (up to 9).
- [ ] Disconnecting a device keeps it in Settings, greyed out.
- [ ] Pressing a disconnected device's shortcut shows “<name> isn't connected”
      in the HUD and changes nothing.
- [ ] Reconnecting the device keeps its shortcut.
- [ ] Forget removes a disconnected device.

## Settings and HUD

- [ ] Launch at Login toggles and is reflected after relaunch.
- [ ] Show HUD toggles the compact HUD.
- [ ] The HUD disappears after about 1.5 seconds.
- [ ] Also move alert sounds is on by default.
- [ ] Dark Mode and Light Mode both look correct.

## Privacy and release

- [ ] No network traffic.
- [ ] No analytics or accounts.
- [ ] App launches from a quarantined DMG after Open Anyway.
- [ ] `dist/SoundHop.dmg` is universal (`arm64` and `x86_64`).
- [ ] SHA-256 file is attached to the release.
