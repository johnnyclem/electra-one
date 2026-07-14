import XCTest
import Foundation
@testable import ElectraKit

final class ConnectorTests: XCTestCase {

    /// Fixture: two controls (ids 1 and 2) on pages 1 and 2 — see PresetDocumentTests.
    func makeDoc() -> PresetDocument {
        guard let doc = PresetDocument(jsonString: PresetDocumentTests.presetJSON) else {
            fatalError("fixture JSON failed to parse")
        }
        return doc
    }

    func test_addAndParseControlConnector() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .control(2), colorHex: "F45C51")
        let k = doc.connector(id: id)
        XCTAssertNotEqual(k, nil)
        XCTAssertEqual(k?.fromControlId, 1)
        XCTAssertEqual(k?.target, .control(2))
        XCTAssertEqual(k?.colorHex, "F45C51")
        XCTAssertEqual(k?.label, "")
    }

    func test_addAndParsePageConnector() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .page(2))
        XCTAssertEqual(doc.connector(id: id)?.target, .page(2))
    }

    func test_duplicateAddReturnsExistingId() {
        var doc = makeDoc()
        let first = doc.addConnector(fromControlId: 1, to: .control(2))
        let second = doc.addConnector(fromControlId: 1, to: .control(2))
        XCTAssertEqual(first, second)
        XCTAssertEqual(doc.connectors.count, 1)
        // The reverse direction is a distinct connector, not a duplicate.
        let reversed = doc.addConnector(fromControlId: 2, to: .control(1))
        XCTAssertNotEqual(reversed, first)
        XCTAssertEqual(doc.connectors.count, 2)
    }

    func test_connectorsFilteredByPage() {
        var doc = makeDoc()
        _ = doc.addConnector(fromControlId: 1, to: .page(2))   // control 1 is on page 1
        _ = doc.addConnector(fromControlId: 2, to: .page(1))   // control 2 is on page 2
        XCTAssertEqual(doc.connectors(onPage: 1).count, 1)
        XCTAssertEqual(doc.connectors(onPage: 1).first?.fromControlId, 1)
        XCTAssertEqual(doc.connectors(onPage: 2).count, 1)
    }

    func test_labelColorAndReverse() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .control(2))
        doc.setConnectorLabel(id: id, "modulates")
        doc.setConnectorColor(id: id, hex: "03A598")
        XCTAssertEqual(doc.connector(id: id)?.label, "modulates")
        XCTAssertEqual(doc.connector(id: id)?.colorHex, "03A598")

        doc.reverseConnector(id: id)
        XCTAssertEqual(doc.connector(id: id)?.fromControlId, 2)
        XCTAssertEqual(doc.connector(id: id)?.target, .control(1))

        // Reversing a page link is a no-op — there's no control to swap with.
        let pageLink = doc.addConnector(fromControlId: 1, to: .page(2))
        doc.reverseConnector(id: pageLink)
        XCTAssertEqual(doc.connector(id: pageLink)?.fromControlId, 1)
        XCTAssertEqual(doc.connector(id: pageLink)?.target, .page(2))
    }

    func test_removeConnector() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .control(2))
        doc.removeConnector(id: id)
        XCTAssert(doc.connectors.isEmpty)
    }

    func test_removingControlPurgesItsConnectors() {
        var doc = makeDoc()
        _ = doc.addConnector(fromControlId: 1, to: .control(2))
        _ = doc.addConnector(fromControlId: 2, to: .control(1))
        _ = doc.addConnector(fromControlId: 2, to: .page(1))
        doc.removeControl(id: 1)
        // Both arrows touching control 1 are gone; control 2's page link stays.
        XCTAssertEqual(doc.connectors.count, 1)
        XCTAssertEqual(doc.connectors.first?.target, .page(1))
    }

    func test_connectorsRoundTripThroughJSON() {
        var doc = makeDoc()
        let id = doc.addConnector(fromControlId: 1, to: .control(2), colorHex: "529DEC")
        doc.setConnectorLabel(id: id, "sends to")
        _ = doc.addConnector(fromControlId: 1, to: .page(2))

        let reloaded = PresetDocument(jsonString: doc.jsonString())
        XCTAssertNotEqual(reloaded, nil)
        XCTAssertEqual(reloaded?.connectors, doc.connectors)
    }

    func test_deviceUploadStripsConnectors() {
        var doc = makeDoc()
        _ = doc.addConnector(fromControlId: 1, to: .control(2))

        func keys(_ s: String) -> Set<String> {
            guard let o = (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [String: Any] else { return [] }
            return Set(o.keys)
        }
        XCTAssert(keys(doc.jsonString()).contains("connectors"))
        XCTAssert(!keys(doc.jsonString(forDevice: true)).contains("connectors"))
        // Stripping must not drop anything else.
        XCTAssertEqual(keys(doc.jsonString(forDevice: true)), keys(doc.jsonString()).subtracting(["connectors"]))
    }

    func test_malformedConnectorEntriesAreSkipped() {
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
        XCTAssertEqual(doc.connectors.map(\.id), [1])
    }
}
