import XCTest
import Foundation
@testable import ElectraKit

final class PresetDocumentTests: XCTestCase {

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

    func test_parseTopLevel() {
        let doc = makeDoc()
        XCTAssertEqual(doc.name, "Demo")
        XCTAssertEqual(doc.version, 2)
        XCTAssertEqual(doc.projectId, "abc123")
        XCTAssertEqual(doc.pages.map(\.id), [1, 2])
        XCTAssertEqual(doc.deviceNames, ["Synth"])
        XCTAssertEqual(doc.allControls().count, 2)
    }

    func test_rejectsInvalidJSON() {
        XCTAssertEqual(PresetDocument(jsonString: "{ not json"), nil)
        XCTAssertEqual(PresetDocument(jsonString: "[1,2,3]"), nil)  // array, not an object
    }

    func test_controlParsingAndKind() {
        let doc = makeDoc()
        let cutoff = doc.control(id: 1)!
        XCTAssertEqual(cutoff.name, "Cutoff")
        XCTAssertEqual(cutoff.kind, .fader)
        XCTAssertEqual(cutoff.parameterNumber, 74)
        XCTAssertEqual(cutoff.potId, 1)
        XCTAssertEqual(cutoff.x, 20)
        // fader + "dial" variant → knob
        XCTAssertEqual(doc.control(id: 2)!.kind, .knob)
    }

    func test_controlsFilteredByPage() {
        let doc = makeDoc()
        XCTAssertEqual(doc.controls(onPage: 1).map(\.id), [1])
        XCTAssertEqual(doc.controls(onPage: 2).map(\.id), [2])
    }

