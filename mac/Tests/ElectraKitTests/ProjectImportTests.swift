import XCTest
import Foundation
@testable import ElectraKit

final class ProjectImportTests: XCTestCase {

    /// A tiny `.eproj` web-editor project: two real tiles plus a `label`
    /// separator, an embedded Lua script, and a `schemaVersion` marker.
    static let eproj = """
    {
      "schemaVersion": 2,
      "id": "proj123",
      "name": "MyProj",
      "pages": [{"id": 1, "name": "P1"}],
      "devices": [{"id": 1, "name": "Dev", "port": 1, "channel": 1}],
      "lua": "function onReady() print('hi') end",
      "tiles": [
        {"slotId": 0, "reference": 10, "type": "fader", "name": "Vol",
         "values": [{"message": {"type": "cc7", "parameterNumber": 7}}]},
        {"slotId": 1, "reference": 11, "type": "list", "name": "Algo"},
        {"slotId": 2, "type": "label", "name": "Section", "span": 2}
      ]
    }
    """

    func test_isProjectDetection() {
        XCTAssert(PresetDocument.isProject(Self.eproj))
        XCTAssert(!PresetDocument.isProject("{\"name\":\"p\",\"controls\":[]}"))
        XCTAssert(!PresetDocument.isProject("not json"))
    }

    func test_importConvertsTilesToControls() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        XCTAssertEqual(doc.name, "MyProj")
        // The label tile is a group separator, not a control.
        let controls = doc.allControls()
        XCTAssertEqual(controls.count, 2)
        XCTAssertEqual(Set(controls.map(\.id)), [10, 11])
    }

    func test_importPlacesFirstTileAtGridOrigin() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        let vol = doc.control(id: 10)!
        XCTAssertEqual(vol.type, "fader")
        XCTAssertEqual([vol.x, vol.y, vol.w, vol.h], [20, 36, 175, 122])
        XCTAssertEqual(vol.controlSetId, 1)
        XCTAssertEqual(vol.potId, 1)
    }

    func test_importExtractsLua() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        XCTAssertEqual(doc.lua, "function onReady() print('hi') end")
    }

    func test_importEmitsLabelsAsGroupsNotControls() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        XCTAssert(doc.jsonString().contains("Section"))  // label survives as a group
        // A label must never become a control (the firmware NACKs unknown types).
        XCTAssertEqual(!doc.allControls().contains { $0.name, "Section" })
    }

    func test_importDoesNotLeakProjectKeys() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        let json = doc.jsonString()
        XCTAssert(!json.contains("\"tiles\""))
        XCTAssert(!json.contains("schemaVersion"))
    }

    func test_importedPresetReparses() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        XCTAssertNotEqual(PresetDocument(jsonString: doc.jsonString()), nil)
    }

    func test_valuesGetDefaultValueId() {
        // The fader tile's value had no "id"; import should inject "value".
        let doc = PresetDocument.load(fileText: Self.eproj)!
        let vals = doc.controlValues(id: 10)
        XCTAssertEqual(vals.first?.valueId, "value")
        XCTAssertEqual(vals.first?.parameterNumber, 7)
    }

    func test_labelSpanWidthIncludesInterSlotGap() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        let groups = doc.root["groups"] as? [[String: Any]] ?? []
        let section = groups.first { ($0["name"] as? String) == "Section" }
        let bounds = section?["bounds"] as? [Int]
        // span 2 → slotWidth + 1×pitchX = 175 + 196, not 2×175.
        XCTAssertEqual(bounds?[2], 371)
    }

    func test_fallbackReferenceIdsDoNotCollide() {
        // Tile B has no explicit `reference`; its fallback id must be allocated
        // above the highest explicit one (2), never colliding with it.
        let proj = """
        {"schemaVersion": 2, "name": "P",
         "tiles": [
           {"slotId": 0, "reference": 2, "type": "fader", "name": "A"},
           {"slotId": 1, "type": "fader", "name": "B"},
           {"slotId": 2, "type": "fader", "name": "C"}
         ]}
        """
        let doc = PresetDocument.load(fileText: proj)!
        let ids = doc.allControls().map(\.id)
        XCTAssertEqual(ids.count, 3)
        XCTAssertEqual(Set(ids).count, ids.count)   // all unique
        XCTAssert(ids.contains(2))               // explicit id preserved
    }

    func test_plainPresetLoadsUnconverted() {
        let preset = "{\"name\":\"Plain\",\"controls\":[{\"id\":1,\"type\":\"fader\"}]}"
        let doc = PresetDocument.load(fileText: preset)
        XCTAssertEqual(doc?.name, "Plain")
        XCTAssertEqual(doc?.allControls().count, 1)
    }
}
