import CoreAudio
import Foundation

/// A thin, UI-free wrapper around the Core Audio HAL.
///
/// All device identity is expressed as a persistent device UID. Names are
/// display-only and must never be used to match a device.
struct AudioDeviceService: Sendable {
    enum ServiceError: LocalizedError {
        case propertyReadFailed(selector: String, status: OSStatus)
        case propertyWriteFailed(selector: String, status: OSStatus)
        case deviceNotFound(uid: String)

        var errorDescription: String? {
            switch self {
            case let .propertyReadFailed(selector, status):
                return "Could not read \(selector) (error \(status))."
            case let .propertyWriteFailed(selector, status):
                return "Could not write \(selector) (error \(status))."
            case let .deviceNotFound(uid):
                return "No connected output device has UID \(uid)."
            }
        }
    }

    struct SwitchVerification: Sendable, Equatable {
        let expectedUID: String
        let actualUID: String?
        let didStick: Bool
    }

    private static let systemObject = AudioObjectID(kAudioObjectSystemObject)

    // MARK: - Reading

    func outputDevices() throws -> [AudioDevice] {
        let deviceIDs = try deviceIDs()
        var devices: [AudioDevice] = []
        devices.reserveCapacity(deviceIDs.count)

        for deviceID in deviceIDs {
            guard hasOutputStreams(deviceID) else { continue }
            guard let uid = stringProperty(deviceID, selector: kAudioDevicePropertyDeviceUID),
                  let name = stringProperty(deviceID, selector: kAudioObjectPropertyName),
                  !uid.isEmpty
            else {
                continue
            }

            let transportCode = uint32Property(deviceID, selector: kAudioDevicePropertyTransportType) ?? 0
            let transport = Self.transport(for: transportCode)
            devices.append(
                AudioDevice(
                    uid: uid,
                    name: name,
                    transport: transport,
                    isVirtual: transport == .aggregate || transport == .virtual
                )
            )
        }

        return devices.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func defaultOutputDeviceUID() throws -> String? {
        let deviceID = try defaultDeviceID(selector: kAudioHardwarePropertyDefaultOutputDevice)
        guard deviceID != kAudioObjectUnknown else { return nil }
        return stringProperty(deviceID, selector: kAudioDevicePropertyDeviceUID)
    }

    func defaultSystemOutputDeviceUID() throws -> String? {
        let deviceID = try defaultDeviceID(selector: kAudioHardwarePropertyDefaultSystemOutputDevice)
        guard deviceID != kAudioObjectUnknown else { return nil }
        return stringProperty(deviceID, selector: kAudioDevicePropertyDeviceUID)
    }

    // MARK: - Writing

    /// Sets the default output device identified by `uid`.
    ///
    /// Core Audio can accept the write and then immediately revert it (most
    /// commonly with Bluetooth devices that are moving between hosts), so the
    /// result is verified by reading the default device back.
    @discardableResult
    func setDefaultOutput(uid: String, moveSystemOutput: Bool) throws -> SwitchVerification {
        guard let deviceID = try deviceID(forUID: uid) else {
            throw ServiceError.deviceNotFound(uid: uid)
        }

        try setSystemDevice(
            deviceID,
            selector: kAudioHardwarePropertyDefaultOutputDevice
        )

        if moveSystemOutput {
            try setSystemDevice(
                deviceID,
                selector: kAudioHardwarePropertyDefaultSystemOutputDevice
            )
        }

        let actualUID = try defaultOutputDeviceUID()
        return SwitchVerification(
            expectedUID: uid,
            actualUID: actualUID,
            didStick: actualUID == uid
        )
    }

    // MARK: - Core Audio helpers

    private func deviceIDs() throws -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            Self.systemObject,
            &address,
            0,
            nil,
            &dataSize
        )
        guard status == noErr else {
            throw ServiceError.propertyReadFailed(
                selector: "device list size",
                status: status
            )
        }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        guard count > 0 else { return [] }

        var ids = [AudioDeviceID](repeating: kAudioObjectUnknown, count: count)
        status = AudioObjectGetPropertyData(
            Self.systemObject,
            &address,
            0,
            nil,
            &dataSize,
            &ids
        )
        guard status == noErr else {
            throw ServiceError.propertyReadFailed(
                selector: "device list",
                status: status
            )
        }
        return ids
    }

    private func hasOutputStreams(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &dataSize
        )
        return status == noErr && dataSize >= UInt32(MemoryLayout<AudioStreamID>.size)
    }

    private func deviceID(forUID uid: String) throws -> AudioDeviceID? {
        for deviceID in try deviceIDs() where hasOutputStreams(deviceID) {
            if stringProperty(deviceID, selector: kAudioDevicePropertyDeviceUID) == uid {
                return deviceID
            }
        }
        return nil
    }

    private func stringProperty(
        _ objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(
            objectID,
            &address,
            0,
            nil,
            &dataSize,
            &value
        )
        guard status == noErr, let value else { return nil }
        return value.takeUnretainedValue() as String
    }

    private func uint32Property(
        _ objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(
            objectID,
            &address,
            0,
            nil,
            &dataSize,
            &value
        )
        return status == noErr ? value : nil
    }

    private func defaultDeviceID(
        selector: AudioObjectPropertySelector
    ) throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: AudioDeviceID = kAudioObjectUnknown
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            Self.systemObject,
            &address,
            0,
            nil,
            &dataSize,
            &value
        )
        guard status == noErr else {
            throw ServiceError.propertyReadFailed(
                selector: Self.selectorName(selector),
                status: status
            )
        }
        return value
    }

    private func setSystemDevice(
        _ deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector
    ) throws {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value = deviceID
        let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectSetPropertyData(
            Self.systemObject,
            &address,
            0,
            nil,
            dataSize,
            &value
        )
        guard status == noErr else {
            throw ServiceError.propertyWriteFailed(
                selector: Self.selectorName(selector),
                status: status
            )
        }
    }

    private static func selectorName(_ selector: AudioObjectPropertySelector) -> String {
        switch selector {
        case kAudioHardwarePropertyDefaultOutputDevice: "default output device"
        case kAudioHardwarePropertyDefaultSystemOutputDevice: "default system output device"
        case kAudioHardwarePropertyDevices: "device list"
        default: "Core Audio property \(selector)"
        }
    }

    private static func transport(for code: UInt32) -> AudioDeviceTransport {
        switch code {
        case kAudioDeviceTransportTypeBuiltIn: .builtIn
        case kAudioDeviceTransportTypeBluetooth: .bluetooth
        case kAudioDeviceTransportTypeBluetoothLE: .bluetoothLE
        case kAudioDeviceTransportTypeUSB: .usb
        case kAudioDeviceTransportTypeHDMI: .hdmi
        case kAudioDeviceTransportTypeDisplayPort: .displayPort
        case kAudioDeviceTransportTypeAirPlay: .airPlay
        case kAudioDeviceTransportTypeThunderbolt: .thunderbolt
        case kAudioDeviceTransportTypeFireWire: .fireWire
        case kAudioDeviceTransportTypePCI: .pci
        case kAudioDeviceTransportTypeAggregate: .aggregate
        case kAudioDeviceTransportTypeVirtual: .virtual
        case kAudioDeviceTransportTypeAVB: .avb
        case kAudioDeviceTransportTypeContinuityCaptureWired: .continuity
        case kAudioDeviceTransportTypeContinuityCaptureWireless: .continuity
        default: .unknown
        }
    }
}
