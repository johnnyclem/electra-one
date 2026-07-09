import Testing
import Foundation
@testable import ElectraKit

@Suite struct ConnectorTests {

    /// Fixture: two controls (ids 1 and 2) on pages 1 and 2 — see PresetDocumentTests.
    func makeDoc() -> PresetDocument {
        guard let doc = PresetDocument(jsonString: PresetDocumentTests.presetJSON) else {
            fatalError("fixture JSON failed to parse")
        }
        return doc
    }

    @Test func addAndParseControlConnector() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .control(2), colorHex: "F45C51")
        let k = doc.connector(id: id)
        #expect(k != nil)
        #expect(k?.fromControlId == 1)
        #expect(k?.target == .control(2))
        #expect(k?.colorHex == "F45C51")
        #expect(k?.label == "")
    }

    @Test func addAndParsePageConnector() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .page(2))
        #expect(doc.connector(id: id)?.target == .page(2))
    }

    @Test func duplicateAddReturnsExistingId() {
        var doc = makeDoc()
        let first = doc.addConnector(fromControlId: 1, to: .control(2))
        let second = doc.addConnector(fromControlId: 1, to: .control(2))
        #expect(first == second)
        #expect(doc.connectors.count == 1)
        // The reverse direction is a distinct connector, not a duplicate.
        let reversed = doc.addConnector(fromControlId: 2, to: .control(1))
        #expect(reversed != first)
        #expect(doc.connectors.count == 2)
    }

    @Test func connectorsFilteredByPage() {
        var doc = makeDoc()
        _ = doc.addConnector(fromControlId: 1, to: .page(2))   // control 1 is on page 1
        _ = doc.addConnector(fromControlId: 2, to: .page(1))   // control 2 is on page 2
        #expect(doc.connectors(onPage: 1).count == 1)
        #expect(doc.connectors(onPage: 1).first?.fromControlId == 1)
        #expect(doc.connectors(onPage: 2).count == 1)
    }

    @Test func labelColorAndReverse() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .control(2))
        doc.setConnectorLabel(id: id, "modulates")
        doc.setConnectorColor(id: id, hex: "03A598")
        #expect(doc.connector(id: id)?.label == "modulates")
        #expect(doc.connector(id: id)?.colorHex == "03A598")

        doc.reverseConnector(id: id)
        #expect(doc.connector(id: id)?.fromControlId == 2)
        #expect(doc.connector(id: id)?.target == .control(1))

        // Reversing a page link is a no-op — there's no control to swap with.
        let pageLink = doc.addConnector(fromControlId: 1, to: .page(2))
        doc.reverseConnector(id: pageLink)
        #expect(doc.connector(id: pageLink)?.fromControlId == 1)
        #expect(doc.connector(id: pageLink)?.target == .page(2))
    }

    @Test func removeConnector() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .control(2))
        doc.removeConnector(id: id)
        #expect(doc.connectors.isEmpty)
    }

    @Test func removingControlPurgesItsConnectors() {
        var doc = makeDoc()
        _ = doc.addConnector(fromControlId: 1, to: .control(2))
        _ = doc.addConnector(fromControlId: 2, to: .control(1))
        _ = doc.addConnector(fromControlId: 2, to: .page(1))
        doc.removeControl(id: 1)
        // Both arrows touching control 1 are gone; control 2's page link stays.
        #expect(doc.connectors.count == 1)
        #expect(doc.connectors.first?.target == .page(1))
    }

    @Test func connectorsRoundTripThroughJSON() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .control(2), colorHex: "529DEC")
        doc.setConnectorLabel(id: id, "sends to")
        _ = doc.addConnector(fromControlId: 1, to: .page(2))

        let reloaded = PresetDocument(jsonString: doc.jsonString())
        #expect(reloaded != nil)
        #expect(reloaded?.connectors == doc.connectors)
    }

    @Test func deviceUploadStripsConnectors() {
        var doc = makeDoc()
        _ = doc.addConnector(fromControlId: 1, to: .control(2))

        func keys(_ s: String) -> Set<String> {
            guard let o = (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [String: Any] else { return [] }
            return Set(o.keys)
        }
        #expect(keys(doc.jsonString()).contains("connectors"))
        #expect(!keys(doc.jsonString(forDevice: true)).contains("connectors"))
        // Stripping must not drop anything else.
        #expect(keys(doc.jsonString(forDevice: true)) == keys(doc.jsonString()).subtracting(["connectors"]))
    }

    @Test func malformedConnectorEntriesAreSkipped() {
        let json = """
        {"version": 2, "name": "X", "pages": [{"id": 1, "name": "P"}], "controls": [],
         "connectors": [
            {"id": 1, "fromControlId": 3, "toControlId": 7},
            {"id": 2, "fromControlId": 3},
            {"fromControlId": 3, "toPageId": 2},
            {"id": 4, "toPageId": 2}
         ]}
        """
        let doc = PresetDocument(jsonString: json)!
        // Only the first entry has an id, a source, and a target.
        #expect(doc.connectors.map(\.id) == [1])
    }
}
