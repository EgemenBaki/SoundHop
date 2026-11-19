import XCTest
@testable import SoundHop

final class BluetoothAddressTests: XCTestCase {
    func testAudioDeviceUIDIsParsedIntoTheSameAddressAsIOBluetooth() {
        let fromCoreAudio = BluetoothAddress(audioDeviceUID: "60-3A-AF-FD-9F-F0:output")
        let fromIOBluetooth = BluetoothAddress("60-3a-af-fd-9f-f0")

        XCTAssertEqual(fromCoreAudio, fromIOBluetooth)
        XCTAssertEqual(fromCoreAudio?.digits, "603aaffd9ff0")
        XCTAssertEqual(fromCoreAudio?.ioBluetoothString, "60-3a-af-fd-9f-f0")
    }

    func testSeparatorsAreAcceptedInAnyForm() {
        let expected = BluetoothAddress("603aaffd9ff0")
        XCTAssertEqual(BluetoothAddress("60:3A:AF:FD:9F:F0"), expected)
        XCTAssertEqual(BluetoothAddress("60 3a af fd 9f f0"), expected)
    }

    func testMalformedAddressesAreRejected() {
        XCTAssertNil(BluetoothAddress("60-3a-af-fd-9f"))
        XCTAssertNil(BluetoothAddress("60-3a-af-fd-9f-f0-aa"))
        XCTAssertNil(BluetoothAddress("not an address"))
        XCTAssertNil(BluetoothAddress(audioDeviceUID: "60-3A-AF-FD-9F-F0:input"))
        XCTAssertNil(BluetoothAddress(audioDeviceUID: "MacBook Pro Speakers"))
        XCTAssertNil(BluetoothAddress(audioDeviceUID: ":output"))
    }

    func testOnlyBluetoothAudioDevicesExposeAnAddress() {
        let bluetooth = AudioDevice(
            uid: "60-3A-AF-FD-9F-F0:output",
            name: "Buds2",
            transport: .bluetooth,
            isVirtual: false
        )
        let usb = AudioDevice(
            uid: "AppleUSBAudioEngine:USB:output",
            name: "Interface",
            transport: .usb,
            isVirtual: false
        )

        XCTAssertEqual(bluetooth.bluetoothAddress?.digits, "603aaffd9ff0")
        XCTAssertNil(usb.bluetoothAddress)
    }
}
