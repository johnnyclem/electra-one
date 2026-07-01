import Testing
@testable import ElectraKit

@Suite struct SlotGeometryTests {
    @Test func cellForSlot() {
        #expect(SlotGeometry.cell(forSlot: 1) == (0, 0))
        #expect(SlotGeometry.cell(forSlot: 7) == (0, 1))
        #expect(SlotGeometry.cell(forSlot: 36) == (5, 5))
    }

    @Test func boundsFirstSlotMatchesWebEditorOrigin() {
        #expect(SlotGeometry.bounds(forSlot: 1).array == [20, 36, 175, 122])
    }

    @Test func boundsSecondColumnUsesPitch() {
        #expect(SlotGeometry.bounds(forSlot: 2).array == [20 + 196, 36, 175, 122])
    }

    @Test func boundsToSlotRoundTrips() {
        for slot in 1...36 {
            let b = SlotGeometry.bounds(forSlot: slot)
            #expect(SlotGeometry.slot(forBounds: b.x, b.y) == slot)
        }
    }

    @Test func slotForBoundsClampsOutOfRange() {
        #expect(SlotGeometry.slot(forBounds: 99999, 99999) == 36)
        #expect(SlotGeometry.slot(forBounds: -500, -500) == 1)
    }

    @Test func controlSetFromRow() {
        #expect(SlotGeometry.controlSet(forRow: 0) == 1)
        #expect(SlotGeometry.controlSet(forRow: 1) == 1)
        #expect(SlotGeometry.controlSet(forRow: 2) == 2)
        #expect(SlotGeometry.controlSet(forRow: 5) == 3)
    }

    @Test func potWithinControlSet() {
        #expect(SlotGeometry.pot(col: 0, row: 0) == 1)
        #expect(SlotGeometry.pot(col: 5, row: 0) == 6)
        #expect(SlotGeometry.pot(col: 0, row: 1) == 7)   // second row of the set → pots 7…12
        #expect(SlotGeometry.pot(col: 5, row: 1) == 12)
        #expect(SlotGeometry.pot(col: 0, row: 2) == 1)   // new control set restarts at 1
    }

    @Test func canvasExtent() {
        #expect(SlotGeometry.canvasWidth == 20 + 6 * 196)
        #expect(SlotGeometry.canvasHeight == 36 + 6 * 162)
    }
}
