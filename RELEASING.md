# Releasing SoundHop

SoundHop is distributed as a signed, notarized DMG through GitHub Releases.
There is no App Store build.

## One-time setup

You need a paid Apple Developer Program membership, Xcode 26 or later, and an
accepted Xcode license (`sudo xcodebuild -license accept`).

### 1. Create a Developer ID certificate

In Xcode, open **Settings → Accounts**, add your Apple ID, select your team,
click **Manage Certificates…**, press **+**, and choose **Developer ID
Application**. The certificate and its private key land in your login keychain.

### 2. Store notarization credentials

Create an app-specific password at <https://account.apple.com>, then run:

```sh
xcrun notarytool store-credentials "SoundHop-notary" \
  --apple-id "you@example.com" \
  --team-id "XXXXXXXXXX"
```

The team ID is shown on the Membership page of your developer account. The
profile name must match `NOTARY_PROFILE`, which defaults to `SoundHop-notary`.

`Scripts/package-release.sh` finds the Developer ID certificate automatically.
Override with `SIGN_IDENTITY`, `TEAM_ID` or `NOTARY_PROFILE` if needed. Without
a certificate it falls back to the old ad-hoc build and skips notarization.

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

   The script builds `arm64` and `x86_64` with the hardened runtime, signs the
   app, notarizes and staples it, signs the DMG, notarizes and staples that,
   then writes the SHA-256 file. Always run it on a Mac with the certificate:
   notarization needs Apple's servers and usually takes a few minutes.

## Verify

```sh
codesign --verify --strict -v dist/SoundHop.dmg
codesign -dv --verbose=2 /Applications/SoundHop.app
spctl --assess --type execute -vvv /Applications/SoundHop.app
spctl --assess --type open --context context:primary-signature -vvv dist/SoundHop.dmg
xcrun stapler validate dist/SoundHop.dmg
```

`spctl` must print `accepted`, and `source=Notarized Developer ID` should appear
in the app's signature details. Also confirm:

- `lipo -info` reports `arm64` and `x86_64`.
- The app launches from the DMG on a Mac that has never seen it before.
- `dist/SoundHop.dmg` is the expected size.

## Troubleshooting

**`security find-identity` reports 0 valid identities after importing the
certificate.** The certificate's CA is missing. Developer ID certificates issued
today chain to the *Developer ID – G2* intermediate, which is not preinstalled on
every Mac. Import Apple's public intermediate once:

```sh
curl -sSLO https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer
security import DeveloperIDG2CA.cer -k ~/Library/Keychains/login.keychain-db
```

**Xcode says “This operation can only be performed by the Account Holder” in
Manage Certificates**, even though you are the holder. Xcode is holding a stale
copy of your role. Create the certificate on the website instead: make a CSR
with Keychain Access → Certificate Assistant, upload it under Certificates →
Developer ID Application, then `security import` the downloaded `.cer`. Import
the G2 intermediate above if the identity does not appear.

**`xcodebuild` fails with “SDK is not supported by the compiler”.** Xcode is
handing the compiler wrapper a stripped environment, so `xcrun` resolves to the
Command Line Tools' older Swift. `Scripts/toolchain/swiftc` prefers Xcode's
bundled toolchain for this reason; check with `xcrun swift --version`.


## Publish

```sh
gh release create v1.1.1 \
  dist/SoundHop.dmg \
  dist/SoundHop.dmg.sha256 \
  --title "SoundHop 1.1.1" \
  --notes "SoundHop 1.1.1. Signed and notarized. macOS 14+."
```

The website uses:

```text
https://github.com/EgemenBaki/SoundHop/releases/latest/download/SoundHop.dmg
```

Keep the release asset name exactly `SoundHop.dmg` so that URL keeps working.

## Important

- Never describe a build as notarized unless `package-release.sh` ran with a
  Developer ID certificate. The script prints a warning when it did not.
- Stapling changes the DMG, so upload `dist/SoundHop.dmg` and its SHA-256 file
  as produced by the script. Do not re-hash a DMG you stapled by hand.
- Notarization does not mean Apple reviewed or endorsed the app. It only means
  Apple scanned it for malware. Wording should stay factual: "signed and
  notarized by Apple".
