import Foundation

/// Encodes a device UID into a shortcut name that is safe for
/// `KeyboardShortcuts.Name`. Names must not contain a dot, and UIDs can
/// contain almost anything (including dots and non-ASCII characters).
enum DeviceShortcutName {
    static func rawValue(forUID uid: String) -> String {
        let encoded = Data(uid.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "soundhop_device_\(encoded)"
    }
}

struct DeviceLibraryStorage {
    static let defaultKey = "soundhop.deviceLibrary.v1"

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = Self.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    func load() -> DeviceLibrary {
        guard let data = defaults.data(forKey: key),
              let library = try? JSONDecoder().decode(DeviceLibrary.self, from: data)
        else {
            return DeviceLibrary()
        }
        return library
    }

    func save(_ library: DeviceLibrary) {
        guard let data = try? JSONEncoder().encode(library) else { return }
        defaults.set(data, forKey: key)
    }
}
