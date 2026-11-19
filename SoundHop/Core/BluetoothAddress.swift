import Foundation

/// A classic Bluetooth device address in a comparable form.
///
/// IOBluetooth and Core Audio spell the same address differently
/// (`60-3a-af-fd-9f-f0` vs. `60-3A-AF-FD-9F-F0:output`), so every address that
/// enters SoundHop is normalized to twelve lowercase hex digits.
struct BluetoothAddress: Hashable, Sendable {
    /// Twelve lowercase hexadecimal digits without separators.
    let digits: String

    init?(digits: String) {
        guard digits.count == 12, digits.allSatisfy(\.isHexDigit) else { return nil }
        self.digits = digits.lowercased()
    }

    init?(_ text: String) {
        let separators: Set<Character> = ["-", ":", " "]
        guard text.allSatisfy({ $0.isHexDigit || separators.contains($0) }) else {
            return nil
        }
        self.init(digits: String(text.filter(\.isHexDigit)))
    }

    /// The Core Audio HAL names Bluetooth endpoints `<address>:output`.
    init?(audioDeviceUID uid: String) {
        let suffix = ":output"
        guard uid.hasSuffix(suffix) else { return nil }
        self.init(String(uid.dropLast(suffix.count)))
    }

    /// The hyphenated form `IOBluetoothDevice(addressString:)` expects.
    var ioBluetoothString: String {
        var parts: [String] = []
        parts.reserveCapacity(6)

        var index = digits.startIndex
        while index < digits.endIndex {
            let next = digits.index(index, offsetBy: 2)
            parts.append(String(digits[index..<next]))
            index = next
        }
        return parts.joined(separator: "-")
    }
}

extension AudioDevice {
    var bluetoothAddress: BluetoothAddress? {
        guard transport == .bluetooth else { return nil }
        return BluetoothAddress(audioDeviceUID: uid)
    }
}

extension RememberedDevice {
    var bluetoothAddress: BluetoothAddress? {
        guard transport == .bluetooth else { return nil }
        return BluetoothAddress(audioDeviceUID: uid)
    }
}
