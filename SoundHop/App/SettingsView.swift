import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: DeviceStore

    @AppStorage(Preferences.Key.showHUD) private var showHUD = true
    @AppStorage(Preferences.Key.moveAlertSounds) private var moveAlertSounds = true

    @StateObject private var launchAtLogin = LaunchAtLoginController()

    var body: some View {
        Form {
            Section {
                if store.rememberedDevices.isEmpty {
                    Text("No output devices have been seen yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.rememberedDevices) { device in
                        let isConnected = store.isConnected(device.uid)
                        let address = device.bluetoothAddress

                        DeviceRow(
                            device: device,
                            isConnected: isConnected,
                            displayName: displayName(for: device),
                            canConnect: !isConnected && pairedDevice(for: device) != nil,
                            canDisconnect: isConnected && address != nil,
                            isBluetoothBusy: address.map {
                                store.isConnecting($0) || store.isDisconnecting($0)
                            } ?? false,
                            onConnect: {
                                if let paired = pairedDevice(for: device) {
                                    store.connect(paired)
                                }
                            },
                            onDisconnect: {
                                if let address {
                                    store.disconnect(address, name: device.name)
                                }
                            },
                            onForget: {
                                store.forgetDisconnectedDevice(uid: device.uid)
                            }
                        )
                    }
                }
            } header: {
                Text("Devices")
            } footer: {
                Text("Shortcuts are bound to each device's persistent UID, not its position or name. Disconnected devices keep their shortcut.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("General") {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    )
                )

                if let errorMessage = launchAtLogin.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if launchAtLogin.requiresApproval {
                    Text("Approve SoundHop in System Settings › General › Login Items.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle("Show HUD", isOn: $showHUD)
                Toggle("Also move alert sounds", isOn: $moveAlertSounds)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 560)
        .onAppear {
            launchAtLogin.refresh()
        }
    }

    private func displayName(for device: RememberedDevice) -> String {
        let duplicates = store.rememberedDevices.filter { $0.name == device.name }.count
        return duplicates > 1
            ? "\(device.name) (\(device.transport.displayName))"
            : device.name
    }

    private func pairedDevice(for device: RememberedDevice) -> PairedBluetoothDevice? {
        guard let address = device.bluetoothAddress else { return nil }
        return store.pairedBluetoothDevice(for: address)
    }
}

private struct DeviceRow: View {
    let device: RememberedDevice
    let isConnected: Bool
    let displayName: String
    let canConnect: Bool
    let canDisconnect: Bool
    let isBluetoothBusy: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onForget: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.transport.symbolName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isConnected ? Color.accentColor : Color.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if device.isVirtual {
                        Text("Virtual")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            KeyboardShortcuts.Recorder(for: DeviceShortcuts.name(forUID: device.uid))

            if canDisconnect {
                Button("Disconnect", action: onDisconnect)
                    .buttonStyle(.borderless)
                    .disabled(isBluetoothBusy)
                    .help("Disconnect \(device.name)")
                    .accessibilityLabel("Disconnect \(device.name)")
            }

            if canConnect {
                Button("Connect", action: onConnect)
                    .buttonStyle(.borderless)
                    .disabled(isBluetoothBusy)
                    .help("Connect \(device.name)")
                    .accessibilityLabel("Connect \(device.name)")
            }

            if !isConnected {
                Button("Forget", role: .destructive, action: onForget)
                    .buttonStyle(.borderless)
                    .help("Forget \(device.name) and remove its shortcut")
                    .accessibilityLabel("Forget \(device.name)")
            }
        }
        .padding(.vertical, 2)
        .opacity(isConnected ? 1 : 0.55)
    }

    private var statusText: String {
        if !isConnected {
            return "\(device.transport.displayName) · Not connected"
        }
        return device.isVirtual
            ? "\(device.transport.displayName) · Virtual output"
            : device.transport.displayName
    }
}
