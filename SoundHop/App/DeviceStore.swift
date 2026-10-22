import Foundation

@MainActor
final class DeviceStore: ObservableObject {
    @Published private(set) var devices: [AudioDevice] = []
    @Published private(set) var defaultOutputUID: String?
    @Published private(set) var defaultSystemOutputUID: String?
    @Published private(set) var lastError: String?

    private let service = AudioDeviceService()

    init() {
        refresh()
    }

    func refresh() {
        do {
            devices = try service.outputDevices()
            defaultOutputUID = try service.defaultOutputDeviceUID()
            defaultSystemOutputUID = try service.defaultSystemOutputDeviceUID()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func switchOutput(to device: AudioDevice) {
        do {
            let result = try service.setDefaultOutput(
                uid: device.uid,
                moveSystemOutput: false
            )
            refresh()
            if !result.didStick {
                lastError = "Couldn't switch to \(device.name)."
            }
        } catch {
            refresh()
            lastError = error.localizedDescription
        }
    }
}
