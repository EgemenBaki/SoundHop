import AppKit
import SwiftUI

@main
struct SoundHopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DeviceStore()

    var body: some Scene {
        MenuBarExtra("SoundHop", systemImage: "hifispeaker.2") {
            if let feedback = store.lastFeedback {
                Text(feedback.message)
                Divider()
            } else if let error = store.lastError {
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
            Button("Refresh") { store.refresh() }
            Button("Quit SoundHop") { NSApplication.shared.terminate(nil) }
        }
        .menuBarExtraStyle(.menu)
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
