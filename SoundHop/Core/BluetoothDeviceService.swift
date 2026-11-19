import Foundation
import IOBluetooth
import IOKit

/// A paired Bluetooth device that is a candidate for audio output.
struct PairedBluetoothDevice: Identifiable, Hashable, Sendable {
    let address: BluetoothAddress
    let name: String
    let isConnected: Bool

    var id: String { address.digits }
}

/// Thin wrapper around the classic Bluetooth stack.
///
/// Core Audio has no API for connecting a Bluetooth device; the HAL only lists
/// devices that are already connected. IOBluetooth is the public way to open
/// and close the underlying connection.
struct BluetoothDeviceService: Sendable {
    private static let audioDeviceClassMajor: UInt32 = UInt32(kBluetoothDeviceClassMajorAudio)

    /// Paired devices whose class of device is audio/video. Disconnected
    /// devices are listed first so the menu puts the actionable items on top.
    func pairedAudioDevices() -> [PairedBluetoothDevice] {
        let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []

        return devices
            .compactMap { device in
                guard device.deviceClassMajor == Self.audioDeviceClassMajor,
                      let addressString = device.addressString,
                      let address = BluetoothAddress(addressString)
                else {
                    return nil
                }
                return PairedBluetoothDevice(
                    address: address,
                    name: device.name ?? addressString,
                    isConnected: device.isConnected()
                )
            }
            .sorted { lhs, rhs in
                if lhs.isConnected != rhs.isConnected {
                    return !lhs.isConnected
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    /// Opens the baseband connection. This call blocks until the device
    /// answers or the stack gives up, so it must not run on the main thread.
    @discardableResult
    func connect(_ address: BluetoothAddress) -> Bool {
        guard let device = IOBluetoothDevice(addressString: address.ioBluetoothString) else {
            return false
        }
        if device.isConnected() { return true }
        return device.openConnection() == kIOReturnSuccess
    }

    /// Closes the baseband connection. Also blocking.
    @discardableResult
    func disconnect(_ address: BluetoothAddress) -> Bool {
        guard let device = IOBluetoothDevice(addressString: address.ioBluetoothString) else {
            return false
        }
        if !device.isConnected() { return true }
        return device.closeConnection() == kIOReturnSuccess
    }
}
