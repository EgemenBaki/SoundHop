import Foundation

extension AudioDeviceTransport {
    /// SF Symbol used in the menu, Settings and HUD.
    var symbolName: String {
        switch self {
        case .builtIn: "laptopcomputer"
        case .bluetooth, .bluetoothLE: "headphones"
        case .usb: "cable.connector"
        case .hdmi, .displayPort: "display"
        case .airPlay: "airplayaudio"
        case .thunderbolt: "bolt"
        case .fireWire, .pci: "cpu"
        case .aggregate: "square.stack.3d.up"
        case .virtual: "waveform"
        case .continuity: "iphone"
        case .avb: "network"
        case .unknown: "hifispeaker"
        }
    }
}

extension DeviceActionFeedback {
    var hudText: String {
        kind == .switched ? deviceName : message
    }

    var hudSymbolName: String {
        switch kind {
        case .switched: transport.symbolName
        case .notConnected: "wifi.slash"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    var isError: Bool {
        kind != .switched
    }
}
