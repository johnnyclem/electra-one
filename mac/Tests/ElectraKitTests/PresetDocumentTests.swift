import Testing
import Foundation
@testable import ElectraKit

@Suite struct PresetDocumentTests {

    /// A minimal but realistic device preset with two controls.
    static let presetJSON = """
    {
      "version": 2,
      "name": "Demo",
      "projectId": "abc123",
      "pages": [{"id": 1, "name": "Main"}, {"id": 2, "name": "Two"}],
      "devices": [{"id": 1, "name": "Synth", "port": 1, "channel": 1}],
      "groups": [],
      "overlays": [],
      "controls": [
        {"id": 1, "type": "fader", "name": "Cutoff", "color": "F45C51",
         "bounds": [20, 36, 175, 122], "pageId": 1, "controlSetId": 1,
         "inputs": [{"potId": 1, "valueId": "value"}],
         "values": [{"id": "value", "message": {"type": "cc7", "parameterNumber": 74, "min": 0, "max": 127, "deviceId": 1}}]},
        {"id": 2, "type": "fader", "variant": "dial", "name": "Res", "color": "529DEC",
         "bounds": [216, 36, 175, 122], "pageId": 2, "controlSetId": 1,
         "inputs": [{"potId": 2, "valueId": "value"}],
         "values": [{"id": "value", "message": {"type": "cc7", "parameterNumber": 71, "min": 0, "max": 127, "deviceId": 1}}]}
      ]
    }
    """

    func makeDoc() -> PresetDocument {
        guard let doc = PresetDocument(jsonString: Self.presetJSON) else {
            fatalError("fixture JSON failed to parse")
        }
        return doc
    }

    @Test func parseTopLevel() {
        let doc = makeDoc()
        #expect(doc.name == "Demo")
        #expect(doc.version == 2)
        #expect(doc.projectId == "abc123")
        #expect(doc.pages.map(\.id) == [1, 2])
        #expect(doc.deviceNames == ["Synth"])
        #expect(doc.allControls().count == 2)
    }

    @Test func rejectsInvalidJSON() {
        #expect(PresetDocument(jsonString: "{ not json") == nil)
        #expect(PresetDocument(jsonString: "[1,2,3]") == nil)  // array, not an object
    }

    @Test func controlParsingAndKind() {
        let doc = makeDoc()
        let cutoff = doc.control(id: 1)!
        #expect(cutoff.name == "Cutoff")
        #expect(cutoff.kind == .fader)
        #expect(cutoff.parameterNumber == 74)
        #expect(cutoff.potId == 1)
        #expect(cutoff.x == 20)
        // fader + "dial" variant → knob
        #expect(doc.control(id: 2)!.kind == .knob)
    }

    @Test func controlsFilteredByPage() {
        let doc = makeDoc()
        #expect(doc.controls(onPage: 1).map(\.id) == [1])
        #expect(doc.controls(onPage: 2).map(\.id) == [2])
    }

