# Contributing

SoundHop is open source under the MIT license. Bug reports and pull requests are
welcome.

## Development

```sh
git clone https://github.com/EgemenBaki/SoundHop.git
cd SoundHop
Scripts/build.sh
Scripts/test.sh
```

Open `SoundHop.xcodeproj` in Xcode for the full app. The project targets macOS
14 and uses Swift 6 language mode.

## Guidelines

- Keep device identity based on the Core Audio UID. Never match devices by name.
- Keep `AudioDeviceService` free of UI code.
- Do not add analytics, telemetry, accounts or network access.
- Add tests for device-binding and persistence changes.
- Keep the app sandboxed.
- Do not introduce a new dependency without discussing it first.

By contributing, you agree that your contribution is licensed under the MIT
license.