    func test_roundTripPreservesAllTopLevelKeys() {
        let doc = makeDoc()
        func keys(_ s: String) -> Set<String> {
            guard let o = (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [String: Any] else { return [] }
            return Set(o.keys)
        }
        XCTAssertEqual(keys(Self.presetJSON), keys(doc.jsonString()))
    }

    func test_targetedEditLeavesOtherControlsUntouched() {
        var doc = makeDoc()
        doc.setControlName(id: 1, "Renamed")
        doc.setControlColor(id: 1, hex: "03A598")
        XCTAssertEqual(doc.control(id: 1)!.name, "Renamed")
        XCTAssertEqual(doc.control(id: 1)!.colorHex, "03A598")
        XCTAssertEqual(doc.control(id: 2)!.name, "Res")  // sibling untouched
        XCTAssertEqual(doc.allControls().count, 2)
    }

    func test_setMessageParameterNumberAndType() {
        var doc = makeDoc()
        doc.setMessageParameterNumber(id: 1, 99)
        doc.setMessageType(id: 1, "nrpn")
        let c = doc.control(id: 1)!
        XCTAssertEqual(c.parameterNumber, 99)
        XCTAssertEqual(c.messageType, "nrpn")
    }

    func test_addControlLandsInNextFreeCell() {
        var doc = makeDoc()
        let id = doc.addControl(kind: .fader, pageId: 1)
        let c = doc.control(id: id)!
        // page 1 had 1 control, so the new one occupies grid slot 2.
        XCTAssertEqual(c.pageId, 1)
        XCTAssertEqual([c.x, c.y, c.w, c.h], [20 + 196, 36, 175, 122])
        XCTAssertEqual(c.kind, .fader)
    }

    func test_placementNeverOverlapsAfterDeletion() {
        var doc = PresetDocument.newPreset()
        let a = doc.addControl(pageId: 1)   // slot 1
        _ = doc.addControl(pageId: 1)       // slot 2
        _ = doc.addControl(pageId: 1)       // slot 3
        doc.removeControl(id: a)            // slot 1 frees up
        let d = doc.addControl(pageId: 1)   // must reuse slot 1, not land on slot 3

        let added = doc.control(id: d)!
        XCTAssertEqual([added.x, added.y], [20, 36])   // the freed origin slot
        // No two controls share an origin.
        let origins = doc.allControls().map { [$0.x, $0.y] }
        XCTAssertEqual(Set(origins.map { "\($0)" }).count, origins.count)
    }

    func test_placementSkipsColumnsSpannedByWideControls() {
        var doc = PresetDocument.newPreset()
        _ = doc.addControl(kind: .custom, pageId: 1)  // spans slots 1+2
        let id = doc.addControl(pageId: 1)
        let c = doc.control(id: id)!
        // The fader must land in slot 3, past the 2-column custom control.
        XCTAssertEqual([c.x, c.y], [20 + 2 * 196, 36])
    }

    func test_newControlParameterIsLowestUnusedCC() {
        var doc = makeDoc()   // fixture already uses CC 74 and 71
        let id = doc.addControl(pageId: 1)
        let c = doc.control(id: id)!
        XCTAssertEqual(c.parameterNumber, 1)          // lowest unused, not the id
        XCTAssertEqual(c.name, "CC #1")               // label matches the parameter
    }

    func test_addADSRBuildsFourValues() {
        var doc = makeDoc()
        let id = doc.addControl(kind: .adsr, pageId: 1)
        let c = doc.control(id: id)!
        XCTAssertEqual(c.kind, .adsr)
        XCTAssertEqual(c.valueCount, 4)
        XCTAssertEqual(doc.controlValues(id: id).map(\.valueId), ["attack", "decay", "sustain", "release"])
    }

    func test_kindSwitchKnobToADSRAndBack() {
        var doc = makeDoc()
        doc.setControlKind(id: 2, .adsr)
        XCTAssertEqual(doc.controlValues(id: 2).count, 4)
        doc.setControlKind(id: 2, .fader)
        XCTAssertEqual(doc.controlValues(id: 2).count, 1)  // ADSR collapses back to one value
        XCTAssertNotEqual(PresetDocument(jsonString: doc.jsonString()), nil)
    }

    func test_duplicateControlGetsNewIdAndOffset() {
        var doc = makeDoc()
        let newId = doc.duplicateControl(id: 1)
        XCTAssertNotEqual(newId, nil)
        XCTAssertEqual(doc.allControls().count, 3)
        let dup = doc.control(id: newId!)!
        XCTAssertEqual(dup.x, 20 + 24)
        XCTAssertEqual(dup.y, 36 + 24)
        XCTAssertEqual(dup.name, "Cutoff")
    }

    func test_removeControl() {
        var doc = makeDoc()
        doc.removeControl(id: 1)
        XCTAssertEqual(doc.control(id: 1), nil)
        XCTAssertEqual(doc.allControls().count, 1)
    }

    func test_setControlBoundsRoundsToInts() {
        var doc = makeDoc()
        doc.setControlBounds(id: 1, x: 40.6, y: 50.4, w: 175, h: 122)
        let c = doc.control(id: 1)!
        XCTAssertEqual(c.x, 41)
        XCTAssertEqual(c.y, 50)
    }

    func test_renamePage() {
        var doc = makeDoc()
        doc.renamePage(id: 2, to: "Renamed")
        XCTAssertEqual(doc.pages.first { $0.id, 2 }?.name == "Renamed")
    }

    func test_addScriptControlBinding() {
        var doc = makeDoc()
        let id = doc.addScriptControl(pageId: 1)
        let c = doc.control(id: id)!
        XCTAssert(c.isScript)
        XCTAssertEqual(c.functionName, PresetDocument.scriptFunctionName(forControlId: id))
        XCTAssertEqual(c.type, "pad")
    }

    func test_newPresetTemplateIsValid() {
        let doc = PresetDocument.newPreset(name: "Fresh")
        XCTAssertEqual(doc.name, "Fresh")
        XCTAssertEqual(doc.pages.count, 2)
        XCTAssertEqual(doc.projectId?.count, 20)
        XCTAssertNotEqual(PresetDocument(jsonString: doc.jsonString()), nil)
    }
}
