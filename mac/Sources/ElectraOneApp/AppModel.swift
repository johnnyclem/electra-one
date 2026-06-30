import Foundation
import SwiftUI
import UniformTypeIdentifiers
import ElectraKit
import LuaKit

/// UI state + orchestration. Published state lives on the main actor; MIDI work
/// happens on the `E1Device` actor. The app is document-centric: it always
/// edits a `PresetDocument`, which may originate from the device, a file, or a
/// fresh template. A device is optional — the editor works fully offline.
@MainActor
final class AppModel: ObservableObject {
    enum ConnectionState: Equatable {
        case connecting, ready, offline(String)
    }

    let slotsPerBank = 12
    let bankCount = 6

    private let device = E1Device()

    // Device
    @Published var connection: ConnectionState = .connecting
    @Published var info: DeviceInfo?
    @Published var portName: String = ""
    @Published var bank: Int = 0
    @Published var slots: [SlotState] = []
    @Published var openSlot: Int? = nil          // which device slot is loaded

    // Open document
    @Published var document: PresetDocument?
    @Published var fileURL: URL?
    @Published var deviceSlot: (bank: Int, slot: Int)?
    @Published var dirty = false
    @Published var currentPageId: Int = 1
    @Published var selectedControlId: Int? = nil

    // Status
    @Published var busy = false
    @Published var message: String = ""

    // ── Lua script editor ────────────────────────────────────────────────────
    enum EditorMode { case design, script }
    @Published var editorMode: EditorMode = .design
    @Published var luaSource: String = AppModel.sampleScript
    @Published var luaConsole: String = ""
    private let lua = LuaEngine()

    // AI script generation
    @Published var aiPrompt: String = ""
    @Published var aiBusy = false
    @Published var aiBarPresented = false
    @Published var aiSettingsPresented = false
    @Published var apiKeyPresent = Keychain.hasKey
    @Published var aiBaseURL: String = UserDefaults.standard.string(forKey: "aiBaseURL") ?? AIClient.defaultBaseURL {
        didSet { UserDefaults.standard.set(aiBaseURL, forKey: "aiBaseURL") }
    }
    @Published var aiModel: String = UserDefaults.standard.string(forKey: "aiModel") ?? AIClient.defaultModel {
        didSet { UserDefaults.standard.set(aiModel, forKey: "aiModel") }
    }

    static let sampleScript = """
    -- Electra One Lua. Build to syntax-check, Run to preview here.
    -- Device APIs (controls, midi, parameterMap, timer, …) are mocked offline.
    print("Hello from Electra One!")

    function onReady()
      print("controller:", controller.getModel())
      info.setText("ready")
    end
    """

    // Save-to-device sheet
    @Published var savePickerPresented = false
    @Published var saveBank = 0
    @Published var saveSlot = 0

    // Undo / redo (document snapshots)
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    private var undoStack: [PresetDocument] = []
    private var redoStack: [PresetDocument] = []
    private let undoLimit = 100

    private var scanToken = 0

    enum AlignEdge { case left, centerH, right, top, centerV, bottom }

    init() {
        slots = (0..<slotsPerBank).map { SlotState(slot: $0, status: .unknown) }
    }

    var isConnected: Bool { if case .ready = connection { return true }; return false }

    var luaInfo: String? {
        guard let lua = document?.lua, !lua.isEmpty else { return nil }
        let lines = lua.split(whereSeparator: \.isNewline).count
        return "Lua script · \(lines) lines"
    }

    var documentTitle: String {
        guard let doc = document else { return "No preset open" }
        return doc.name.isEmpty ? "(unnamed)" : doc.name
    }

    var subtitle: String {
        var parts: [String] = []
        if let s = deviceSlot { parts.append("bank \(s.bank) · slot \(s.slot)") }
        if let u = fileURL { parts.append(u.lastPathComponent) }
        if dirty { parts.append("• edited") }
        return parts.joined(separator: "  ·  ")
    }

    // ── Connection (non-fatal) ─────────────────────────────────────────────

    func start() {
        Task {
            do {
                let ports = try await device.connect()
                portName = ports.input
                info = try await device.getInfo()
                connection = .ready
                rescan()
            } catch {
                connection = .offline(describe(error))
            }
        }
    }

    func reconnect() {
        connection = .connecting
        start()
    }

    func shutdown() { Task { await device.disconnect() } }

