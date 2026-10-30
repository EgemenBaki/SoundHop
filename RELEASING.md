# Releasing SoundHop

SoundHop is distributed as an ad-hoc signed, **not notarized** DMG through
GitHub Releases. There is no App Store build and no Apple Developer Program
membership.

## Prepare

1. Update the version in `SoundHop/Support/Info.plist` if needed:
   - `CFBundleShortVersionString`
   - `CFBundleVersion`
2. Run the tests:

   ```sh
   Scripts/test.sh
   ```

3. Build the universal release and DMG:

   ```sh
   Scripts/package-release.sh
   ```

4. Verify the output:
   - `lipo -info` reports `arm64` and `x86_64`.
   - The app launches from the DMG.
   - `dist/SoundHop.dmg` is the expected size.

## Publish

```sh
gh release create v1.0.0 \
  dist/SoundHop.dmg \
  dist/SoundHop.dmg.sha256 \
  --title "SoundHop 1.0.0" \
  --notes "SoundHop 1.0.0. macOS 14+. See INSTALL.md for installation notes."
```

The website uses:

```text
https://github.com/EgemenBaki/SoundHop/releases/latest/download/SoundHop.dmg
```

Keep the release asset name exactly `SoundHop.dmg` so that URL keeps working.

## Important

Do not advertise the app as notarized. It is not. Users may need to approve it
in System Settings → Privacy & Security on first launch.

If you ever join the Apple Developer Program, you can add Developer ID signing
and notarization without changing the app’s distribution URL.
