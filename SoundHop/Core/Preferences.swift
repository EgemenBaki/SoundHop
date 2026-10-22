import Foundation

/// UserDefaults-backed preferences. The Settings UI will bind to the same keys.
enum Preferences {
    enum Key {
        static let moveAlertSounds = "soundhop.moveAlertSounds"
        static let showHUD = "soundhop.showHUD"
        static let launchAtLogin = "soundhop.launchAtLogin"
    }

    static var moveAlertSounds: Bool {
        if UserDefaults.standard.object(forKey: Key.moveAlertSounds) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: Key.moveAlertSounds)
    }

    static var showHUD: Bool {
        if UserDefaults.standard.object(forKey: Key.showHUD) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: Key.showHUD)
    }
}
