import Foundation

/// A sound output device as exposed by Core Audio.
///
/// `uid` is the device's `kAudioDevicePropertyDeviceUID`. It is the only
/// stable identifier used by SoundHop; display names can change and collide.
struct AudioDevice: Identifiable, Hashable, Sendable {
    let uid: String
    let name: String
    let transport: AudioDeviceTransport
    let isVirtual: Bool

    var id: String { uid }
}

enum AudioDeviceTransport: String, Codable, Sendable {
    case builtIn
    case bluetooth
    case bluetoothLE
    case usb
    case hdmi
    case displayPort
    case airPlay
    case thunderbolt
    case fireWire
    case pci
    case aggregate
    case virtual
    case avb
    case continuity
    case unknown

    var displayName: String {
        switch self {
        case .builtIn: "Built-in"
        case .bluetooth, .bluetoothLE: "Bluetooth"
        case .usb: "USB"
        case .hdmi: "HDMI"
        case .displayPort: "DisplayPort"
        case .airPlay: "AirPlay"
        case .thunderbolt: "Thunderbolt"
        case .fireWire: "FireWire"
        case .pci: "PCI"
        case .aggregate: "Aggregate"
        case .virtual: "Virtual"
        case .avb: "AVB"
        case .continuity: "Continuity"
        case .unknown: "Unknown"
        }
    }
}
