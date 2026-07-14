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

    /// The five assignable Electra accent colors, plus white, for the palette
    /// picker.
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
        case fader, knob, vfader, pad, list, adsr, custom

        public var displayName: String {
            switch self {
            case .fader:  return "Fader"
            case .knob:   return "Knob"
            case .vfader: return "VFader"
            case .pad:    return "Pad"
            case .list:   return "List"
            case .adsr:   return "ADSR"
            case .custom: return "Custom (script)"
            }
        }

        var rawType: String {
            switch self {
            case .fader, .knob: return "fader"
            case .vfader:       return "vfader"
            case .pad:          return "pad"
            case .list:         return "list"
            case .adsr:         return "adsr"
            case .custom:       return "custom"
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
            case "custom": return .custom
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
        public var onValue: Int?
        public var offValue: Int?
        public var mode: String?
        public var valueCount: Int
        public var visible: Bool
        /// Name of the Lua function this control's value invokes, if any.
        public var functionName: String?

        public var kind: ControlKind { ControlKind.from(type: type, variant: variant) }

        /// A control bound to a Lua function (a "Script button").
        public var isScript: Bool { functionName?.isEmpty == false }

        /// A Custom control whose graphics are drawn by a Lua paint callback.
        public var isCustom: Bool { kind == .custom }
    }

    /// One value row on a control (faders have one; ADSR has four).
    public struct ControlValue: Identifiable, Hashable {
        public var id: String { valueId }
        public var valueId: String
        public var functionName: String?
        public var messageType: String?
        public var parameterNumber: Int?
        public var deviceId: Int?
        public var minValue: Int?
        public var maxValue: Int?
        public var onValue: Int?
        public var offValue: Int?
        public var defaultValue: Int?
    }

    /// A device entry from the preset `devices[]` array.
    public struct DeviceEntry: Identifiable, Hashable {
        public var id: Int
        public var name: String
        public var port: Int
        public var channel: Int
        public var rate: Int?
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
            onValue: firstMsg?["onValue"] as? Int,
            offValue: firstMsg?["offValue"] as? Int,
            mode: c["mode"] as? String,
            valueCount: values.count,
            visible: c["visible"] as? Bool ?? true,
            functionName: values.first?["function"] as? String
        )
    }

    public var devices: [DeviceEntry] {
        (root["devices"] as? [[String: Any]] ?? []).compactMap { d in
            guard let id = d["id"] as? Int else { return nil }
            return DeviceEntry(
                id: id,
                name: d["name"] as? String ?? "Device \(id)",
                port: d["port"] as? Int ?? 1,
                channel: d["channel"] as? Int ?? 1,
                rate: d["rate"] as? Int
            )
        }
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

    /// Bind or clear the Lua function on the primary value (`values[0].function`).
    /// Pass empty / whitespace to remove the binding.
    public mutating func setFunctionName(id: Int, _ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        mutateControl(id: id) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            if values.isEmpty { values = [["id": "value", "message": [String: Any]()]] }
            var v = values[0]
            if trimmed.isEmpty {
                v.removeValue(forKey: "function")
            } else {
                v["function"] = trimmed
            }
            values[0] = v
            c["values"] = values
        }
    }

    /// Bind physical pot 1…12, or pass `nil` to remove the input binding
    /// (soft-key / touch-only pads use no pot, or pots 9–12 on Mini).
    public mutating func setPotId(id: Int, _ potId: Int?) {
        mutateControl(id: id) { c in
            if let potId, (1...12).contains(potId) {
                c["inputs"] = [["potId": potId, "valueId": "value"]]
            } else {
                c.removeValue(forKey: "inputs")
            }
        }
    }

    /// Pad mode: `"momentary"`, `"toggle"`, or nil/empty to clear.
    public mutating func setControlMode(id: Int, _ mode: String?) {
        mutateControl(id: id) { c in
            let m = mode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if m.isEmpty {
                c.removeValue(forKey: "mode")
            } else {
                c["mode"] = m
            }
        }
    }

    public mutating func setOnValue(id: Int, _ value: Int?) {
        mutateFirstMessage(id: id) { m in
            if let value { m["onValue"] = value } else { m.removeValue(forKey: "onValue") }
        }
    }

    public mutating func setOffValue(id: Int, _ value: Int?) {
        mutateFirstMessage(id: id) { m in
            if let value { m["offValue"] = value } else { m.removeValue(forKey: "offValue") }
        }
    }

    public mutating func setMessageMinMax(id: Int, min: Int?, max: Int?) {
        mutateFirstMessage(id: id) { m in
            if let min { m["min"] = min } else { m.removeValue(forKey: "min") }
            if let max { m["max"] = max } else { m.removeValue(forKey: "max") }
        }
    }

    public mutating func setMessageDeviceId(id: Int, _ deviceId: Int) {
        mutateFirstMessage(id: id) { m in m["deviceId"] = deviceId }
    }

    private mutating func mutateFirstMessage(id: Int, _ body: (inout [String: Any]) -> Void) {
        mutateControl(id: id) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            if values.isEmpty { values = [["id": "value", "message": [String: Any]()]] }
            var v = values[0]
            var m = v["message"] as? [String: Any] ?? [:]
            body(&m)
            v["message"] = m
            values[0] = v
            c["values"] = values
        }
    }

    /// Rich read of every value row (for the multi-value inspector).
    public func controlValueDetails(id: Int) -> [ControlValue] {
        guard let controls = root["controls"] as? [[String: Any]],
              let c = controls.first(where: { ($0["id"] as? Int) == id }) else { return [] }
        let values = c["values"] as? [[String: Any]] ?? []
        return values.map { v in
            let m = v["message"] as? [String: Any]
            let def: Int?
            if let i = v["defaultValue"] as? Int { def = i }
            else if let s = v["defaultValue"] as? String, let i = Int(s) { def = i }
            else { def = nil }
            return ControlValue(
                valueId: v["id"] as? String ?? "value",
                functionName: v["function"] as? String,
                messageType: m?["type"] as? String,
                parameterNumber: m?["parameterNumber"] as? Int,
                deviceId: m?["deviceId"] as? Int,
                minValue: m?["min"] as? Int,
                maxValue: m?["max"] as? Int,
                onValue: m?["onValue"] as? Int,
                offValue: m?["offValue"] as? Int,
                defaultValue: def
            )
        }
    }

    /// Read each value's id + parameter number (ADSR has four).
    public func controlValues(id: Int) -> [(valueId: String, parameterNumber: Int?)] {
        controlValueDetails(id: id).map { ($0.valueId, $0.parameterNumber) }
    }

    /// Set the parameter number of a specific value by id (for multi-value
    /// controls like ADSR).
    public mutating func setValueParameterNumber(controlId: Int, valueId: String, _ number: Int) {
        mutateValueMessage(controlId: controlId, valueId: valueId) { m in
            m["parameterNumber"] = number
        }
    }

    public mutating func setValueMessageType(controlId: Int, valueId: String, _ type: String) {
        mutateValueMessage(controlId: controlId, valueId: valueId) { m in
            m["type"] = type
        }
    }

    public mutating func setValueFunctionName(controlId: Int, valueId: String, _ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        mutateControl(id: controlId) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            for i in values.indices where (values[i]["id"] as? String) == valueId {
                var v = values[i]
                if trimmed.isEmpty { v.removeValue(forKey: "function") }
                else { v["function"] = trimmed }
                values[i] = v
            }
            c["values"] = values
        }
    }

    public mutating func setValueMinMax(controlId: Int, valueId: String, min: Int?, max: Int?) {
        mutateValueMessage(controlId: controlId, valueId: valueId) { m in
            if let min { m["min"] = min } else { m.removeValue(forKey: "min") }
            if let max { m["max"] = max } else { m.removeValue(forKey: "max") }
        }
    }

    public mutating func setValueOnOff(controlId: Int, valueId: String, on: Int?, off: Int?) {
        mutateValueMessage(controlId: controlId, valueId: valueId) { m in
            if let on { m["onValue"] = on } else { m.removeValue(forKey: "onValue") }
            if let off { m["offValue"] = off } else { m.removeValue(forKey: "offValue") }
        }
    }

    private mutating func mutateValueMessage(
        controlId: Int, valueId: String, _ body: (inout [String: Any]) -> Void
    ) {
        let dev = (root["devices"] as? [[String: Any]])?.first?["id"] as? Int ?? 1
        mutateControl(id: controlId) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            for i in values.indices where (values[i]["id"] as? String) == valueId {
                var v = values[i]
                var m = v["message"] as? [String: Any]
                    ?? ["type": "cc7", "min": 0, "max": 127, "deviceId": dev]
                body(&m)
                v["message"] = m
                values[i] = v
            }
            c["values"] = values
        }
    }

    // ── Devices ──────────────────────────────────────────────────────────────

    public mutating func setDeviceName(id: Int, _ name: String) {
        mutateDevice(id: id) { $0["name"] = String(name.prefix(20)) }
    }

    public mutating func setDevicePort(id: Int, _ port: Int) {
        let p = max(1, min(2, port))
        mutateDevice(id: id) { $0["port"] = p }
    }

    public mutating func setDeviceChannel(id: Int, _ channel: Int) {
        let ch = max(1, min(16, channel))
        mutateDevice(id: id) { $0["channel"] = ch }
    }

    public mutating func setDeviceRate(id: Int, _ rate: Int?) {
        mutateDevice(id: id) { d in
            if let rate, rate >= 10 {
                d["rate"] = rate
            } else {
                d.removeValue(forKey: "rate")
            }
        }
    }

    private mutating func mutateDevice(id: Int, _ body: (inout [String: Any]) -> Void) {
        guard var devices = root["devices"] as? [[String: Any]] else { return }
        for i in devices.indices where (devices[i]["id"] as? Int) == id {
            var d = devices[i]
            body(&d)
            devices[i] = d
            break
        }
        root["devices"] = devices
    }

    /// Replace the entire root with parsed JSON (power-user raw editor).
    /// Returns false if the string is not a JSON object.
    public mutating func replaceRoot(fromJSON string: String) -> Bool {
        guard let data = string.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        // Preserve in-memory Lua (not stored in JSON root).
        let keepLua = lua
        root = obj
        lua = keepLua
        return true
    }

    /// Add a blank page at the end. Returns the new page id.
    @discardableResult
    public mutating func addPage(name: String? = nil) -> Int {
        var pages = root["pages"] as? [[String: Any]] ?? []
        let nextId = (pages.compactMap { $0["id"] as? Int }.max() ?? 0) + 1
        pages.append(["id": nextId, "name": name ?? "Page \(nextId)"])
        root["pages"] = pages
        return nextId
    }

    /// Mini usable design region (soft upper bound for layout guidance).
    public static let miniCanvasWidth: Double = 480
    public static let miniCanvasHeight: Double = 320

    /// Build the four ADSR inputs + CC values (attack/decay/sustain/release) —
    /// shared by `addControl` and `setControlKind`.
    private static func adsrInputsAndValues(basePot: Int, baseParameter: Int, deviceId: Int)
        -> (inputs: [[String: Any]], values: [[String: Any]]) {
        let inputs: [[String: Any]] = adsrValueIds.enumerated().map { i, vid in
            ["potId": min(12, basePot + i), "valueId": vid]
        }
        let values: [[String: Any]] = adsrValueIds.enumerated().map { i, vid in
            ["id": vid, "defaultValue": 0,
             "message": ["type": "cc7", "min": 0, "max": 127,
                         "parameterNumber": baseParameter + i, "deviceId": deviceId]]
        }
        return (inputs, values)
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
                let (inputs, values) = Self.adsrInputsAndValues(basePot: pot, baseParameter: base, deviceId: dev)
                c["inputs"] = inputs
                c["values"] = values
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
        // A connector with a dangling endpoint is meaningless — drop them along
        // with the control.
        if var conns = root[Self.connectorsKey] as? [[String: Any]] {
            conns.removeAll {
                ($0["fromControlId"] as? Int) == id || ($0["toControlId"] as? Int) == id
            }
            root[Self.connectorsKey] = conns
        }
    }

    /// Duplicate a control (all fields preserved, incl. ADSR values), offset
    /// slightly so the copy is visible. Returns the new control's id.
    @discardableResult
    public mutating func duplicateControl(id: Int) -> Int? {
        guard var controls = root["controls"] as? [[String: Any]],
              let src = controls.first(where: { ($0["id"] as? Int) == id }) else { return nil }
        var copy = src
        let newId = (controls.compactMap { $0["id"] as? Int }.max() ?? 0) + 1
        copy["id"] = newId
        if var b = (copy["bounds"] as? [Int]) ?? (copy["bounds"] as? [Double])?.map({ Int($0) }), b.count == 4 {
            b[0] = max(0, min(Int(Self.screenWidth) - b[2], b[0] + 24))
            b[1] = max(0, min(Int(Self.screenHeight) - b[3], b[1] + 24))
            copy["bounds"] = b
        }
        controls.append(copy)
        root["controls"] = controls
        return newId
    }

    // ── New-control bootstrap (shared by addControl/addScriptControl) ────────

    /// Everything a fresh control needs before its type-specific fields.
    private struct NewControlSeed {
        var id: Int
        var deviceId: Int
        var bounds: SlotGeometry.Bounds
        var pot: Int
        var controlSetId: Int
        var color: String
        var parameterNumber: Int
    }

    /// Allocate the next control id, resolve the device id, pick the first free
    /// grid slot, and derive pot/control-set/color plus a CC parameter number.
    private func newControlSeed(in controls: [[String: Any]], pageId: Int,
                                deviceId: Int?, span: Int, parameterCount: Int) -> NewControlSeed {
        let newId = (controls.compactMap { $0["id"] as? Int }.max() ?? 0) + 1
        let dev = deviceId ?? (root["devices"] as? [[String: Any]])?.first?["id"] as? Int ?? 1
        let slot = Self.firstFreeSlot(onPage: pageId, span: span, in: controls)
        let (col, row) = SlotGeometry.cell(forSlot: slot)
        var b = SlotGeometry.bounds(forSlot: slot)
        b.w += Double(span - 1) * SlotGeometry.pitchX
        return NewControlSeed(
            id: newId,
            deviceId: dev,
            bounds: b,
            pot: SlotGeometry.pot(col: col, row: row),
            controlSetId: SlotGeometry.controlSet(forRow: row),
            color: Self.palette[1 + (newId % (Self.palette.count - 1))],
            // Ids keep growing past the 0…127 CC range, so parameter numbers
            // are allocated independently (lowest unused wins).
            parameterNumber: Self.lowestUnusedParameter(count: parameterCount, in: controls))
    }

    /// First grid slot (1…36) on the page whose `span` columns are all free,
    /// judged from actual control bounds — a plain count would drift after
    /// deletions or wide (2-column) controls and cause overlaps.
    private static func firstFreeSlot(onPage pageId: Int, span: Int, in controls: [[String: Any]]) -> Int {
        var occupied = Set<Int>()
        for c in controls where (c["pageId"] as? Int) == pageId {
            guard let b = (c["bounds"] as? [Double]) ?? (c["bounds"] as? [Int])?.map(Double.init),
                  b.count == 4 else { continue }
            let slot = SlotGeometry.slot(forBounds: b[0], b[1])
            occupied.insert(slot)
            // Wide controls also occupy the extra columns they span.
            let extraCols = max(0, Int(((b[2] - SlotGeometry.slotWidth) / SlotGeometry.pitchX).rounded()))
            if extraCols > 0 {
                for k in 1...extraCols { occupied.insert(slot + k) }
            }
        }
        for slot in 1...SlotGeometry.slotsPerPage {
            let (col, _) = SlotGeometry.cell(forSlot: slot)
            guard col + span <= SlotGeometry.columns else { continue }   // don't wrap a row
            if (0..<span).allSatisfy({ !occupied.contains(slot + $0) }) { return slot }
        }
        return 1  // page full — overlap at the origin rather than fail
    }

    /// Lowest CC parameter number with `count` consecutive unused values,
    /// gathered from every message in the preset. Returns 0 if the space is
    /// exhausted.
    private static func lowestUnusedParameter(count: Int, in controls: [[String: Any]]) -> Int {
        var used = Set<Int>()
        for c in controls {
            for v in c["values"] as? [[String: Any]] ?? [] {
                if let m = v["message"] as? [String: Any], let p = m["parameterNumber"] as? Int {
                    used.insert(p)
                }
            }
        }
        search: for p in 1...(128 - count) {
            for k in 0..<count where used.contains(p + k) { continue search }
            return p
        }
        return 0
    }

    /// Add a fresh control of the given kind, placed in the next free grid cell.
    @discardableResult
    public mutating func addControl(kind: ControlKind = .fader, pageId: Int, deviceId: Int? = nil) -> Int {
        var controls = root["controls"] as? [[String: Any]] ?? []
        // Custom + ADSR span two columns (Custom to give the paint script room);
        // ADSR needs four consecutive CC numbers, one per value.
        let span = (kind == .custom || kind == .adsr) ? 2 : 1
        let seed = newControlSeed(in: controls, pageId: pageId, deviceId: deviceId,
                                  span: span, parameterCount: kind == .adsr ? 4 : 1)

        var control: [String: Any] = [
            "id": seed.id,
            "type": kind.rawType,
            "visible": true,
            "name": kind == .adsr ? "ADSR" : (kind == .custom ? "Custom" : "CC #\(seed.parameterNumber)"),
            "color": seed.color,
            "pageId": pageId,
            "controlSetId": seed.controlSetId,
            "bounds": seed.bounds.array,
        ]
        if let v = kind.rawVariant { control["variant"] = v }

        if kind == .custom {
            // A Custom control's value is a *virtual* parameter (no MIDI
            // mapping) — this mirrors the working custom-control format the
            // Electra One editor produces; a `cc7` value here leaves the
            // control non-custom and blank on device.
            control["inputs"] = [["potId": seed.pot, "valueId": "value"]]
            control["values"] = [[
                "id": "value", "defaultValue": 0,
                "message": ["type": "virtual", "parameterNumber": seed.parameterNumber, "deviceId": seed.deviceId],
            ]]
        } else if kind == .adsr {
            // ADSR carries four CC values.
            let (inputs, values) = Self.adsrInputsAndValues(
                basePot: seed.pot, baseParameter: seed.parameterNumber, deviceId: seed.deviceId)
            control["inputs"] = inputs
            control["values"] = values
        } else {
            control["inputs"] = [["potId": seed.pot, "valueId": "value"]]
            control["values"] = [[
                "id": "value", "defaultValue": 0,
                "message": ["type": "cc7", "min": 0, "max": 127, "parameterNumber": seed.parameterNumber, "deviceId": seed.deviceId],
            ]]
        }

        controls.append(control)
        root["controls"] = controls
        return seed.id
    }

    /// The conventional Lua function name for a script button with the given id.
    public static func scriptFunctionName(forControlId id: Int) -> String {
        "scriptBtn_\(id)"
    }

    /// The conventional Lua paint-callback function name for a Custom control.
    public static func paintFunctionName(forControlId id: Int) -> String {
        "paint_\(id)"
    }

    /// A starter paint callback (and its registration) for a new Custom control:
    /// draws a value bar so the control shows something from the first frame.
    /// Shared by the app (seeding) and tests so both use identical Lua.
    public static func customPaintStarter(controlId id: Int, colorHex: String) -> String {
        let fn = paintFunctionName(forControlId: id)
        // Sanitize: colors can arrive as "#F20530" etc. Keep only hex digits,
        // falling back to white when nothing valid remains — anything else
        // would produce a Lua syntax error.
        let cleaned = colorHex.uppercased().filter(\.isHexDigit)
        let hex = "0x" + (cleaned.isEmpty ? "FFFFFF" : cleaned)
        return """
        -- Custom control \(id): draws its own graphics via a paint callback.
        -- Coordinates are LOCAL to the control (0,0 = its top-left corner).
        -- Edit freely — the in-app canvas updates as you type.
        function \(fn)(display)
          local b = display:getBounds()
          local w, h = b[WIDTH], b[HEIGHT]
          graphics.setColor(0x1A1A20)          -- background
          graphics.fillRect(0, 0, w, h)
          graphics.setColor(\(hex))            -- filled body
          graphics.fillRoundRect(4, 4, w - 8, h - 8, 6)
          graphics.setColor(WHITE)
          graphics.print(0, h / 2 - 6, "CUSTOM", w, CENTER)
        end

        -- Register the paint callback in preset.onLoad and force the first paint
        -- with repaint() — this matches the format the Electra One editor produces
        -- for custom controls (registering at top level alone draws nothing).
        function preset.onLoad()
          local c = controls.get(\(id))
          c:setPaintCallback(\(fn))
          c:repaint()
        end
        """
    }

    /// Add a "Script button": a `pad` whose value invokes a Lua function. Placed
    /// in the next free grid cell like `addControl`. The referenced function is
    /// expected to live in the preset's Lua script. Returns the new control's id.
    @discardableResult
    public mutating func addScriptControl(pageId: Int, deviceId: Int? = nil) -> Int {
        var controls = root["controls"] as? [[String: Any]] ?? []
        let seed = newControlSeed(in: controls, pageId: pageId, deviceId: deviceId,
                                  span: 1, parameterCount: 1)

        let control: [String: Any] = [
            "id": seed.id,
            "type": "pad",
            "mode": "momentary",
            "visible": true,
            "name": "Script",
            "color": seed.color,
            "pageId": pageId,
            "controlSetId": seed.controlSetId,
            "bounds": seed.bounds.array,
            "inputs": [["potId": seed.pot, "valueId": "value"]],
            "values": [[
                "id": "value",
                "function": Self.scriptFunctionName(forControlId: seed.id),
                "message": ["type": "cc7", "onValue": 127, "offValue": 0,
                            "parameterNumber": seed.parameterNumber, "deviceId": seed.deviceId],
            ]],
        ]

        controls.append(control)
        root["controls"] = controls
        return seed.id
    }

    public mutating func renamePage(id: Int, to name: String) {
        guard var pages = root["pages"] as? [[String: Any]] else { return }
        for i in pages.indices where (pages[i]["id"] as? Int) == id {
            pages[i]["name"] = name
        }
        root["pages"] = pages
    }

    // ── Connectors (editor-only board arrows) ────────────────────────────────

    /// Where a connector arrow points: another control, or a page (a "sub-page
    /// link" — e.g. a pad that conceptually opens page 3).
    public enum ConnectorTarget: Hashable, Sendable {
        case control(Int)
        case page(Int)
    }

    /// A FigJam/OmniGraffle-style arrow on the design canvas. Connectors are an
    /// editor annotation, not part of the Electra preset schema — they persist
    /// in saved files but are stripped from device uploads (see `jsonString`).
    public struct Connector: Identifiable, Hashable {
        public var id: Int
        public var fromControlId: Int
        public var target: ConnectorTarget
        public var label: String
        public var colorHex: String
    }

    static let connectorsKey = "connectors"

    public var connectors: [Connector] {
        (root[Self.connectorsKey] as? [[String: Any]] ?? []).compactMap { c in
            guard let id = c["id"] as? Int,
                  let from = c["fromControlId"] as? Int else { return nil }
            let target: ConnectorTarget
            if let t = c["toControlId"] as? Int { target = .control(t) }
            else if let p = c["toPageId"] as? Int { target = .page(p) }
            else { return nil }
            return Connector(id: id, fromControlId: from, target: target,
                             label: c["label"] as? String ?? "",
                             colorHex: c["color"] as? String ?? "FFFFFF")
        }
    }

    /// Connectors that render on a page: those whose source control lives there.
    public func connectors(onPage pageId: Int) -> [Connector] {
        let ids = Set(controls(onPage: pageId).map(\.id))
        return connectors.filter { ids.contains($0.fromControlId) }
    }

    public func connector(id: Int) -> Connector? {
        connectors.first { $0.id == id }
    }

    /// Add a connector arrow. Exact duplicates (same source and target) return
    /// the existing connector's id instead of stacking a second arrow.
    @discardableResult
    public mutating func addConnector(fromControlId: Int, to target: ConnectorTarget,
                                      colorHex: String = "FFFFFF") -> Int {
        if let existing = connectors.first(where: { $0.fromControlId == fromControlId && $0.target == target }) {
            return existing.id
        }
        var arr = root[Self.connectorsKey] as? [[String: Any]] ?? []
        let newId = (arr.compactMap { $0["id"] as? Int }.max() ?? 0) + 1
        var c: [String: Any] = ["id": newId, "fromControlId": fromControlId,
                                "label": "", "color": colorHex]
        switch target {
        case .control(let t): c["toControlId"] = t
        case .page(let p):    c["toPageId"] = p
        }
        arr.append(c)
        root[Self.connectorsKey] = arr
        return newId
    }

    public mutating func removeConnector(id: Int) {
        guard var arr = root[Self.connectorsKey] as? [[String: Any]] else { return }
        arr.removeAll { ($0["id"] as? Int) == id }
        root[Self.connectorsKey] = arr
    }

    private mutating func mutateConnector(id: Int, _ body: (inout [String: Any]) -> Void) {
        guard var arr = root[Self.connectorsKey] as? [[String: Any]] else { return }
        for i in arr.indices where (arr[i]["id"] as? Int) == id {
            var c = arr[i]
            body(&c)
            arr[i] = c
            break
        }
        root[Self.connectorsKey] = arr
    }

    public mutating func setConnectorLabel(id: Int, _ label: String) {
        mutateConnector(id: id) { $0["label"] = label }
    }

    public mutating func setConnectorColor(id: Int, hex: String) {
        mutateConnector(id: id) { $0["color"] = hex }
    }

    /// Flip a control→control connector's direction. Page links have no
    /// meaningful reverse, so they're left untouched.
    public mutating func reverseConnector(id: Int) {
        mutateConnector(id: id) { c in
            guard let from = c["fromControlId"] as? Int,
                  let to = c["toControlId"] as? Int else { return }
            c["fromControlId"] = to
            c["toControlId"] = from
        }
    }

    // ── Serialization ──────────────────────────────────────────────────────

    /// `forDevice: true` strips editor-only keys (connectors) so the upload is
    /// exactly the schema the firmware knows; file saves keep everything.
    public func jsonString(pretty: Bool = false, forDevice: Bool = false) -> String {
        var obj = root
        if forDevice { obj.removeValue(forKey: Self.connectorsKey) }
        let opts: JSONSerialization.WritingOptions = pretty ? [.prettyPrinted, .sortedKeys] : []
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: opts),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    // ── Templates ────────────────────────────────────────────────────────────

    /// The default device entry used when a preset (or imported project)
    /// declares none. Shared with ProjectImport.
    static let defaultDevice: [String: Any] = [
        "id": 1, "name": "MIDI Device 1", "port": 1, "channel": 1,
    ]

    public static func newPreset(name: String = "New Preset") -> PresetDocument {
        let root: [String: Any] = [
            "version": 2,
            "name": name,
            "projectId": Self.makeProjectId(),
            "pages": [
                ["id": 1, "name": "Page 1"],
                ["id": 2, "name": "Page 2"],
            ],
            "devices": [Self.defaultDevice],
            "groups": [[String: Any]](),
            "overlays": [[String: Any]](),
            "controls": [[String: Any]](),
        ]
        return PresetDocument(root: root)
    }

    /// 20-char alphanumeric project id (the format the web editor generates).
    /// Internal so ProjectImport can mint ids without building a whole preset.
    static func makeProjectId() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        return String((0..<20).map { _ in chars[Int.random(in: 0..<chars.count)] })
    }
}
