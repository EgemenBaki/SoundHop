import AppKit
import KeyboardShortcuts
import XCTest
@testable import SoundHop

@MainActor
final class DeviceShortcutTests: XCTestCase {
    func testShortcutNameIsDeterministicAndContainsNoDot() {
        let uid = "Egemen adlı kişiye ait Buds2:output"
        let first = DeviceShortcutName.rawValue(forUID: uid)
        let second = DeviceShortcutName.rawValue(forUID: uid)

        XCTAssertEqual(first, second)
        XCTAssertFalse(first.contains("."))
        XCTAssertTrue(first.hasPrefix("soundhop_device_"))
        XCTAssertNotEqual(first, DeviceShortcutName.rawValue(forUID: "BuiltInSpeakerDevice"))
    }

    func testShortcutNamesAreUniqueForCollidingLookingUIDs() {
        let uids = [
            "a:b",
            "a-b",
            "a.b",
            "a/b",
            "A:B"
        ]
        let names = Set(uids.map(DeviceShortcutName.rawValue(forUID:)))

        XCTAssertEqual(names.count, uids.count)
    }

    func testDefaultShortcutsAreControlCommandOneThroughNine() {
        let expectedKeys: [KeyboardShortcuts.Key] = [
            .one, .two, .three, .four, .five, .six, .seven, .eight, .nine
        ]

        for (slot, key) in expectedKeys.enumerated() {
            let shortcut = DeviceShortcuts.defaultShortcut(forSlot: slot)
            XCTAssertEqual(shortcut?.key, key)
            XCTAssertEqual(shortcut?.modifiers, [.control, .command])
        }

        XCTAssertNil(DeviceShortcuts.defaultShortcut(forSlot: -1))
        XCTAssertNil(DeviceShortcuts.defaultShortcut(forSlot: 9))
    }

    func testDefaultSlotPolicyMatchesShortcutKeys() {
        XCTAssertEqual(DefaultShortcutPolicy.maximumShortcuts, 9)

        for ordinal in 0..<9 {
            let slot = DefaultShortcutPolicy.slot(forFirstSeenOrdinal: ordinal)
            XCTAssertEqual(slot, ordinal)
            XCTAssertNotNil(slot.flatMap(DeviceShortcuts.defaultShortcut(forSlot:)))
        }

        XCTAssertNil(DefaultShortcutPolicy.slot(forFirstSeenOrdinal: 9))
    }

    func testChangingShortcutDoesNotChangeTheDeviceIdentity() {
        let uid = "device-uid-with-ünïcode:output"
        let nameBefore = DeviceShortcuts.name(forUID: uid)
        let newShortcut = KeyboardShortcuts.Shortcut(.seven, modifiers: [.option, .command])

        KeyboardShortcuts.setShortcut(newShortcut, for: nameBefore)
        defer { KeyboardShortcuts.setShortcut(nil, for: nameBefore) }

        let nameAfter = DeviceShortcuts.name(forUID: uid)
        XCTAssertEqual(nameBefore, nameAfter)
        XCTAssertEqual(KeyboardShortcuts.getShortcut(for: nameAfter), newShortcut)
    }
}
