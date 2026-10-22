import AppKit
import Foundation
import KeyboardShortcuts

/// Temporary launch-argument harness for the sandbox spike.
///
/// The same signed, sandboxed app can be launched from Terminal:
///   SoundHop --spike-list
///   SoundHop --spike-switch <device-uid>
///
/// This lets us verify HAL access without needing to drive the menu bar. It
/// will be removed once the spike is confirmed.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let command = SpikeCommand(arguments: CommandLine.arguments) else {
            return
        }

        switch command {
        case .list:
            listDevices()
        case let .switchTo(uid, moveSystemOutput):
            switchOutput(to: uid, moveSystemOutput: moveSystemOutput)
        case .shortcuts:
            listShortcuts()
        case .watch:
            watchDeviceChanges()
        }

        exit(EXIT_SUCCESS)
    }

    private func listDevices() {
        let service = AudioDeviceService()
        print("SoundHop sandbox spike")
        print("home: \(NSHomeDirectory())")
        let container = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"]
        print("sandbox container: \(container ?? "not set")")
        print("")

        do {
            let defaultUID = try service.defaultOutputDeviceUID()
            let systemUID = try service.defaultSystemOutputDeviceUID()
            print("default output uid: \(defaultUID ?? "none")")
            print("default system output uid: \(systemUID ?? "none")")
            print("")

            let devices = try service.outputDevices()
            print("output devices (\(devices.count)):")
            for device in devices {
                let marker = device.uid == defaultUID ? "*" : " "
                let virtual = device.isVirtual ? " [virtual]" : ""
                print("\(marker) \(device.name) | \(device.transport.displayName)\(virtual) | \(device.uid)")
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        }
    }

    private func watchDeviceChanges() {
        let monitor = AudioDeviceMonitor {
            print("HAL change received at \(Date())")
        }
        monitor.start()
        print("watching HAL for 5 seconds")
        RunLoop.main.run(until: Date().addingTimeInterval(5))
        monitor.stop()
    }

    private func listShortcuts() {
        let store = DeviceStore()
        print("remembered devices (\(store.rememberedDevices.count)):")
        for device in store.rememberedDevices {
            let name = DeviceShortcuts.name(forUID: device.uid)
            let shortcut = KeyboardShortcuts.getShortcut(for: name)
            let isEnabled = KeyboardShortcuts.isEnabled(for: name)
            print("- \(device.name) | ordinal \(device.firstSeenOrdinal) | connected: \(store.isConnected(device.uid)) | shortcut: \(shortcut?.description ?? "none") | enabled: \(isEnabled)")
        }
    }

    private func switchOutput(to uid: String, moveSystemOutput: Bool) {
        let service = AudioDeviceService()
        do {
            let before = try service.defaultOutputDeviceUID()
            print("before: \(before ?? "none")")
            let result = try service.setDefaultOutput(
                uid: uid,
                moveSystemOutput: moveSystemOutput
            )
            print("requested: \(uid)")
            print("move system output: \(moveSystemOutput ? "yes" : "no")")
            print("actual: \(result.actualUID ?? "none")")
            print("did stick: \(result.didStick ? "yes" : "no")")
            if moveSystemOutput {
                print("system output now: \(try service.defaultSystemOutputDeviceUID() ?? "none")")
            }
            if !result.didStick {
                exit(EXIT_FAILURE)
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        }
    }
}

private enum SpikeCommand {
    case list
    case switchTo(uid: String, moveSystemOutput: Bool)
    case shortcuts
    case watch

    init?(arguments: [String]) {
        guard arguments.count >= 2 else { return nil }

        switch arguments[1] {
        case "--spike-list":
            self = .list
        case "--spike-shortcuts":
            self = .shortcuts
        case "--spike-watch":
            self = .watch
        case "--spike-switch" where arguments.count >= 3:
            self = .switchTo(
                uid: arguments[2],
                moveSystemOutput: arguments.contains("--also-system")
            )
        default:
            return nil
        }
    }
}