    // ── Device browser ───────────────────────────────────────────────────

    func setBank(_ newBank: Int) {
        guard newBank != bank, newBank >= 0, newBank < bankCount else { return }
        bank = newBank
        rescan()
    }

    func rescan() {
        guard isConnected else { return }
        scanToken += 1
        let token = scanToken
        let targetBank = bank
        slots = (0..<slotsPerBank).map { SlotState(slot: $0, status: .scanning) }
        Task {
            for slot in 0..<slotsPerBank {
                let result = await device.scanSlot(bank: targetBank, slot: slot)
                if token != scanToken { return }
                slots[slot] = result
            }
            if token == scanToken { message = "Scanned bank \(targetBank)." }
        }
    }

    /// Permanently clear a device slot (preset + Lua). For freeing burned or
    /// corrupt slots. Callers should confirm first — this can't be undone.
    func clearSlot(_ slot: Int) {
        guard isConnected else { return }
        let b = bank
        run("Clearing bank \(b), slot \(slot)…") {
            try await self.device.clearSlot(bank: b, slot: slot)
            if self.openSlot == slot {
                self.openSlot = nil
                if self.deviceSlot?.bank == b && self.deviceSlot?.slot == slot {
                    self.deviceSlot = nil
                }
            }
            self.rescan()
            return "Cleared bank \(b), slot \(slot)."
        }
    }

    func openFromSlot(_ slot: Int) {
        guard isConnected else { return }
        openSlot = slot
        let targetBank = bank
        busy = true
        message = "Loading bank \(targetBank), slot \(slot)…"
        Task {
            do {
                let raw = try await device.getPresetRaw(bank: targetBank, slot: slot)
                guard var doc = PresetDocument(jsonString: raw) else {
                    throw E1Error.decode("This slot's data isn't valid preset JSON.")
                }
                // Preserve any Lua so a later Save to Device doesn't drop it.
                if let lua = try? await device.getLua(bank: targetBank, slot: slot), !lua.isEmpty {
                    doc.lua = lua
                }
                loadDocument(doc, fileURL: nil, deviceSlot: (targetBank, slot))
                message = "Opened \"\(doc.name)\"."
            } catch let e as E1Error where isEmpty(e) {
                message = "Slot \(slot) is empty. Use New Preset to build one, then Save to Device."
            } catch {
                message = "Error: \(describe(error))"
            }
            busy = false
        }
    }

    // ── Document lifecycle ──────────────────────────────────────────────────

    private func loadDocument(_ doc: PresetDocument, fileURL: URL?, deviceSlot: (Int, Int)?) {
        document = doc
        self.fileURL = fileURL
        self.deviceSlot = deviceSlot.map { (bank: $0.0, slot: $0.1) }
        currentPageId = doc.pages.first?.id ?? 1
        selectedControlId = nil
        dirty = false
        undoStack.removeAll()
        redoStack.removeAll()
        refreshUndoFlags()
        if let l = doc.lua, !l.isEmpty { luaSource = l }
    }

    // ── Lua editor actions ───────────────────────────────────────────────────

    /// Edit the script. Kept in sync with the open preset's Lua (no undo entry)
    /// so Save / Push to Device include it automatically.
    func setLuaSource(_ s: String) {
        luaSource = s
        if var d = document {
            d.lua = s.isEmpty ? nil : s
            document = d
            dirty = true
        }
    }

    func luaBuild() {
        if let err = lua.check(luaSource) {
            appendConsole("✗ Build failed:\n\(err)")
        } else {
            appendConsole("✓ Build OK — no syntax errors.")
        }
    }

    func luaRun() {
        appendConsole("▶ Run")
        let result = lua.run(luaSource)
        if !result.output.isEmpty { appendConsole(result.output, raw: true) }
        if let err = result.error {
            appendConsole("✗ \(err)")
        } else {
            appendConsole("✓ finished")
        }
    }

    func clearConsole() { luaConsole = "" }

