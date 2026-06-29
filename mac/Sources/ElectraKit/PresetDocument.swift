import Foundation

/// An editable Electra One preset.
///
/// Backed by the full parsed JSON (`root`) so that **every** field round-trips
/// untouched — editing only mutates the keys we explicitly change. This is the
/// safe-upload guarantee: we never reserialize a lossy model back to the device.
public struct PresetDocument {
    public private(set) var root: [String: Any]

    /// Optional Lua script associated with the preset. Populated when importing
    /// an `.eproj` project (which embeds it) or when fetched from the device.
    /// Not part of `root`, so it never leaks into the preset JSON upload.
    public var lua: String? = nil

    public init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        root = obj
    }

    public init(root: [String: Any]) { self.root = root }

    // ── Logical screen ─────────────────────────────────────────────────────

    /// Electra One preset coordinate space — the full 6×6 slot grid extent.
    public static let screenWidth: Double = SlotGeometry.canvasWidth
    public static let screenHeight: Double = SlotGeometry.canvasHeight

    /// The six assignable Electra colors (plus white) for the palette picker.
    public static let palette: [String] = [
        "FFFFFF", "F45C51", "F49500", "529DEC", "03A598", "C44795",
    ]

    // ── Top-level ──────────────────────────────────────────────────────────

    public var name: String {
        get { root["name"] as? String ?? "" }
        set { root["name"] = newValue }
    }

    public var version: Int { root["version"] as? Int ?? 2 }
    public var projectId: String? { root["projectId"] as? String }

    public struct Page: Identifiable, Hashable {
        public let id: Int
        public var name: String
    }

    public var pages: [Page] {
        let arr = root["pages"] as? [[String: Any]] ?? []
        let parsed = arr.compactMap { p -> Page? in
            guard let id = p["id"] as? Int else { return nil }
            return Page(id: id, name: p["name"] as? String ?? "Page \(id)")
        }
        return parsed.isEmpty ? [Page(id: 1, name: "Page 1")] : parsed
    }

    public var deviceNames: [String] {
        (root["devices"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }
    }

    // ── Controls ─────────────────────────────────────────────────────────────

    /// User-facing control kinds. Several map to the same Electra `type` with a
    /// different `variant` (a Knob is a `fader` with the `dial` variant).
    public enum ControlKind: String, CaseIterable, Sendable {
        case fader, knob, vfader, pad, list, adsr

        public var displayName: String {
            switch self {
            case .fader:  return "Fader"
            case .knob:   return "Knob"
            case .vfader: return "VFader"
            case .pad:    return "Pad"
            case .list:   return "List"
            case .adsr:   return "ADSR"
            }
        }

        var rawType: String {
            switch self {
            case .fader, .knob: return "fader"
            case .vfader:       return "vfader"
            case .pad:          return "pad"
            case .list:         return "list"
            case .adsr:         return "adsr"
            }
        }

        /// Variant to write: `dial` for a knob, `""` for a plain fader, and
        /// nil (remove the key) for the rest.
        var rawVariant: String? {
            switch self {
            case .knob:  return "dial"
            case .fader: return ""
            default:     return nil
            }
        }

        public static func from(type: String, variant: String?) -> ControlKind {
            switch type {
            case "fader":  return variant == "dial" ? .knob : .fader
            case "vfader": return .vfader
            case "pad":    return .pad
            case "list":   return .list
            case "adsr", "adr", "dx7envelope": return .adsr
            default:       return .fader
            }
        }
    }

    /// The four ADSR value ids, in display order.
    public static let adsrValueIds = ["attack", "decay", "sustain", "release"]

    public struct Control: Identifiable, Hashable {
        public var id: Int
        public var type: String
        public var variant: String?
        public var name: String
        public var colorHex: String
        public var x: Double, y: Double, w: Double, h: Double
        public var pageId: Int
        public var controlSetId: Int
        public var potId: Int?
        public var messageType: String?
        public var parameterNumber: Int?
        public var deviceId: Int?
        public var minValue: Int?
        public var maxValue: Int?
        public var valueCount: Int
        public var visible: Bool

        public var kind: ControlKind { ControlKind.from(type: type, variant: variant) }
    }

    private static func parseControl(_ c: [String: Any]) -> Control? {
        guard let id = c["id"] as? Int else { return nil }
        let bounds = c["bounds"] as? [Double] ?? (c["bounds"] as? [Int])?.map(Double.init) ?? [0, 0, 0, 0]
        let b = bounds.count == 4 ? bounds : [0, 0, 0, 0]
        let inputs = c["inputs"] as? [[String: Any]] ?? []
        let values = c["values"] as? [[String: Any]] ?? []
        let firstMsg = (values.first?["message"]) as? [String: Any]
        return Control(
            id: id,
            type: c["type"] as? String ?? "fader",
            variant: c["variant"] as? String,
            name: c["name"] as? String ?? "",
            colorHex: c["color"] as? String ?? "FFFFFF",
            x: b[0], y: b[1], w: b[2], h: b[3],
            pageId: c["pageId"] as? Int ?? 1,
            controlSetId: c["controlSetId"] as? Int ?? 1,
            potId: inputs.first?["potId"] as? Int,
            messageType: firstMsg?["type"] as? String,
            parameterNumber: firstMsg?["parameterNumber"] as? Int,
            deviceId: firstMsg?["deviceId"] as? Int,
            minValue: firstMsg?["min"] as? Int,
            maxValue: firstMsg?["max"] as? Int,
            valueCount: values.count,
            visible: c["visible"] as? Bool ?? true
        )
    }

    public func allControls() -> [Control] {
        (root["controls"] as? [[String: Any]] ?? []).compactMap { Self.parseControl($0) }
    }

    public func controls(onPage pageId: Int) -> [Control] {
        allControls().filter { $0.pageId == pageId }
    }

    public func control(id: Int) -> Control? {
        allControls().first { $0.id == id }
    }

    // ── Mutation ─────────────────────────────────────────────────────────────

    /// Low-level: mutate the raw dict of the control with the given id.
    public mutating func mutateControl(id: Int, _ body: (inout [String: Any]) -> Void) {
        guard var controls = root["controls"] as? [[String: Any]] else { return }
        for i in controls.indices where (controls[i]["id"] as? Int) == id {
            var c = controls[i]
            body(&c)
            controls[i] = c
            break
        }
        root["controls"] = controls
    }

    public mutating func setControlName(id: Int, _ name: String) {
        mutateControl(id: id) { $0["name"] = name }
    }

    public mutating func setControlColor(id: Int, hex: String) {
        mutateControl(id: id) { $0["color"] = hex }
    }

    public mutating func setControlBounds(id: Int, x: Double, y: Double, w: Double, h: Double) {
        mutateControl(id: id) { $0["bounds"] = [Int(x.rounded()), Int(y.rounded()), Int(w.rounded()), Int(h.rounded())] }
    }

    public mutating func setMessageParameterNumber(id: Int, _ number: Int) {
        mutateControl(id: id) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            if values.isEmpty { values = [["id": "value", "message": [String: Any]()]] }
            var v = values[0]
            var m = v["message"] as? [String: Any] ?? [:]
            m["parameterNumber"] = number
            v["message"] = m
            values[0] = v
            c["values"] = values
        }
    }

    public mutating func setMessageType(id: Int, _ type: String) {
        mutateControl(id: id) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            if values.isEmpty { values = [["id": "value", "message": [String: Any]()]] }
            var v = values[0]
            var m = v["message"] as? [String: Any] ?? [:]
            m["type"] = type
            v["message"] = m
            values[0] = v
            c["values"] = values
        }
    }

    public mutating func setControlType(id: Int, _ type: String) {
        mutateControl(id: id) { $0["type"] = type }
    }

    /// Read each value's id + parameter number (ADSR has four).
    public func controlValues(id: Int) -> [(valueId: String, parameterNumber: Int?)] {
        guard let controls = root["controls"] as? [[String: Any]],
              let c = controls.first(where: { ($0["id"] as? Int) == id }) else { return [] }
        let values = c["values"] as? [[String: Any]] ?? []
        return values.map { v in
            let m = v["message"] as? [String: Any]
            return (v["id"] as? String ?? "value", m?["parameterNumber"] as? Int)
        }
    }

    /// Set the parameter number of a specific value by id (for multi-value
    /// controls like ADSR).
    public mutating func setValueParameterNumber(controlId: Int, valueId: String, _ number: Int) {
        mutateControl(id: controlId) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            for i in values.indices where (values[i]["id"] as? String) == valueId {
                var v = values[i]
                var m = v["message"] as? [String: Any] ?? ["type": "cc7", "min": 0, "max": 127]
                m["parameterNumber"] = number
                v["message"] = m
                values[i] = v
            }
            c["values"] = values
        }
    }

    /// Change a control's kind, updating type/variant and (for ADSR) the value
    /// structure so the result is a valid control.
    public mutating func setControlKind(id: Int, _ kind: ControlKind) {
        let dev = (root["devices"] as? [[String: Any]])?.first?["id"] as? Int ?? 1
        mutateControl(id: id) { c in
            c["type"] = kind.rawType
            if let v = kind.rawVariant { c["variant"] = v } else { c.removeValue(forKey: "variant") }

            let existing = c["values"] as? [[String: Any]] ?? []
            let isADSR = kind == .adsr
            let hasADSRShape = existing.count == 4

            if isADSR && !hasADSRShape {
                let base = (existing.first?["message"] as? [String: Any])?["parameterNumber"] as? Int ?? 1
                let pot = (c["inputs"] as? [[String: Any]])?.first?["potId"] as? Int ?? 1
                c["inputs"] = Self.adsrValueIds.enumerated().map { i, vid in
                    ["potId": min(12, pot + i), "valueId": vid]
                }
                c["values"] = Self.adsrValueIds.enumerated().map { i, vid in
                    ["id": vid, "defaultValue": 0,
                     "message": ["type": "cc7", "min": 0, "max": 127, "parameterNumber": base + i, "deviceId": dev]]
                }
            } else if !isADSR && hasADSRShape {
                // Collapse the 4 ADSR values back to a single value.
                let first = existing.first ?? [:]
                let msg = first["message"] as? [String: Any] ?? ["type": "cc7", "min": 0, "max": 127, "deviceId": dev]
                let pot = (c["inputs"] as? [[String: Any]])?.first?["potId"] as? Int ?? 1
                c["inputs"] = [["potId": pot, "valueId": "value"]]
                c["values"] = [["id": "value", "defaultValue": 0, "message": msg]]
            }
        }
    }

    public mutating func removeControl(id: Int) {
        guard var controls = root["controls"] as? [[String: Any]] else { return }
        controls.removeAll { ($0["id"] as? Int) == id }
        root["controls"] = controls
    }

    /// Add a fresh control of the given kind, placed in the next free grid cell.
    @discardableResult
    public mutating func addControl(kind: ControlKind = .fader, pageId: Int, deviceId: Int? = nil) -> Int {
        var controls = root["controls"] as? [[String: Any]] ?? []
        let newId = (controls.compactMap { $0["id"] as? Int }.max() ?? 0) + 1
        let dev = deviceId ?? (root["devices"] as? [[String: Any]])?.first?["id"] as? Int ?? 1

        // Place into the next free slot on the 6×6 grid.
        let used = controls.filter { ($0["pageId"] as? Int) == pageId }.count
        let slot = (used % SlotGeometry.slotsPerPage) + 1
        let (col, row) = SlotGeometry.cell(forSlot: slot)
        let b = SlotGeometry.bounds(forSlot: slot)
        let pot = SlotGeometry.pot(col: col, row: row)

        var control: [String: Any] = [
            "id": newId,
            "type": kind.rawType,
            "visible": true,
            "name": kind == .adsr ? "ADSR" : "CC #\(newId)",
            "color": Self.palette[1 + (newId % (Self.palette.count - 1))],
            "pageId": pageId,
            "controlSetId": SlotGeometry.controlSet(forRow: row),
        ]
        if let v = kind.rawVariant { control["variant"] = v }

        if kind == .adsr {
            // ADSR spans two columns and carries four CC values.
            control["bounds"] = [b.x, b.y, b.w + SlotGeometry.pitchX, b.h].map { Int($0.rounded()) }
            control["inputs"] = Self.adsrValueIds.enumerated().map { i, vid in
                ["potId": min(12, pot + i), "valueId": vid]
            }
            control["values"] = Self.adsrValueIds.enumerated().map { i, vid in
                ["id": vid, "defaultValue": 0,
                 "message": ["type": "cc7", "min": 0, "max": 127, "parameterNumber": newId + i, "deviceId": dev]]
            }
        } else {
            control["bounds"] = b.array
            control["inputs"] = [["potId": pot, "valueId": "value"]]
            control["values"] = [[
                "id": "value", "defaultValue": 0,
                "message": ["type": "cc7", "min": 0, "max": 127, "parameterNumber": newId, "deviceId": dev],
            ]]
        }

        controls.append(control)
        root["controls"] = controls
        return newId
    }

    public mutating func renamePage(id: Int, to name: String) {
        guard var pages = root["pages"] as? [[String: Any]] else { return }
        for i in pages.indices where (pages[i]["id"] as? Int) == id {
            pages[i]["name"] = name
        }
        root["pages"] = pages
    }

    // ── Serialization ──────────────────────────────────────────────────────

    public func jsonString(pretty: Bool = false) -> String {
        let opts: JSONSerialization.WritingOptions = pretty ? [.prettyPrinted, .sortedKeys] : []
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: opts),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    // ── Templates ────────────────────────────────────────────────────────────

    public static func newPreset(name: String = "New Preset") -> PresetDocument {
        let root: [String: Any] = [
            "version": 2,
            "name": name,
            "projectId": Self.makeProjectId(),
            "pages": [
                ["id": 1, "name": "Page 1"],
                ["id": 2, "name": "Page 2"],
            ],
            "devices": [
                ["id": 1, "name": "MIDI Device 1", "port": 1, "channel": 1],
            ],
            "groups": [[String: Any]](),
            "overlays": [[String: Any]](),
            "controls": [[String: Any]](),
        ]
        return PresetDocument(root: root)
    }

    private static func makeProjectId() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<20).map { _ in chars.randomElement()! })
    }
}
