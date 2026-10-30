import AppKit
import SwiftUI

@main
struct SoundHopApp: App {
    @StateObject private var store = DeviceStore()

    var body: some Scene {
        // Must precede the Settings scene: SwiftUI needs a rendered scene for
        // openSettings to work in a menu bar-only app.
        Window("Hidden", id: "HiddenWindow") {
            HiddenSettingsContextView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)

        MenuBarExtra("SoundHop", systemImage: "hifispeaker.2") {
            MenuBarContent(store: store)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(store: store)
                .onDisappear {
                    NotificationCenter.default.post(
                        name: .soundHopSettingsWindowClosed,
                        object: nil
                    )
                }
        }
    }
}

private struct MenuBarContent: View {
    @ObservedObject var store: DeviceStore

    var body: some View {
        if let error = store.lastError {
            Text(error)
            Divider()
        }

        if store.orderedConnectedDevices.isEmpty {
            Text("No output devices")
        } else {
            ForEach(store.orderedConnectedDevices) { device in
                Toggle(
                    label(for: device),
                    isOn: Binding(
                        get: { store.defaultOutputUID == device.uid },
                        set: { isOn in
                            if isOn {
                                store.switchOutput(to: device)
                            }
                        }
                    )
                )
            }
        }

        Divider()

        Button("Settings…") {
            SettingsOpener.open()
        }

        Button("About SoundHop…") {
            AboutWindowController.shared.show()
        }

        Divider()

        Button("Quit SoundHop") {
            NSApplication.shared.terminate(nil)
        }
    }

    private func label(for device: AudioDevice) -> String {
        let duplicateNameCount = store.orderedConnectedDevices.filter {
            $0.name == device.name
        }.count
        let name = duplicateNameCount > 1
            ? "\(device.name) (\(device.transport.displayName))"
            : device.name

        guard let shortcut = store.shortcut(forUID: device.uid) else {
            return name
        }
        return "\(name) — \(shortcut.description)"
    }
}
