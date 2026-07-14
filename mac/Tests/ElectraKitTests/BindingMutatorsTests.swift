import XCTest
@testable import ElectraKit

/// P0/P1 document mutators: function, pot, onValue, devices, raw JSON.
final class BindingMutatorsTests: XCTestCase {
    private func sampleJSON() -> String {
        """
        {
          "version": 2,
          "name": "Test",
          "pages": [{"id": 1, "name": "P1"}],
          "devices": [{"id": 1, "name": "Dev", "port": 1, "channel": 1}],
          "controls": [{
            "id": 10,
            "type": "pad",
            "mode": "momentary",
            "name": "REC",
            "color": "FFFFFF",
            "bounds": [20, 20, 100, 60],
            "pageId": 1,
            "controlSetId": 1,
            "values": [{
              "id": "value",
              "function": "onRecord",
              "message": {
                "deviceId": 1,
                "type": "cc7",
                "parameterNumber": 40,
                "onValue": 127
              }
            }]
          }]
        }
        """
    }

    func testParseFunctionAndOnValue() throws {
        let doc = try XCTUnwrap(PresetDocument(jsonString: sampleJSON()))
        let c = try XCTUnwrap(doc.control(id: 10))
        XCTAssertEqual(c.functionName, "onRecord")
        XCTAssertEqual(c.onValue, 127)
        XCTAssertEqual(c.mode, "momentary")
        XCTAssertEqual(c.parameterNumber, 40)
    }

    func testSetFunctionNameAndPot() throws {
        var doc = try XCTUnwrap(PresetDocument(jsonString: sampleJSON()))
        doc.setFunctionName(id: 10, "onPlayStop")
        doc.setPotId(id: 10, 9)
        let c = try XCTUnwrap(doc.control(id: 10))
        XCTAssertEqual(c.functionName, "onPlayStop")
        XCTAssertEqual(c.potId, 9)

        doc.setFunctionName(id: 10, "  ")
        doc.setPotId(id: 10, nil)
        let c2 = try XCTUnwrap(doc.control(id: 10))
        XCTAssertNil(c2.functionName)
        XCTAssertNil(c2.potId)
    }

    func testSetOnOffAndMode() throws {
        var doc = try XCTUnwrap(PresetDocument(jsonString: sampleJSON()))
        doc.setOnValue(id: 10, 1)
        doc.setOffValue(id: 10, 0)
        doc.setControlMode(id: 10, "toggle")
        let c = try XCTUnwrap(doc.control(id: 10))
        XCTAssertEqual(c.onValue, 1)
        XCTAssertEqual(c.offValue, 0)
        XCTAssertEqual(c.mode, "toggle")
    }

    func testDeviceMutators() throws {
        var doc = try XCTUnwrap(PresetDocument(jsonString: sampleJSON()))
        doc.setDevicePort(id: 1, 2)
        doc.setDeviceChannel(id: 1, 5)
        doc.setDeviceName(id: 1, "EHX 95000")
        doc.setDeviceRate(id: 1, 15)
        let d = try XCTUnwrap(doc.devices.first)
        XCTAssertEqual(d.port, 2)
        XCTAssertEqual(d.channel, 5)
        XCTAssertEqual(d.name, "EHX 95000")
        XCTAssertEqual(d.rate, 15)
    }

    func testReplaceRootPreservesLua() throws {
        var doc = try XCTUnwrap(PresetDocument(jsonString: sampleJSON()))
        doc.lua = "print('hi')"
        let ok = doc.replaceRoot(fromJSON: sampleJSON().replacingOccurrences(of: "\"Test\"", with: "\"Renamed\""))
        XCTAssertTrue(ok)
        XCTAssertEqual(doc.name, "Renamed")
        XCTAssertEqual(doc.lua, "print('hi')")
    }

    func testAddPage() throws {
        var doc = try XCTUnwrap(PresetDocument(jsonString: sampleJSON()))
        let id = doc.addPage(name: "Modes")
        XCTAssertEqual(id, 2)
        XCTAssertEqual(doc.pages.count, 2)
        XCTAssertEqual(doc.pages.last?.name, "Modes")
    }

    func testRoundTripJSONKeepsFunction() throws {
        var doc = try XCTUnwrap(PresetDocument(jsonString: sampleJSON()))
        doc.setFunctionName(id: 10, "onTap")
        doc.setPotId(id: 10, 12)
        let out = doc.jsonString(pretty: false, forDevice: true)
        let again = try XCTUnwrap(PresetDocument(jsonString: out))
        let c = try XCTUnwrap(again.control(id: 10))
        XCTAssertEqual(c.functionName, "onTap")
        XCTAssertEqual(c.potId, 12)
    }
}