    func importLua() {
        let panel = NSOpenPanel()
        var types: [UTType] = []
        if let lua = UTType(filenameExtension: "lua") { types.append(lua) }
        types.append(.plainText)
        panel.allowedContentTypes = types
        panel.allowsOtherFileTypes = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            setLuaSource(try String(contentsOf: url, encoding: .utf8))
            message = "Imported \(url.lastPathComponent)."
        } catch {
            message = "Error: \(error.localizedDescription)"
        }
    }

    func exportLua() {
        let panel = NSSavePanel()
        if let lua = UTType(filenameExtension: "lua") { panel.allowedContentTypes = [lua] }
        panel.nameFieldStringValue = "\(document?.name.isEmpty == false ? document!.name : "script").lua"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try luaSource.write(to: url, atomically: true, encoding: .utf8)
            message = "Saved → \(url.path)"
        } catch { message = "Save failed: \(error.localizedDescription)" }
    }

    private func appendConsole(_ text: String, raw: Bool = false) {
        if !luaConsole.isEmpty { luaConsole += "\n" }
        luaConsole += raw ? text : text
    }

    // ── AI generation ────────────────────────────────────────────────────────

    func saveAPIKey(_ key: String) {
        Keychain.setAPIKey(key.trimmingCharacters(in: .whitespacesAndNewlines))
        apiKeyPresent = Keychain.hasKey
    }

    func clearAPIKey() {
        Keychain.clear()
        apiKeyPresent = false
    }

    /// Compact list of the open preset's controls, so generated scripts can
    /// reference real control ids.
    private var presetControlContext: String? {
        guard let doc = document else { return nil }
        let lines = doc.allControls().prefix(48).map { c -> String in
            let name = c.name.isEmpty ? "(unnamed)" : c.name
            return "  \(c.id) — \(name) [\(c.kind.displayName)]"
        }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    func generateScript() {
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        // API key is optional — local servers (Ollama, LM Studio) don't need one.
        let key = Keychain.apiKey()
        let base = aiBaseURL
        let model = aiModel
        let ctx = presetControlContext
        aiBusy = true
        luaSource = "" // clear; tokens stream in live
        appendConsole("✨ Streaming with \(model) @ \(base): \(prompt)")
        var reasonedShown = false
        Task {
            do {
                let lua = try await AIClient.streamLua(
                    request: prompt, presetContext: ctx, baseURL: base, model: model, apiKey: key,
                    onText: { soFar in await MainActor.run { self.luaSource = soFar } },
                    onReasoning: { _ in
                        // Reasoning models (ornith, deepseek-r1, qwen3…) think before
                        // answering — surface a one-time note so it doesn't look frozen.
                        await MainActor.run {
                            if !reasonedShown {
                                reasonedShown = true
                                self.appendConsole("🧠 Model is reasoning… (the script streams in once it finishes thinking)")
                            }
                        }
                    })
                // Commit the final (fence-stripped) source to the document + undo/dirty.
                setLuaSource(lua)
                appendConsole("✓ Script generated (\(lua.split(separator: "\n").count) lines). Review, Build, and Run.")
                aiPrompt = ""
            } catch {
                let msg = (error as? AIClient.AIError)?.description ?? error.localizedDescription
                appendConsole("✗ AI error: \(msg)")
                message = "AI error: \(msg)"
            }
            aiBusy = false
        }
    }

    func newDocument() {
        loadDocument(.newPreset(), fileURL: nil, deviceSlot: nil)
        openSlot = nil
        message = "New preset."
    }

    func openFile() {
        let panel = NSOpenPanel()
        var types: [UTType] = [.json]
        if let eproj = UTType(filenameExtension: "eproj") { types.append(eproj) }
        if let epr = UTType(filenameExtension: "epr") { types.append(epr) }
        panel.allowedContentTypes = types
        panel.allowsOtherFileTypes = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let wasProject = PresetDocument.isProject(text)
            guard let doc = PresetDocument.load(fileText: text) else {
                message = "Error: not a valid Electra preset or project file."
                return
            }
            // A project converts to a new preset; don't tie it to the source file.
            loadDocument(doc, fileURL: wasProject ? nil : url, deviceSlot: nil)
            openSlot = nil
            if wasProject {
                let n = doc.allControls().count
                let luaNote = doc.lua != nil ? " (with Lua script)" : ""
                message = "Imported project “\(doc.name)” — \(n) control(s)\(luaNote)."
            } else {
                message = "Opened \(url.lastPathComponent)."
            }
        } catch {
            message = "Error: \(error.localizedDescription)"
        }
    }

    func saveToFile() {
        guard let doc = document else { return }
        let url: URL
        if let existing = fileURL {
            url = existing
        } else {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = PresetNaming.fileName(for: doc.name)
            panel.canCreateDirectories = true
            guard panel.runModal() == .OK, let chosen = panel.url else { return }
            url = chosen
        }
        do {
            try doc.jsonString(pretty: true).write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            dirty = false
            message = "Saved → \(url.path)"
        } catch {
            message = "Save failed: \(error.localizedDescription)"
        }
    }

    func saveToFileAs() {
        fileURL = nil
        saveToFile()
    }

    func presentSaveToDevice() {
        guard document != nil else { return }
        if let s = deviceSlot { saveBank = s.bank; saveSlot = s.slot }
        else { saveBank = bank; saveSlot = 0 }
        savePickerPresented = true
    }

    func confirmSaveToDevice() {
        savePickerPresented = false
        guard isConnected, let doc = document else {
            message = "Connect an Electra One to save to the device."
            return
        }
        let json = doc.jsonString(pretty: false)
        let lua = doc.lua
        let b = saveBank, s = saveSlot
        let luaNote = (lua?.isEmpty == false) ? " + Lua" : ""
        run("Uploading \"\(doc.name)\"\(luaNote) → bank \(b), slot \(s)…") {
            try await self.device.putProject(json: json, lua: lua, bank: b, slot: s)
            self.deviceSlot = (bank: b, slot: s)
            self.dirty = false
            if self.bank == b { self.rescan() }
            return "Saved \"\(doc.name)\"\(luaNote) → bank \(b), slot \(s)."
        }
    }

    // ── Editing ─────────────────────────────────────────────────────────────

    var currentControls: [PresetDocument.Control] {
        document?.controls(onPage: currentPageId) ?? []
    }

    var selectedControl: PresetDocument.Control? {
        guard let id = selectedControlId else { return nil }
        return document?.control(id: id)
    }

    /// Single mutation funnel. Snapshots the document for undo before applying.
    private func edit(_ body: (inout PresetDocument) -> Void) {
        guard var doc = document else { return }
        undoStack.append(doc)
        if undoStack.count > undoLimit { undoStack.removeFirst() }
        redoStack.removeAll()
        body(&doc)
        document = doc
        dirty = true
        refreshUndoFlags()
    }

    private func refreshUndoFlags() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    func undo() {
        guard let prev = undoStack.popLast(), let current = document else { return }
        redoStack.append(current)
        document = prev
        dirty = true
        if let id = selectedControlId, prev.control(id: id) == nil { selectedControlId = nil }
        refreshUndoFlags()
        message = "Undo."
    }

    func redo() {
        guard let next = redoStack.popLast(), let current = document else { return }
        undoStack.append(current)
        document = next
        dirty = true
        refreshUndoFlags()
        message = "Redo."
    }

    func setControlName(_ id: Int, _ name: String) { edit { $0.setControlName(id: id, name) } }
    func setControlColor(_ id: Int, hex: String) { edit { $0.setControlColor(id: id, hex: hex) } }
    func setControlType(_ id: Int, _ type: String) { edit { $0.setControlType(id: id, type) } }
    func setControlParameterNumber(_ id: Int, _ n: Int) { edit { $0.setMessageParameterNumber(id: id, n) } }
    func setControlMessageType(_ id: Int, _ t: String) { edit { $0.setMessageType(id: id, t) } }

    func setControlBounds(_ id: Int, x: Double, y: Double, w: Double, h: Double) {
        edit { $0.setControlBounds(id: id, x: x, y: y, w: w, h: h) }
    }

    func setPresetName(_ name: String) { edit { $0.name = name } }
    func renamePage(_ id: Int, _ name: String) { edit { $0.renamePage(id: id, to: name) } }

    func addControl(kind: PresetDocument.ControlKind = .fader) {
        edit { doc in
            let newId = doc.addControl(kind: kind, pageId: currentPageId)
            DispatchQueue.main.async { self.selectedControlId = newId }
        }
        message = "Added \(kind.displayName)."
    }

    func setControlKind(_ id: Int, _ kind: PresetDocument.ControlKind) {
        edit { $0.setControlKind(id: id, kind) }
    }

    func setValueParameterNumber(_ controlId: Int, valueId: String, _ n: Int) {
        edit { $0.setValueParameterNumber(controlId: controlId, valueId: valueId, n) }
    }

    func deleteSelectedControl() {
        guard let id = selectedControlId else { return }
        deleteControls([id])
    }

    func deleteControls(_ ids: [Int]) {
        guard !ids.isEmpty else { return }
        edit { doc in for id in ids { doc.removeControl(id: id) } }
        if let s = selectedControlId, ids.contains(s) { selectedControlId = nil }
        message = ids.count == 1 ? "Deleted control." : "Deleted \(ids.count) controls."
    }

    /// Move several controls by the same delta in one undo step (used for
    /// multi-select drag). Optionally snaps each control's origin to the
    /// nearest 6×6 slot.
    func moveControls(_ ids: [Int], dx: Double, dy: Double, snap: Bool = false) {
        guard !ids.isEmpty else { return }
        let maxX = PresetDocument.screenWidth, maxY = PresetDocument.screenHeight
        edit { doc in
            for id in ids {
                guard let c = doc.control(id: id) else { continue }
                var nx = max(0, min(maxX - c.w, c.x + dx))
                var ny = max(0, min(maxY - c.h, c.y + dy))
                if snap {
                    let b = SlotGeometry.bounds(forSlot: SlotGeometry.slot(forBounds: nx, ny))
                    nx = b.x
                    ny = b.y
                }
                doc.setControlBounds(id: id, x: nx, y: ny, w: c.w, h: c.h)
            }
        }
    }

    func duplicateControls(_ ids: [Int]) {
        guard !ids.isEmpty else { return }
        var newIds: [Int] = []
        edit { doc in for id in ids { if let n = doc.duplicateControl(id: id) { newIds.append(n) } } }
        if let first = newIds.first { selectedControlId = newIds.count == 1 ? first : nil }
        message = "Duplicated \(ids.count) control(s)."
    }

    enum DistributeAxis { case horizontal, vertical }

    /// Evenly distribute control centers along an axis (needs 3+).
    func distributeControls(_ ids: [Int], axis: DistributeAxis) {
        guard ids.count >= 3 else { return }
        edit { doc in
            var cs = ids.compactMap { doc.control(id: $0) }
            guard cs.count >= 3 else { return }
            let center: (PresetDocument.Control) -> Double = { axis == .horizontal ? $0.x + $0.w / 2 : $0.y + $0.h / 2 }
            cs.sort { center($0) < center($1) }
            let first = center(cs.first!), last = center(cs.last!)
            let step = (last - first) / Double(cs.count - 1)
            for (i, c) in cs.enumerated() {
                let target = first + step * Double(i)
                if axis == .horizontal {
                    doc.setControlBounds(id: c.id, x: target - c.w / 2, y: c.y, w: c.w, h: c.h)
                } else {
                    doc.setControlBounds(id: c.id, x: c.x, y: target - c.h / 2, w: c.w, h: c.h)
                }
            }
        }
        message = "Distributed \(ids.count) controls."
    }

    /// Align a set of controls to a shared edge in one undo step.
    func alignControls(_ ids: [Int], to edge: AlignEdge) {
        guard ids.count > 1 else { return }
        edit { doc in
            let cs = ids.compactMap { doc.control(id: $0) }
            guard !cs.isEmpty else { return }
            let minX = cs.map(\.x).min()!, maxX = cs.map { $0.x + $0.w }.max()!
            let minY = cs.map(\.y).min()!, maxY = cs.map { $0.y + $0.h }.max()!
            let cX = (minX + maxX) / 2, cY = (minY + maxY) / 2
            for c in cs {
                var x = c.x, y = c.y
                switch edge {
                case .left:    x = minX
                case .right:   x = maxX - c.w
                case .centerH: x = cX - c.w / 2
                case .top:     y = minY
                case .bottom:  y = maxY - c.h
                case .centerV: y = cY - c.h / 2
                }
                doc.setControlBounds(id: c.id, x: x, y: y, w: c.w, h: c.h)
            }
        }
        message = "Aligned \(ids.count) controls."
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private func run(_ msg: String, _ op: @escaping () async throws -> String) {
        busy = true
        message = msg
        Task {
            do { message = try await op() }
            catch { message = "Error: \(describe(error))" }
            busy = false
        }
    }

    private func isEmpty(_ e: E1Error) -> Bool {
        if case .empty = e { return true }
        if case .timeout = e { return true }
        return false
    }

    private func describe(_ error: Error) -> String {
        (error as? E1Error)?.description ?? error.localizedDescription
    }
}

enum PresetNaming {
    static func fileName(for name: String?) -> String {
        let base = (name ?? "preset").trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "_")
        return "\(base.isEmpty ? "preset" : base).json"
    }
}
