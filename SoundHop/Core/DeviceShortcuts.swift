import AppKit
import KeyboardShortcuts

enum DeviceShortcuts {
    static func name(forUID uid: String) -> KeyboardShortcuts.Name {
        KeyboardShortcuts.Name(DeviceShortcutName.rawValue(forUID: uid))
    }

    /// Control+Command+1 through Control+Command+9.
    static func defaultShortcut(forSlot slot: Int) -> KeyboardShortcuts.Shortcut? {
        let keys: [KeyboardShortcuts.Key] = [
            .one, .two, .three, .four, .five, .six, .seven, .eight, .nine
        ]
        guard keys.indices.contains(slot) else { return nil }
        return KeyboardShortcuts.Shortcut(
            keys[slot],
            modifiers: [.control, .command]
        )
    }

    @MainActor
    static func currentShortcut(forUID uid: String) -> KeyboardShortcuts.Shortcut? {
        KeyboardShortcuts.getShortcut(for: name(forUID: uid))
    }
}
