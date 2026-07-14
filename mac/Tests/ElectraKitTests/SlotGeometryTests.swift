import XCTest
import Foundation
@testable import ElectraKit

final class SlotGeometryTests: XCTestCase {
    func test_cellForSlot() {
        XCTAssertEqual(SlotGeometry.cell(forSlot: 1), (0, 0))
        XCTAssertEqual(SlotGeometry.cell(forSlot: 7), (0, 1))
        XCTAssertEqual(SlotGeometry.cell(forSlot: 36), (5, 5))
    }

    func test_boundsFirstSlotMatchesWebEditorOrigin() {
        XCTAssertEqual(SlotGeometry.bounds(forSlot: 1).array, [20, 36, 175, 122])
    }

    func test_boundsSecondColumnUsesPitch() {
        XCTAssertEqual(SlotGeometry.bounds(forSlot: 2).array, [20 + 196, 36, 175, 122])
    }

    func test_boundsToSlotRoundTrips() {
        for slot in 1...36 {
            let b = SlotGeometry.bounds(forSlot: slot)
            XCTAssertEqual(SlotGeometry.slot(forBounds: b.x, b.y), slot)
        }
    }

    func test_slotForBoundsClampsOutOfRange() {
        XCTAssertEqual(SlotGeometry.slot(forBounds: 99999, 99999), 36)
        XCTAssertEqual(SlotGeometry.slot(forBounds: -500, -500), 1)
    }

    func test_controlSetFromRow() {
        XCTAssertEqual(SlotGeometry.controlSet(forRow: 0), 1)
        XCTAssertEqual(SlotGeometry.controlSet(forRow: 1), 1)
        XCTAssertEqual(SlotGeometry.controlSet(forRow: 2), 2)
        XCTAssertEqual(SlotGeometry.controlSet(forRow: 5), 3)
    }

    func test_potWithinControlSet() {
        XCTAssertEqual(SlotGeometry.pot(col: 0, row: 0), 1)
        XCTAssertEqual(SlotGeometry.pot(col: 5, row: 0), 6)
        XCTAssertEqual(SlotGeometry.pot(col: 0, row: 1), 7)   // second row of the set → pots 7…12
        XCTAssertEqual(SlotGeometry.pot(col: 5, row: 1), 12)
        XCTAssertEqual(SlotGeometry.pot(col: 0, row: 2), 1)   // new control set restarts at 1
    }

    func test_canvasExtent() {
        XCTAssertEqual(SlotGeometry.canvasWidth, 20 + 6 * 196)
        XCTAssertEqual(SlotGeometry.canvasHeight, 36 + 6 * 162)
    }
}
