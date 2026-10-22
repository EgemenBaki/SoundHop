import Foundation
import KeyboardShortcuts

struct DeviceActionFeedback: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case switched
        case notConnected
        case failed
    }

    let id = UUID()
    let kind: Kind
    let deviceUID: String
    let deviceName: String

    var message: String {
        switch kind {
        case .switched:
            return "Switched to \(deviceName)"
        case .notConnected:
            return "\(deviceName) isn't connected"
        case .failed:
            return "Couldn't switch to \(deviceName)"
        }
    }
}

@MainActor
final class DeviceStore: ObservableObject {
    @Published private(set) var connectedDevices: [AudioDevice] = []
    @Published private(set) var rememberedDevices: [RememberedDevice] = []
    @Published private(set) var defaultOutputUID: String?
    @Published private(set) var lastFeedback: DeviceActionFeedback?
    @Published private(set) var lastError: String?

    private var library: DeviceLibrary
    private let storage: DeviceLibraryStorage
    private let service: AudioDeviceService
    private lazy var monitor = AudioDeviceMonitor { [weak self] in
        self?.refresh()
    }
    private var registeredHotkeyUIDs = Set<String>()

    init(
        storage: DeviceLibraryStorage = DeviceLibraryStorage(),
        service: AudioDeviceService = AudioDeviceService()
    ) {
        self.storage = storage
        self.service = service
        self.library = storage.load()

        refresh()
        monitor.start()
    }

    /// The menu should show connected devices in the order they were first seen.
    var orderedConnectedDevices: [AudioDevice] {
        let byUID = Dictionary(
            connectedDevices.map { ($0.uid, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return rememberedDevices.compactMap { byUID[$0.uid] }
    }

    func isConnected(_ uid: String) -> Bool {
        connectedDevices.contains { $0.uid == uid }
    }

    func refresh() {
        do {
            lastError = nil
            let devices = try service.outputDevices()
            let firstSeen = library.reconcile(with: devices)
            connectedDevices = devices
            applyDefaultShortcuts(to: firstSeen)
            registerHotkeys(for: library.devices)
            rememberedDevices = library.devices
            storage.save(library)

            do {
                defaultOutputUID = try service.defaultOutputDeviceUID()
            } catch {
                lastError = error.localizedDescription
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func switchOutput(to device: AudioDevice) {
        guard let remembered = library.rememberedDevice(forUID: device.uid) else {
            return
        }
        guard isConnected(device.uid) else {
            lastFeedback = DeviceActionFeedback(
                kind: .notConnected,
                deviceUID: remembered.uid,
                deviceName: remembered.name
            )
            return
        }

        do {
            let result = try service.setDefaultOutput(
                uid: device.uid,
                moveSystemOutput: Preferences.moveAlertSounds
            )
            refresh()
            defaultOutputUID = result.actualUID

            if result.didStick {
                lastFeedback = DeviceActionFeedback(
                    kind: .switched,
                    deviceUID: remembered.uid,
                    deviceName: remembered.name
                )
            } else {
                lastFeedback = DeviceActionFeedback(
                    kind: .failed,
                    deviceUID: remembered.uid,
                    deviceName: remembered.name
                )
            }
        } catch {
            refresh()
            lastFeedback = DeviceActionFeedback(
                kind: .failed,
                deviceUID: remembered.uid,
                deviceName: remembered.name
            )
            lastError = error.localizedDescription
        }
    }

    @MainActor
    func shortcut(forUID uid: String) -> KeyboardShortcuts.Shortcut? {
        DeviceShortcuts.currentShortcut(forUID: uid)
    }

    /// Removes a disconnected device and its shortcut. Connected devices can't
    /// be forgotten because they would simply be rediscovered immediately.
    func forgetDisconnectedDevice(uid: String) {
        guard !isConnected(uid) else { return }

        library.forget(uid: uid)
        storage.save(library)
        rememberedDevices = library.devices

        let name = DeviceShortcuts.name(forUID: uid)
        KeyboardShortcuts.setShortcut(nil, for: name)
        KeyboardShortcuts.removeHandler(for: name)
        registeredHotkeyUIDs.remove(uid)
    }

    private func applyDefaultShortcuts(to newDevices: [RememberedDevice]) {
        for device in newDevices {
            if let slot = library.pendingDefaultShortcutSlot(forUID: device.uid),
               let shortcut = DeviceShortcuts.defaultShortcut(forSlot: slot) {
                let name = DeviceShortcuts.name(forUID: device.uid)
                // Do not overwrite a value installed by an earlier build or a
                // shortcut the user has already customized.
                if KeyboardShortcuts.getShortcut(for: name) == nil {
                    KeyboardShortcuts.setShortcut(shortcut, for: name)
                }
            }
            library.markDefaultShortcutInstalled(forUID: device.uid)
        }
    }

    private func registerHotkeys(for devices: [RememberedDevice]) {
        for device in devices {
            guard registeredHotkeyUIDs.insert(device.uid).inserted else { continue }
            let uid = device.uid
            KeyboardShortcuts.onKeyUp(for: DeviceShortcuts.name(forUID: uid)) { [weak self] in
                self?.activateDevice(uid: uid)
            }
        }
    }

    private func activateDevice(uid: String) {
        guard let remembered = library.rememberedDevice(forUID: uid) else { return }
        guard let device = connectedDevices.first(where: { $0.uid == uid }) else {
            lastFeedback = DeviceActionFeedback(
                kind: .notConnected,
                deviceUID: remembered.uid,
                deviceName: remembered.name
            )
            return
        }
        switchOutput(to: device)
    }
}
