import Foundation

/// High-level Electra One operations. An actor, so every exchange is
/// serialized — which is exactly the single-in-flight guarantee the transport
/// relies on. Mirrors lib/device.js.
public actor E1Device {
    private let transport: MIDITransport

    public init(transport: MIDITransport = MIDITransport()) {
        self.transport = transport
    }

    @discardableResult
    public func connect() throws -> PortNames {
        try transport.connect()
    }

    public func disconnect() {
        transport.disconnect()
    }

    public var isConnected: Bool { transport.connected }

    // ── Info ──────────────────────────────────────────────────────────────

    public func getInfo() async throws -> DeviceInfo {
        let (_, payload) = try await transport.query(E1Proto.infoRequest())
        return try JSONDecoder().decode(DeviceInfo.self, from: Data(payload))
    }

    // ── Presets ───────────────────────────────────────────────────────────

    /// Raw preset JSON text for a slot (or the active slot when nil).
    /// Throws `.empty` for empty slots.
    public func getPresetRaw(bank: Int?, slot: Int?) async throws -> String {
        let (_, payload) = try await transport.query(E1Proto.presetRequest(bank: bank, slot: slot))
        if payload.isEmpty { throw E1Error.empty }
        guard let text = String(bytes: payload, encoding: .utf8) else {
            throw E1Error.decode("preset is not valid text")
        }
        return text
    }

    /// Pretty-printed preset JSON for a slot (best effort: returns raw text if
    /// it can't be re-serialized).
    public func getPresetPretty(bank: Int?, slot: Int?) async throws -> String {
        let raw = try await getPresetRaw(bank: bank, slot: slot)
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let s = String(data: pretty, encoding: .utf8)
        else { return raw }
        return s
    }

    /// Upload preset JSON. When bank/slot are given, arms that slot first
    /// (uploads always target the active slot).
    public func putPreset(json: String, bank: Int?, slot: Int?) async throws {
        if let b = bank, let s = slot {
            try await transport.command(E1Proto.presetSlotSelect(bank: b, slot: s))
        }
        try await transport.command(E1Proto.presetUpload(json: json))
    }

    public func getLua(bank: Int?, slot: Int?) async throws -> String {
        let (_, payload) = try await transport.query(E1Proto.luaRequest(bank: bank, slot: slot))
        return String(bytes: payload, encoding: .utf8) ?? ""
    }

    /// Upload a preset and (optionally) its Lua script to a slot. Arms the slot
    /// first, sends the preset, then the Lua — matching how the web editor
    /// publishes a project.
    public func putProject(json: String, lua: String?, bank: Int?, slot: Int?) async throws {
        if let b = bank, let s = slot {
            try await transport.command(E1Proto.presetSlotSelect(bank: b, slot: s))
        }
        try await transport.command(E1Proto.presetUpload(json: json))
        if let lua, !lua.isEmpty {
            try await transport.command(E1Proto.luaUpload(source: lua))
        }
    }

    /// Arm a slot as the target for subsequent uploads (does not load it).
    public func switchSlot(bank: Int, slot: Int) async throws {
        try await transport.command(E1Proto.presetSlotSelect(bank: bank, slot: slot))
    }

    /// Activate a slot: the controller switches to it and loads its preset (and
    /// any associated Lua / overrides / performance). Use after an upload to make
    /// the just-written preset the live one.
    public func activateSlot(bank: Int, slot: Int) async throws {
        try await transport.command(E1Proto.presetSlotSwitch(bank: bank, slot: slot))
    }

    /// Permanently clear a preset slot on the device (preset + Lua). Frees a
    /// burned/corrupt slot.
    public func clearSlot(bank: Int, slot: Int) async throws {
        try await transport.command(E1Proto.clearSlot(bank: bank, slot: slot))
    }

    // ── Scanning ──────────────────────────────────────────────────────────

    /// Scan a single slot. Empty/timeout → `.empty`; malformed → `.error`.
    public func scanSlot(bank: Int, slot: Int, timeout: TimeInterval = 1.5) async -> SlotState {
        do {
            let (_, payload) = try await transport.query(
                E1Proto.presetRequest(bank: bank, slot: slot), timeout: timeout)
            if payload.isEmpty {
                return SlotState(slot: slot, status: .empty)
            }
            let summary = try Self.summarize(payload)
            return SlotState(slot: slot, status: .ok, name: summary.name)
        } catch E1Error.empty, E1Error.timeout {
            return SlotState(slot: slot, status: .empty)
        } catch {
            let msg = (error as? E1Error)?.description ?? "\(error)"
            return SlotState(slot: slot, status: .error, error: msg)
        }
    }

    // ── Parsing ───────────────────────────────────────────────────────────

    public func summarize(bank: Int?, slot: Int?) async throws -> PresetSummary {
        let (_, payload) = try await transport.query(E1Proto.presetRequest(bank: bank, slot: slot))
        if payload.isEmpty { throw E1Error.empty }
        return try Self.summarize(payload)
    }

    static func summarize(_ payload: [UInt8]) throws -> PresetSummary {
        guard let obj = try JSONSerialization.jsonObject(with: Data(payload)) as? [String: Any] else {
            throw E1Error.decode("preset is not a JSON object")
        }
        let devices = obj["devices"] as? [[String: Any]] ?? []
        return PresetSummary(
            name: obj["name"] as? String ?? "(unnamed)",
            version: obj["version"] as? Int,
            projectId: obj["projectId"] as? String,
            pages: (obj["pages"] as? [Any])?.count ?? 0,
            controls: (obj["controls"] as? [Any])?.count ?? 0,
            devices: devices.count,
            deviceNames: devices.compactMap { $0["name"] as? String }
        )
    }

    /// Summarize raw JSON text (used by the UI after an edit/preview).
    public static func summarize(text: String) -> PresetSummary? {
        guard let data = text.data(using: .utf8),
              let s = try? summarize(Array(data)) else { return nil }
        return s
    }
}
