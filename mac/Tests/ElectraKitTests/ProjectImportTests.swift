import Testing
@testable import ElectraKit

@Suite struct ProjectImportTests {

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

    @Test func isProjectDetection() {
        #expect(PresetDocument.isProject(Self.eproj))
        #expect(!PresetDocument.isProject("{\"name\":\"p\",\"controls\":[]}"))
        #expect(!PresetDocument.isProject("not json"))
    }

    @Test func importConvertsTilesToControls() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        #expect(doc.name == "MyProj")
        // The label tile is a group separator, not a control.
        let controls = doc.allControls()
        #expect(controls.count == 2)
        #expect(Set(controls.map(\.id)) == [10, 11])
    }

    @Test func importPlacesFirstTileAtGridOrigin() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        let vol = doc.control(id: 10)!
        #expect(vol.type == "fader")
        #expect([vol.x, vol.y, vol.w, vol.h] == [20, 36, 175, 122])
        #expect(vol.controlSetId == 1)
        #expect(vol.potId == 1)
    }

    @Test func importExtractsLua() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        #expect(doc.lua == "function onReady() print('hi') end")
    }

    @Test func importEmitsLabelsAsGroupsNotControls() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        #expect(doc.jsonString().contains("Section"))  // label survives as a group
        // A label must never become a control (the firmware NACKs unknown types).
        #expect(!doc.allControls().contains { $0.name == "Section" })
    }

    @Test func importDoesNotLeakProjectKeys() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        let json = doc.jsonString()
        #expect(!json.contains("\"tiles\""))
        #expect(!json.contains("schemaVersion"))
    }

    @Test func importedPresetReparses() {
        let doc = PresetDocument.load(fileText: Self.eproj)!
        #expect(PresetDocument(jsonString: doc.jsonString()) != nil)
    }

    @Test func valuesGetDefaultValueId() {
        // The fader tile's value had no "id"; import should inject "value".
        let doc = PresetDocument.load(fileText: Self.eproj)!
        let vals = doc.controlValues(id: 10)
        #expect(vals.first?.valueId == "value")
        #expect(vals.first?.parameterNumber == 7)
    }

    @Test func plainPresetLoadsUnconverted() {
        let preset = "{\"name\":\"Plain\",\"controls\":[{\"id\":1,\"type\":\"fader\"}]}"
        let doc = PresetDocument.load(fileText: preset)
        #expect(doc?.name == "Plain")
        #expect(doc?.allControls().count == 1)
    }
}
