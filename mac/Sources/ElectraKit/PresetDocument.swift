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

    /// Electra One logical screen size (preset coordinate space).
    public static let screenWidth: Double = 1024
    public static let screenHeight: Double = 575

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
        public var visible: Bool
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

    public mutating func removeControl(id: Int) {
        guard var controls = root["controls"] as? [[String: Any]] else { return }
        controls.removeAll { ($0["id"] as? Int) == id }
        root["controls"] = controls
    }

    /// Add a fresh fader control on a page, placed in the next free grid cell.
    @discardableResult
    public mutating func addControl(pageId: Int, deviceId: Int? = nil) -> Int {
        var controls = root["controls"] as? [[String: Any]] ?? []
        let newId = (controls.compactMap { $0["id"] as? Int }.max() ?? 0) + 1
        let dev = deviceId ?? (root["devices"] as? [[String: Any]])?.first?["id"] as? Int ?? 1

        // Place into a 6-col × 4-row grid.
        let used = controls.filter { ($0["pageId"] as? Int) == pageId }.count
        let cols = 6, rows = 4
        let idx = used % (cols * rows)
        let col = idx % cols, row = idx / cols
        let cw = Self.screenWidth / Double(cols), rh = Self.screenHeight / Double(rows)
        let bx = Int((Double(col) * cw + 10).rounded())
        let by = Int((Double(row) * rh + 12).rounded())
        let bw = Int((cw - 20).rounded())
        let bh = Int((rh - 24).rounded())
        let potId = (used % 12) + 1

        let control: [String: Any] = [
            "id": newId,
            "type": "fader",
            "variant": "dial",
            "visible": true,
            "name": "CC #\(newId)",
            "color": Self.palette[1 + (newId % (Self.palette.count - 1))],
            "bounds": [bx, by, bw, bh],
            "pageId": pageId,
            "controlSetId": 1,
            "inputs": [["potId": potId, "valueId": "value"]],
            "values": [[
                "message": ["type": "cc7", "min": 0, "max": 127, "parameterNumber": newId, "deviceId": dev],
                "defaultValue": 0,
                "id": "value",
            ]],
        ]
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
