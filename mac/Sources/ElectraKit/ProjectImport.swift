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

    /// Load from a file's text, auto-detecting project vs preset.
    public static func load(fileText text: String) -> PresetDocument? {
        guard let data = text.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        if obj["tiles"] != nil || obj["schemaVersion"] != nil {
            return importProject(obj)
        }
        return PresetDocument(root: obj)
    }

    /// True if the JSON text looks like an Electra project (.eproj).
    public static func isProject(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        return obj["tiles"] != nil || obj["schemaVersion"] != nil
    }

    // ── Project → preset conversion ─────────────────────────────────────────

    static func importProject(_ proj: [String: Any]) -> PresetDocument {
        let pagesIn = proj["pages"] as? [[String: Any]] ?? [["id": 1, "name": "Page 1"]]
        let pageIds = pagesIn.compactMap { $0["id"] as? Int }
        func pageId(forSlot slot: Int) -> Int {
            let idx = (slot - 1) / 36
            return (idx >= 0 && idx < pageIds.count) ? pageIds[idx] : (pageIds.first ?? 1)
        }

        let tiles = proj["tiles"] as? [[String: Any]] ?? []
        var controls: [[String: Any]] = []
        for (i, tile) in tiles.enumerated() {
            let slotId = tile["slotId"] as? Int ?? (i + 1)
            let (col, row) = SlotGeometry.cell(forSlot: slotId)
            let refId = tile["reference"] as? Int ?? (i + 1)

            var control: [String: Any] = [
                "id": refId,
                "type": tile["type"] as? String ?? "fader",
                "name": tile["name"] as? String ?? "",
                "color": tile["color"] as? String ?? "FFFFFF",
                "bounds": SlotGeometry.bounds(forSlot: slotId).array,
                "pageId": pageId(forSlot: slotId),
                "controlSetId": SlotGeometry.controlSet(forRow: row),
                "visible": tile["visible"] as? Bool ?? true,
                "inputs": [["potId": SlotGeometry.pot(col: col, row: row), "valueId": "value"]],
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
            ? [["id": 1, "name": "MIDI Device 1", "port": 1, "channel": 1]]
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
            "projectId": proj["id"] as? String ?? PresetDocument.newPreset().projectId ?? "imported",
            "pages": pagesIn.map { ["id": $0["id"] ?? 1, "name": $0["name"] ?? "Page"] },
            "devices": devices,
            "groups": [[String: Any]](),
            "overlays": [[String: Any]](),
            "controls": controls,
        ]

        var doc = PresetDocument(root: root)
        if let lua = proj["lua"] as? String, !lua.isEmpty { doc.lua = lua }
        return doc
    }
}