    @Test func roundTripPreservesAllTopLevelKeys() {
        let doc = makeDoc()
        func keys(_ s: String) -> Set<String> {
            guard let o = (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [String: Any] else { return [] }
            return Set(o.keys)
        }
        #expect(keys(Self.presetJSON) == keys(doc.jsonString()))
    }

    @Test func targetedEditLeavesOtherControlsUntouched() {
        var doc = makeDoc()
        doc.setControlName(id: 1, "Renamed")
        doc.setControlColor(id: 1, hex: "03A598")
        #expect(doc.control(id: 1)!.name == "Renamed")
        #expect(doc.control(id: 1)!.colorHex == "03A598")
        #expect(doc.control(id: 2)!.name == "Res")  // sibling untouched
        #expect(doc.allControls().count == 2)
    }

    @Test func setMessageParameterNumberAndType() {
        var doc = makeDoc()
        doc.setMessageParameterNumber(id: 1, 99)
        doc.setMessageType(id: 1, "nrpn")
        let c = doc.control(id: 1)!
        #expect(c.parameterNumber == 99)
        #expect(c.messageType == "nrpn")
    }

    @Test func addControlLandsInNextFreeCell() {
        var doc = makeDoc()
        let id = doc.addControl(kind: .fader, pageId: 1)
        let c = doc.control(id: id)!
        // page 1 had 1 control, so the new one occupies grid slot 2.
        #expect(c.pageId == 1)
        #expect([c.x, c.y, c.w, c.h] == [20 + 196, 36, 175, 122])
        #expect(c.kind == .fader)
    }

    @Test func placementNeverOverlapsAfterDeletion() {
        var doc = PresetDocument.newPreset()
        let a = doc.addControl(pageId: 1)   // slot 1
        _ = doc.addControl(pageId: 1)       // slot 2
        _ = doc.addControl(pageId: 1)       // slot 3
        doc.removeControl(id: a)            // slot 1 frees up
        let d = doc.addControl(pageId: 1)   // must reuse slot 1, not land on slot 3

        let added = doc.control(id: d)!
        #expect([added.x, added.y] == [20, 36])   // the freed origin slot
        // No two controls share an origin.
        let origins = doc.allControls().map { [$0.x, $0.y] }
        #expect(Set(origins.map { "\($0)" }).count == origins.count)
    }

    @Test func placementSkipsColumnsSpannedByWideControls() {
        var doc = PresetDocument.newPreset()
        _ = doc.addControl(kind: .custom, pageId: 1)  // spans slots 1+2
        let id = doc.addControl(pageId: 1)
        let c = doc.control(id: id)!
        // The fader must land in slot 3, past the 2-column custom control.
        #expect([c.x, c.y] == [20 + 2 * 196, 36])
    }

    @Test func newControlParameterIsLowestUnusedCC() {
        var doc = makeDoc()   // fixture already uses CC 74 and 71
        let id = doc.addControl(pageId: 1)
        let c = doc.control(id: id)!
        #expect(c.parameterNumber == 1)          // lowest unused, not the id
        #expect(c.name == "CC #1")               // label matches the parameter
    }

    @Test func addADSRBuildsFourValues() {
        var doc = makeDoc()
        let id = doc.addControl(kind: .adsr, pageId: 1)
        let c = doc.control(id: id)!
        #expect(c.kind == .adsr)
        #expect(c.valueCount == 4)
        #expect(doc.controlValues(id: id).map(\.valueId) == ["attack", "decay", "sustain", "release"])
    }

    @Test func kindSwitchKnobToADSRAndBack() {
        var doc = makeDoc()
        doc.setControlKind(id: 2, .adsr)
        #expect(doc.controlValues(id: 2).count == 4)
        doc.setControlKind(id: 2, .fader)
        #expect(doc.controlValues(id: 2).count == 1)  // ADSR collapses back to one value
        #expect(PresetDocument(jsonString: doc.jsonString()) != nil)
    }

    @Test func duplicateControlGetsNewIdAndOffset() {
        var doc = makeDoc()
        let newId = doc.duplicateControl(id: 1)
        #expect(newId != nil)
        #expect(doc.allControls().count == 3)
        let dup = doc.control(id: newId!)!
        #expect(dup.x == 20 + 24)
        #expect(dup.y == 36 + 24)
        #expect(dup.name == "Cutoff")
    }

    @Test func removeControl() {
        var doc = makeDoc()
        doc.removeControl(id: 1)
        #expect(doc.control(id: 1) == nil)
        #expect(doc.allControls().count == 1)
    }

    @Test func setControlBoundsRoundsToInts() {
        var doc = makeDoc()
        doc.setControlBounds(id: 1, x: 40.6, y: 50.4, w: 175, h: 122)
        let c = doc.control(id: 1)!
        #expect(c.x == 41)
        #expect(c.y == 50)
    }

    @Test func renamePage() {
        var doc = makeDoc()
        doc.renamePage(id: 2, to: "Renamed")
        #expect(doc.pages.first { $0.id == 2 }?.name == "Renamed")
    }

    @Test func addScriptControlBinding() {
        var doc = makeDoc()
        let id = doc.addScriptControl(pageId: 1)
        let c = doc.control(id: id)!
        #expect(c.isScript)
        #expect(c.functionName == PresetDocument.scriptFunctionName(forControlId: id))
        #expect(c.type == "pad")
    }

    @Test func newPresetTemplateIsValid() {
        let doc = PresetDocument.newPreset(name: "Fresh")
        #expect(doc.name == "Fresh")
        #expect(doc.pages.count == 2)
        #expect(doc.projectId?.count == 20)
        #expect(PresetDocument(jsonString: doc.jsonString()) != nil)
    }
}
