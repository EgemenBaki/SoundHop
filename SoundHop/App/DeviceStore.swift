import Foundation
import KeyboardShortcuts

struct DeviceActionFeedback: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case switched
        case notConnected
        case failed
        case connectFailed
        case disconnected
        case disconnectFailed
        case audioUnavailable
    }

    let id = UUID()
    let kind: Kind
    let deviceUID: String
    let deviceName: String
    let transport: AudioDeviceTransport
    let isVirtual: Bool

    var message: String {
        switch kind {
        case .switched:
            return "Switched to \(deviceName)"
        case .notConnected:
            return "\(deviceName) isn't connected"
        case .failed:
            return "Couldn't switch to \(deviceName)"
        case .connectFailed:
            return "Couldn't connect to \(deviceName)"
        case .disconnected:
            return "Disconnected from \(deviceName)"
        case .disconnectFailed:
            return "Couldn't disconnect \(deviceName)"
        case .audioUnavailable:
            return "\(deviceName) connected, but no audio output appeared"
        }
    }
}

@MainActor
final class DeviceStore: ObservableObject {
    @Published private(set) var connectedDevices: [AudioDevice] = []
    @Published private(set) var rememberedDevices: [RememberedDevice] = []
    @Published private(set) var pairedBluetoothDevices: [PairedBluetoothDevice] = []
    @Published private(set) var defaultOutputUID: String?
    @Published private(set) var lastFeedback: DeviceActionFeedback?
    @Published private(set) var lastError: String?
    @Published private(set) var connectingAddresses: Set<BluetoothAddress> = []
    @Published private(set) var disconnectingAddresses: Set<BluetoothAddress> = []

    private var library: DeviceLibrary
    private let storage: DeviceLibraryStorage
    private let service: AudioDeviceService
    private let bluetooth: BluetoothDeviceService
    private lazy var monitor = AudioDeviceMonitor { [weak self] in
        self?.refresh()
    }
    private var registeredHotkeyUIDs = Set<String>()
    private var bluetoothRefreshTask: Task<Void, Never>?

    init(
        storage: DeviceLibraryStorage = DeviceLibraryStorage(),
        service: AudioDeviceService = AudioDeviceService(),
        bluetooth: BluetoothDeviceService = BluetoothDeviceService()
    ) {
        self.storage = storage
        self.service = service
        self.bluetooth = bluetooth
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
        refreshBluetoothDevices()

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

    func isConnecting(_ address: BluetoothAddress) -> Bool {
        connectingAddresses.contains(address)
    }

    func isDisconnecting(_ address: BluetoothAddress) -> Bool {
        disconnectingAddresses.contains(address)
    }

    func pairedBluetoothDevice(for address: BluetoothAddress) -> PairedBluetoothDevice? {
        pairedBluetoothDevices.first { $0.address == address }
    }

    /// Connects a paired device and switches to its audio output once Core
    /// Audio publishes it. Opening the connection alone often leaves the Mac
    /// on its previous output.
    func connect(_ device: PairedBluetoothDevice) {
        let address = device.address
        guard !connectingAddresses.contains(address),
              !disconnectingAddresses.contains(address)
        else { return }

        if let audioDevice = audioDevice(for: address) {
            switchOutput(to: audioDevice)
            return
        }

        connectingAddresses.insert(address)
        let bluetoothService = bluetooth
        Task {
            let connected = await Task.detached(priority: .userInitiated) {
                bluetoothService.connect(address)
            }.value

            guard connected else {
                connectingAddresses.remove(address)
                refreshBluetoothDevices()
                present(feedback(.connectFailed, address: address, name: device.name))
                return
            }

            guard let audioDevice = await waitForAudioDevice(address: address) else {
                connectingAddresses.remove(address)
                refresh()
                present(feedback(.audioUnavailable, address: address, name: device.name))
                return
            }

            connectingAddresses.remove(address)
            refresh()
            switchOutput(to: audioDevice)
        }
    }

    func disconnect(_ address: BluetoothAddress, name: String) {
        guard !connectingAddresses.contains(address),
              !disconnectingAddresses.contains(address)
        else { return }

        disconnectingAddresses.insert(address)
        let bluetoothService = bluetooth
        Task {
            let disconnected = await Task.detached(priority: .userInitiated) {
                bluetoothService.disconnect(address)
            }.value

            disconnectingAddresses.remove(address)
            refresh()
            present(
                feedback(
                    disconnected ? .disconnected : .disconnectFailed,
                    address: address,
                    name: name
                )
            )
        }
    }

    func switchOutput(to device: AudioDevice) {
        guard let remembered = library.rememberedDevice(forUID: device.uid) else {
            return
        }
        guard isConnected(device.uid) else {
            present(DeviceActionFeedback(
                kind: .notConnected,
                deviceUID: remembered.uid,
                deviceName: remembered.name,
                transport: remembered.transport,
                isVirtual: remembered.isVirtual
            ))
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
                present(DeviceActionFeedback(
                    kind: .switched,
                    deviceUID: remembered.uid,
                    deviceName: remembered.name,
                    transport: remembered.transport,
                    isVirtual: remembered.isVirtual
                ))
            } else {
                present(DeviceActionFeedback(
                    kind: .failed,
                    deviceUID: remembered.uid,
                    deviceName: remembered.name,
                    transport: remembered.transport,
                    isVirtual: remembered.isVirtual
                ))
            }
        } catch {
            refresh()
            present(DeviceActionFeedback(
                kind: .failed,
                deviceUID: remembered.uid,
                deviceName: remembered.name,
                transport: remembered.transport,
                isVirtual: remembered.isVirtual
            ))
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
            present(DeviceActionFeedback(
                kind: .notConnected,
                deviceUID: remembered.uid,
                deviceName: remembered.name,
                transport: remembered.transport,
                isVirtual: remembered.isVirtual
            ))
            return
        }
        switchOutput(to: device)
    }

    private func present(_ feedback: DeviceActionFeedback) {
        lastFeedback = feedback
        HUDController.shared.present(feedback)
    }

    private func refreshBluetoothDevices() {
        bluetoothRefreshTask?.cancel()
        bluetoothRefreshTask = Task { [bluetooth] in
            let devices = await Task.detached(priority: .utility) {
                bluetooth.pairedAudioDevices()
            }.value
            guard !Task.isCancelled else { return }
            pairedBluetoothDevices = devices
        }
    }

    private func audioDevice(for address: BluetoothAddress) -> AudioDevice? {
        connectedDevices.first { $0.bluetoothAddress == address }
    }

    /// Connecting only makes the device reachable; the HAL endpoint appears a
    /// moment later, and switching before then fails.
    private func waitForAudioDevice(
        address: BluetoothAddress,
        timeout: Duration = .seconds(8)
    ) async -> AudioDevice? {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if let device = audioDevice(for: address) { return device }
            try? await Task.sleep(for: .milliseconds(200))
        }
        return audioDevice(for: address)
    }

    private func feedback(
        _ kind: DeviceActionFeedback.Kind,
        address: BluetoothAddress,
        name: String
    ) -> DeviceActionFeedback {
        DeviceActionFeedback(
            kind: kind,
            deviceUID: address.digits,
            deviceName: name,
            transport: .bluetooth,
            isVirtual: false
        )
    }
}
