import Foundation

/// Loading Electra files, auto-detecting the two formats:
///   - `.eproj` — the web-editor *project* (schemaVersion 2): controls live in
///     `tiles`, positioned by `slotId`, with an embedded `lua` script.
///   - `.epr` / `.json` — the *device preset*: controls in `controls` with
///     pixel `bounds`, the format the hardware exchanges.
///
/// Projects are converted into the device-preset model so the visual editor
/// and device upload work uniformly.
extension PresetDocument {

    /// Parse the file text into a JSON object (nil if it isn't one).
    private static func parseObject(_ text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    /// Project detection on already-parsed JSON — shared by `load`/`isProject`
    /// so neither has to parse twice.
    private static func looksLikeProject(_ obj: [String: Any]) -> Bool {
        obj["tiles"] != nil || obj["schemaVersion"] != nil
    }

    /// Load from a file's text, auto-detecting project vs preset.
    public static func load(fileText text: String) -> PresetDocument? {
        guard let obj = parseObject(text) else { return nil }
        return looksLikeProject(obj) ? importProject(obj) : PresetDocument(root: obj)
    }

    /// True if the JSON text looks like an Electra project (.eproj).
    public static func isProject(_ text: String) -> Bool {
        parseObject(text).map(looksLikeProject) ?? false
    }

    // ── Project → preset conversion ─────────────────────────────────────────

    /// The eproj editor places tiles on a 6-column grid. Each device *page*
    /// occupies a block of 72 editor slots (12 editor rows), and every two
    /// editor rows collapse into one device pot-row — so a 12-row editor page
    /// maps onto the device's 6 rows (3 control sets × 2 rows of 6 pots).
    private static let editorCols = 6
    private static let editorSlotsPerPage = 72

    /// Decode a 0-based eproj `slotId` into its device coordinates.
    private static func decodeSlot(_ slot: Int)
        -> (pageIndex: Int, deviceRow: Int, col: Int) {
        let pageIndex = slot / editorSlotsPerPage
        let local = slot % editorSlotsPerPage
        let editorRow = local / editorCols
        let col = local % editorCols
        return (pageIndex, editorRow / 2, col)
    }

    static func importProject(_ proj: [String: Any]) -> PresetDocument {
        let pagesIn = proj["pages"] as? [[String: Any]] ?? [["id": 1, "name": "Page 1"]]
        let pageIds = pagesIn.compactMap { $0["id"] as? Int }
        func pageId(forIndex idx: Int) -> Int {
            (idx >= 0 && idx < pageIds.count) ? pageIds[idx] : (pageIds.first ?? 1)
        }

        let tiles = proj["tiles"] as? [[String: Any]] ?? []
        var controls: [[String: Any]] = []
        var groups: [[String: Any]] = []
        // Fallback ids for tiles without an explicit `reference` are allocated
        // above the highest explicit one so they can never collide with it.
        var nextFallbackId = tiles.compactMap { $0["reference"] as? Int }.max() ?? 0
        for (i, tile) in tiles.enumerated() {
            let slotId = tile["slotId"] as? Int ?? i
            let (pageIndex, deviceRow, col) = decodeSlot(slotId)
            let pid = pageId(forIndex: pageIndex)
            let refId: Int
            if let r = tile["reference"] as? Int {
                refId = r
            } else {
                nextFallbackId += 1
                refId = nextFallbackId
            }
            let type = tile["type"] as? String ?? "fader"
            // A device cell on the collapsed 6×6 grid (1…36), reused for geometry.
            let cellSlot = deviceRow * SlotGeometry.columns + col + 1
            let cell = SlotGeometry.bounds(forSlot: cellSlot)

            // `label` tiles are visual separators, not controls — the firmware
            // only accepts fader/list/pad/vfader/adsr/adr/dx7envelope and NACKs
            // any other control type. Emit them as `groups` instead.
            if type == "label" {
                let span = max(1, tile["span"] as? Int ?? 1)
                // Spanning adds whole column pitches (slot width + gap), not
                // bare slot widths — matches how addControl widens controls.
                let width = Int((SlotGeometry.slotWidth + Double(span - 1) * SlotGeometry.pitchX).rounded())
                groups.append([
                    "id": refId,
                    "pageId": pid,
                    "name": tile["name"] as? String ?? "",
                    "color": tile["color"] as? String ?? "FFFFFF",
                    "bounds": [cell.array[0], cell.array[1], width, 16],
                ])
                continue
            }

            var control: [String: Any] = [
                "id": refId,
                "type": type,
                "name": tile["name"] as? String ?? "",
                "color": tile["color"] as? String ?? "FFFFFF",
                "bounds": cell.array,
                "pageId": pid,
                "controlSetId": SlotGeometry.controlSet(forRow: deviceRow),
                "visible": tile["visible"] as? Bool ?? true,
                "inputs": [["potId": SlotGeometry.pot(col: col, row: deviceRow), "valueId": "value"]],
            ]
            if let v = tile["variant"] as? String, !v.isEmpty { control["variant"] = v }
            if let m = tile["mode"] as? String { control["mode"] = m }

            var values = tile["values"] as? [[String: Any]] ?? []
            for j in values.indices where values[j]["id"] == nil { values[j]["id"] = "value" }
            control["values"] = values

            controls.append(control)
        }

        let devicesIn = proj["devices"] as? [[String: Any]] ?? []
        let devices: [[String: Any]] = devicesIn.isEmpty
            ? [PresetDocument.defaultDevice]
            : devicesIn.map { d in
                [
                    "id": d["id"] ?? 1,
                    "name": d["name"] ?? "Device",
                    "port": d["port"] ?? 1,
                    "channel": d["channel"] ?? 1,
                ]
            }

        let root: [String: Any] = [
            "version": 2,
            "name": proj["name"] as? String ?? "Imported Preset",
            "projectId": proj["id"] as? String ?? PresetDocument.makeProjectId(),
            "pages": pagesIn.map { ["id": $0["id"] ?? 1, "name": $0["name"] ?? "Page"] },
            "devices": devices,
            "groups": groups,
            "overlays": [[String: Any]](),
            "controls": controls,
        ]

        var doc = PresetDocument(root: root)
        if let lua = proj["lua"] as? String, !lua.isEmpty { doc.lua = lua }
        return doc
    }
}
