import XCTest
@testable import SoundHop

@MainActor
final class DeviceLibraryTests: XCTestCase {
    func testReconcileMatchesByUIDAndNotName() {
        var library = DeviceLibrary()

        let first = AudioDevice(
            uid: "uid-a",
            name: "Shared Name",
            transport: .bluetooth,
            isVirtual: false
        )
        let second = AudioDevice(
            uid: "uid-b",
            name: "Shared Name",
            transport: .usb,
            isVirtual: false
        )

        XCTAssertEqual(library.reconcile(with: [first, second]).count, 2)
        XCTAssertEqual(library.devices.map(\.uid), ["uid-a", "uid-b"])

        let renamed = AudioDevice(
            uid: "uid-a",
            name: "Renamed Device",
            transport: .builtIn,
            isVirtual: false
        )

        XCTAssertTrue(library.reconcile(with: [renamed]).isEmpty)
        XCTAssertEqual(library.devices.count, 2)
        XCTAssertEqual(library.rememberedDevice(forUID: "uid-a")?.name, "Renamed Device")
        XCTAssertEqual(library.rememberedDevice(forUID: "uid-a")?.transport, .builtIn)
    }

    func testFirstSeenOrdinalsFollowDiscoveryOrderAndSurviveReordering() {
        var library = DeviceLibrary()
        let a = device(uid: "a", name: "A")
        let b = device(uid: "b", name: "B")
        let c = device(uid: "c", name: "C")

        _ = library.reconcile(with: [b, a])
        XCTAssertEqual(library.rememberedDevice(forUID: "b")?.firstSeenOrdinal, 0)
        XCTAssertEqual(library.rememberedDevice(forUID: "a")?.firstSeenOrdinal, 1)

        _ = library.reconcile(with: [a, b, c])
        XCTAssertEqual(library.rememberedDevice(forUID: "a")?.firstSeenOrdinal, 1)
        XCTAssertEqual(library.rememberedDevice(forUID: "b")?.firstSeenOrdinal, 0)
        XCTAssertEqual(library.rememberedDevice(forUID: "c")?.firstSeenOrdinal, 2)
        XCTAssertEqual(library.devices.map(\.uid), ["b", "a", "c"])
    }

    func testDisconnectedDeviceStaysRemembered() {
        var library = DeviceLibrary()
        let a = device(uid: "a", name: "A")
        let b = device(uid: "b", name: "B")

        _ = library.reconcile(with: [a, b])
        _ = library.reconcile(with: [b])

        XCTAssertEqual(library.devices.map(\.uid), ["a", "b"])
        XCTAssertEqual(library.rememberedDevice(forUID: "a")?.name, "A")
    }

    func testOnlyFirstNineDevicesGetAPendingDefaultShortcut() {
        var library = DeviceLibrary()
        let devices = (0..<10).map { device(uid: "uid-\($0)", name: "Device \($0)") }

        let firstSeen = library.reconcile(with: devices)
        XCTAssertEqual(firstSeen.count, 10)

        for (ordinal, device) in firstSeen.enumerated() {
            XCTAssertEqual(
                library.pendingDefaultShortcutSlot(forUID: device.uid),
                ordinal < 9 ? ordinal : nil
            )
        }
    }

    func testDefaultShortcutIsOfferedOnlyOnce() {
        var library = DeviceLibrary()
        let device = device(uid: "a", name: "A")
        _ = library.reconcile(with: [device])

        XCTAssertEqual(library.pendingDefaultShortcutSlot(forUID: "a"), 0)
        library.markDefaultShortcutInstalled(forUID: "a")
        XCTAssertNil(library.pendingDefaultShortcutSlot(forUID: "a"))
    }

    func testForgetRemovesOnlyTheRequestedUID() {
        var library = DeviceLibrary()
        _ = library.reconcile(with: [device(uid: "a", name: "A"), device(uid: "b", name: "B")])

        library.forget(uid: "a")

        XCTAssertNil(library.rememberedDevice(forUID: "a"))
        XCTAssertNotNil(library.rememberedDevice(forUID: "b"))
    }

    func testLibraryRoundTripsThroughUserDefaults() {
        let suiteName = "SoundHopTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var library = DeviceLibrary()
        _ = library.reconcile(with: [device(uid: "a", name: "Ä"), device(uid: "b", name: "B")])
        library.markDefaultShortcutInstalled(forUID: "a")

        let storage = DeviceLibraryStorage(defaults: defaults, key: "test-library")
        storage.save(library)

        XCTAssertEqual(storage.load(), library)
    }

    private func device(uid: String, name: String) -> AudioDevice {
        AudioDevice(uid: uid, name: name, transport: .usb, isVirtual: false)
    }
}
