import Foundation

/// A device SoundHop has seen before.
///
/// The UID is persisted as the identity. `firstSeenOrdinal` is the device's
/// position in the sequence of unique UIDs SoundHop has ever seen, which is
/// what the one-time default shortcut assignment is based on.
struct RememberedDevice: Codable, Identifiable, Hashable, Sendable {
    let uid: String
    var name: String
    var transport: AudioDeviceTransport
    var isVirtual: Bool
    let firstSeenOrdinal: Int
    var defaultShortcutInstalled: Bool

    var id: String { uid }
}

enum DefaultShortcutPolicy {
    static let maximumShortcuts = 9

    /// Returns the zero-based default shortcut slot for a device. Only the
    /// first nine unique devices seen by SoundHop receive a default shortcut.
    static func slot(forFirstSeenOrdinal ordinal: Int) -> Int? {
        guard ordinal >= 0, ordinal < maximumShortcuts else { return nil }
        return ordinal
    }
}

/// The persisted, UI-independent list of devices SoundHop knows about.
///
/// Reconciliation never matches on names. Devices are matched exclusively by
/// their Core Audio UID so that a rename or a reordered device list cannot
/// silently move a shortcut to a different device.
struct DeviceLibrary: Codable, Equatable, Sendable {
    private(set) var devices: [RememberedDevice]
    private(set) var nextOrdinal: Int

    init(devices: [RememberedDevice] = [], nextOrdinal: Int = 0) {
        self.devices = devices.sorted { $0.firstSeenOrdinal < $1.firstSeenOrdinal }
        self.nextOrdinal = max(nextOrdinal, (devices.map(\.firstSeenOrdinal).max() ?? -1) + 1)
    }

    func rememberedDevice(forUID uid: String) -> RememberedDevice? {
        devices.first { $0.uid == uid }
    }

    /// Updates metadata for connected devices and remembers newly seen UIDs.
    /// Returns only the devices that were seen for the first time.
    @discardableResult
    mutating func reconcile(with connectedDevices: [AudioDevice]) -> [RememberedDevice] {
        var firstSeen: [RememberedDevice] = []

        for connected in connectedDevices {
            if let index = devices.firstIndex(where: { $0.uid == connected.uid }) {
                devices[index].name = connected.name
                devices[index].transport = connected.transport
                devices[index].isVirtual = connected.isVirtual
                continue
            }

            let remembered = RememberedDevice(
                uid: connected.uid,
                name: connected.name,
                transport: connected.transport,
                isVirtual: connected.isVirtual,
                firstSeenOrdinal: nextOrdinal,
                defaultShortcutInstalled: false
            )
            nextOrdinal += 1
            devices.append(remembered)
            firstSeen.append(remembered)
        }

        devices.sort { $0.firstSeenOrdinal < $1.firstSeenOrdinal }
        return firstSeen
    }

    /// The default slot that should be installed for this device, if any.
    /// A device is offered a default shortcut only once; clearing the shortcut
    /// later must not cause it to be assigned again.
    func pendingDefaultShortcutSlot(forUID uid: String) -> Int? {
        guard let device = rememberedDevice(forUID: uid),
              !device.defaultShortcutInstalled,
              let slot = DefaultShortcutPolicy.slot(forFirstSeenOrdinal: device.firstSeenOrdinal)
        else {
            return nil
        }
        return slot
    }

    mutating func markDefaultShortcutInstalled(forUID uid: String) {
        guard let index = devices.firstIndex(where: { $0.uid == uid }) else { return }
        devices[index].defaultShortcutInstalled = true
    }

    mutating func forget(uid: String) {
        devices.removeAll { $0.uid == uid }
    }
}
