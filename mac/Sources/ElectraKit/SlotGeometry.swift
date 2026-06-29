import Foundation

/// The Electra One's 6×6 control-slot grid (36 slots/page), mirroring the
/// firmware's `helpers.slotToBounds` / `boundsToSlot`.
///
/// The constants are taken from real web-editor presets, which consistently
/// place full-size controls at column lefts {20, 216, 412, 608, …} (pitch 196)
/// and row tops {36, 198, 360, …} (pitch 162), sized 175×122. Extending that to
/// all 6 columns and 6 rows yields a coordinate space larger than one physical
/// screen — the device pages through it by control set (2 rows each). Designing
/// against this exact grid is what makes a layout land correctly on hardware.
public enum SlotGeometry {
    public static let columns = 6
    public static let rows = 6
    public static let slotsPerPage = columns * rows   // 36

    public static let originX = 20.0
    public static let originY = 36.0
    public static let pitchX = 196.0
    public static let pitchY = 162.0
    public static let slotWidth = 175.0
    public static let slotHeight = 122.0

    /// Full grid extent (the preset coordinate space).
    public static let canvasWidth = originX + Double(columns) * pitchX   // 1196
    public static let canvasHeight = originY + Double(rows) * pitchY      // 1008

    public struct Bounds: Equatable {
        public var x: Double, y: Double, w: Double, h: Double
        public var array: [Int] { [Int(x.rounded()), Int(y.rounded()), Int(w.rounded()), Int(h.rounded())] }
    }

    /// Slot index → (column, row), 0-based, within a page (slot 1…36).
    public static func cell(forSlot slot: Int) -> (col: Int, row: Int) {
        let within = (slot - 1) % slotsPerPage
        return (within % columns, within / columns)
    }

    /// Which page (1-based) a global slot id falls on.
    public static func pageIndex(forSlot slot: Int) -> Int { (slot - 1) / slotsPerPage }

    /// slot (1…36) → pixel bounds. Mirrors firmware `slotToBounds`.
    public static func bounds(forSlot slot: Int) -> Bounds {
        let (col, row) = cell(forSlot: slot)
        return Bounds(
            x: originX + Double(col) * pitchX,
            y: originY + Double(row) * pitchY,
            w: slotWidth, h: slotHeight)
    }

    /// pixel bounds → nearest slot (1…36). Mirrors firmware `boundsToSlot`.
    public static func slot(forBounds x: Double, _ y: Double) -> Int {
        let col = max(0, min(columns - 1, Int(((x - originX) / pitchX).rounded())))
        let row = max(0, min(rows - 1, Int(((y - originY) / pitchY).rounded())))
        return row * columns + col + 1
    }

    /// The control-set (1…3) a row belongs to — two rows per set.
    public static func controlSet(forRow row: Int) -> Int { row / 2 + 1 }

    /// Pot id (1…12) for a cell within its control set.
    public static func pot(col: Int, row: Int) -> Int { (row % 2) * columns + col + 1 }
}
