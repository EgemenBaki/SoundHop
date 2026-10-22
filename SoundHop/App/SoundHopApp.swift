import AppKit
import SwiftUI

@main
struct SoundHopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DeviceStore()

    var body: some Scene {
        MenuBarExtra("SoundHop", systemImage: "hifispeaker.2") {
            if let error = store.lastError {
                Text(error)
                Divider()
            }

            if store.devices.isEmpty {
                Text("No output devices")
            } else {
                ForEach(store.devices) { device in
                    Toggle(
                        device.name,
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
}
