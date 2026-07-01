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

    // ── Script library ────────────────────────────────────────────────────────
    // A persistent collection of every Lua script the user writes, generates, or
    // imports — independent of any one preset. Lives on disk (see ScriptLibrary).
    private let scriptLibrary = ScriptLibrary()
    @Published var libraryScripts: [LibraryScript] = []
    @Published var libraryPresented = false
    /// The library entry currently loaded in the editor, if any — lets "Save"
    /// update in place rather than always creating a new entry.
    @Published var activeLibraryScriptId: UUID? = nil

    // Built-in simulator (Run)
    @Published var simulatorPresented = false
    @Published var simBottomText: String = ""

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
        // Seed the built-in example scripts (once), so the library ships with a
        // set of known-good Electra One Lua examples covering MIDI and visuals.
        // Existing users pick up the set too; their own scripts are untouched.
        scriptLibrary.seedExamples(
            ExampleLuaScripts.all.map { ($0.name, $0.source) }, version: 1)
        libraryScripts = scriptLibrary.scripts
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
        // The editor now reflects this preset's Lua, not a library entry.
        activeLibraryScriptId = nil
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

    /// "Build" — compile-check only; reports syntax errors without running.
    func luaBuild() {
        if let err = lua.check(luaSource) {
            appendConsole("✗ Build failed:\n\(err)")
        } else {
            appendConsole("✓ Build OK — no syntax errors.")
        }
    }

    /// "Run" — build, then execute the script in the in-app simulator (the Lua
    /// runs against a mocked Electra environment) and open the simulator window
    /// showing the preset screen, the status-bar text the script set, and the
    /// console output.
    func luaRun() {
        // A syntax error means there's nothing to run — surface it and stop.
        if let err = lua.check(luaSource) {
            appendConsole("▶ Run — build failed:\n\(err)")
            simBottomText = ""
            simulatorPresented = true
            return
        }
        appendConsole("▶ Run — launching simulator…")
        let result = lua.simulate(luaSource)
        if !result.output.isEmpty { appendConsole(result.output) }
        if let err = result.error {
            appendConsole("✗ \(err)")
        } else {
            appendConsole("✓ finished")
        }
        simBottomText = result.bottomText ?? ""
        simulatorPresented = true
    }

    func clearConsole() { luaConsole = "" }

    // ── Script library actions ────────────────────────────────────────────────

    private func refreshLibrary() { libraryScripts = scriptLibrary.scripts }

    var canSaveToLibrary: Bool {
        !luaSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Save the current editor script into the library. If it's already backed by
    /// a library entry, update that entry in place; otherwise create a new one
    /// (named after the open preset, or "Untitled Script").
    func saveCurrentToLibrary() {
        guard canSaveToLibrary else { message = "Nothing to save — the editor is empty."; return }
        if let id = activeLibraryScriptId,
           scriptLibrary.scripts.contains(where: { $0.id == id }) {
            scriptLibrary.updateSource(id: id, source: luaSource)
            refreshLibrary()
            let name = scriptLibrary.scripts.first { $0.id == id }?.name ?? "script"
            message = "Updated “\(name)” in the library."
        } else {
            let base = document?.name.isEmpty == false ? document!.name : "Untitled Script"
            let script = captureToLibrary(source: luaSource, name: base, origin: .created)
            activeLibraryScriptId = script?.id
            message = script.map { "Saved “\($0.name)” to the library." } ?? "Nothing to save."
        }
    }

    /// Add a script to the library, skipping exact-duplicate sources so auto-capture
    /// (AI generation, imports) doesn't pile up copies. Returns the stored entry.
    @discardableResult
    func captureToLibrary(source: String, name: String, origin: LibraryScript.Origin) -> LibraryScript? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !scriptLibrary.contains(source: source) else { return nil }
        let script = scriptLibrary.add(LibraryScript(
            name: scriptLibrary.uniqueName(basedOn: name), source: source, origin: origin))
        refreshLibrary()
        return script
    }

    /// Load a library script into the editor (attaching it to the open preset's
    /// Lua so Save / Push carry it along).
    func loadFromLibrary(_ script: LibraryScript) {
        setLuaSource(script.source)
        activeLibraryScriptId = script.id
        editorMode = .script
        libraryPresented = false
        message = "Loaded “\(script.name)” into the editor."
    }

    func renameLibraryScript(_ id: UUID, to name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        scriptLibrary.rename(id: id, to: clean)
        refreshLibrary()
    }

    func deleteLibraryScript(_ id: UUID) {
        scriptLibrary.remove(id: id)
        if activeLibraryScriptId == id { activeLibraryScriptId = nil }
        refreshLibrary()
    }

    func importLua() {
        let panel = NSOpenPanel()
        var types: [UTType] = []
        if let lua = UTType(filenameExtension: "lua") { types.append(lua) }
        types.append(.plainText)
        panel.allowedContentTypes = types
        panel.allowsOtherFileTypes = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let source = try String(contentsOf: url, encoding: .utf8)
            setLuaSource(source)
            let base = url.deletingPathExtension().lastPathComponent
            let saved = captureToLibrary(source: source, name: base, origin: .imported)
            activeLibraryScriptId = saved?.id
            message = saved != nil
                ? "Imported \(url.lastPathComponent) → added to library."
                : "Imported \(url.lastPathComponent)."
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

    private func appendConsole(_ text: String) {
        if !luaConsole.isEmpty { luaConsole += "\n" }
        luaConsole += text
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
                // Auto-capture the generation into the library (named from the prompt).
                let saved = captureToLibrary(source: lua, name: Self.libraryName(fromPrompt: prompt), origin: .generated)
                activeLibraryScriptId = saved?.id
                let libNote = saved != nil ? " Saved to library as “\(saved!.name)”." : ""
                appendConsole("✓ Script generated (\(lua.split(separator: "\n").count) lines). Review, Build, and Run.\(libNote)")
                aiPrompt = ""
            } catch {
                let msg = (error as? AIClient.AIError)?.description ?? error.localizedDescription
                appendConsole("✗ AI error: \(msg)")
                message = "AI error: \(msg)"
            }
            aiBusy = false
        }
    }

    /// Turn a free-text AI prompt into a short, title-ish library name.
    static func libraryName(fromPrompt prompt: String) -> String {
        let words = prompt
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: " ")
            .prefix(6)
            .joined(separator: " ")
        let trimmed = words.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "AI Script" : trimmed
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

    /// Whether "Push to Device" is available: a connected device plus something
    /// to push — either an open preset or a non-empty script (which we wrap in a
    /// minimal preset).
    var canPushToDevice: Bool {
        isConnected && (document != nil || !luaSource.isEmpty)
    }

    func presentSaveToDevice() {
        guard document != nil || !luaSource.isEmpty else { return }
        if let s = deviceSlot { saveBank = s.bank; saveSlot = s.slot }
        else { saveBank = bank; saveSlot = 0 }
        savePickerPresented = true
    }

    func confirmSaveToDevice() {
        savePickerPresented = false
        guard isConnected else {
            message = "Connect an Electra One to save to the device."
            return
        }

        // Decide what to push. With no preset open but a script in the editor,
        // wrap the Lua in a minimal preset so it has a slot to live in — this is
        // what lets a script-only session push and run on the device.
        var doc: PresetDocument
        let synthesized: Bool
        if let d = document {
            doc = d
            synthesized = false
        } else if !luaSource.isEmpty {
            doc = .newPreset(name: "Lua Script")
            synthesized = true
        } else {
            message = "Nothing to push — open a preset or write a script first."
            return
        }
        // Make sure the current editor script rides along with the upload.
        if !luaSource.isEmpty { doc.lua = luaSource }

        let json = doc.jsonString(pretty: false)
        let lua = doc.lua
        let b = saveBank, s = saveSlot
        let luaNote = (lua?.isEmpty == false) ? " + Lua" : ""
        run("Uploading \"\(doc.name)\"\(luaNote) → bank \(b), slot \(s)…") {
            try await self.device.putProject(json: json, lua: lua, bank: b, slot: s)
            // Auto-load: switch the controller to the slot we just wrote so it
            // becomes the live preset (Set-slot only arms; Switch-slot loads).
            try await self.device.activateSlot(bank: b, slot: s)
            // Adopt the pushed preset as the open document (especially when we
            // synthesized one) so subsequent edits/pushes target the same slot.
            if synthesized || self.document == nil {
                self.loadDocument(doc, fileURL: nil, deviceSlot: (b, s))
            } else {
                self.deviceSlot = (bank: b, slot: s)
                self.dirty = false
            }
            self.bank = b
            self.openSlot = s
            self.rescan()
            return "Pushed \"\(doc.name)\"\(luaNote) → bank \(b), slot \(s) and loaded it."
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
        var createdId: Int?
        var colorHex = "FFFFFF"
        edit { doc in
            let newId = doc.addControl(kind: kind, pageId: currentPageId)
            createdId = newId
            colorHex = doc.control(id: newId)?.colorHex ?? "FFFFFF"
            DispatchQueue.main.async { self.selectedControlId = newId }
        }
        // A Custom control needs a paint callback to draw anything — seed a
        // starter one into the preset's Lua and register it, so it renders live
        // immediately (and pushes to the device already working).
        if kind == .custom, let id = createdId {
            seedCustomPaint(controlId: id, colorHex: colorHex)
            editorMode = .script
        }
        message = kind == .custom
            ? "Added Custom control — edit its paint script to draw."
            : "Added \(kind.displayName)."
    }

    /// Append a starter `paint_<id>` callback (and its registration) to the
    /// preset's Lua for a new Custom control. The callback draws a value bar so
    /// there's something on screen from the first frame.
    private func seedCustomPaint(controlId id: Int, colorHex: String) {
        let starter = PresetDocument.customPaintStarter(controlId: id, colorHex: colorHex)
        setLuaSource(luaSource.isEmpty ? starter : luaSource + "\n\n" + starter)
    }

    /// Render a Custom control's paint callback against the preset's current Lua,
    /// returning the recorded draw ops for the canvas to replay. `fraction` is the
    /// simulated 0..1 value (no live hardware value offline).
    func renderCustomControl(id: Int, width: Double, height: Double,
                             fraction: Double) -> LuaEngine.PaintResult {
        let src = luaSource.isEmpty ? (document?.lua ?? "") : luaSource
        return lua.paint(src, controlId: id, width: width, height: height, fraction: fraction)
    }

    /// Jump to the Lua editor to edit a Custom control's paint callback.
    func editPaintScript(id: Int) { editorMode = .script }

    // ── Script buttons ─────────────────────────────────────────────────────────

    /// Where a script button's Lua code comes from.
    enum ScriptSource { case editor, clipboard, file }

    /// Read Lua code for a new script button. Returns nil if the source is empty
    /// or the user cancels a file picker.
    func acquireScriptSource(_ source: ScriptSource) -> String? {
        switch source {
        case .editor:
            let s = luaSource.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : luaSource
        case .clipboard:
            let s = NSPasteboard.general.string(forType: .string)
            return (s?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? s : nil
        case .file:
            let panel = NSOpenPanel()
            var types: [UTType] = []
            if let lua = UTType(filenameExtension: "lua") { types.append(lua) }
            types.append(.plainText)
            panel.allowedContentTypes = types
            panel.allowsOtherFileTypes = true
            guard panel.runModal() == .OK, let url = panel.url else { return nil }
            return try? String(contentsOf: url, encoding: .utf8)
        }
    }

    /// Add a Script button: place a pad bound to a Lua function and append that
    /// function (wrapping the supplied code) to the preset's Lua script.
    func addScriptControl(from source: ScriptSource) {
        guard document != nil else { return }
        guard let body = acquireScriptSource(source) else {
            message = "No script to add."
            return
        }
        var newId: Int?
        edit { doc in
            let id = doc.addScriptControl(pageId: currentPageId)
            newId = id
            DispatchQueue.main.async { self.selectedControlId = id }
        }
        guard let id = newId else { return }
        appendScriptFunction(name: PresetDocument.scriptFunctionName(forControlId: id), body: body)
        message = "Added Script button."
    }

    /// Append a named function wrapping `body` to the preset's Lua source.
    private func appendScriptFunction(name: String, body: String) {
        let trimmed = body.trimmingCharacters(in: .newlines)
        let fn = "\n\nfunction \(name)(valueObject, value)\n\(trimmed)\nend\n"
        setLuaSource(luaSource.isEmpty ? String(fn.drop(while: { $0 == "\n" })) : luaSource + fn)
    }

    /// Run a script button's function in the in-app simulator, surfacing print
    /// output in the console (and any `info.setText` in the simulator status bar).
    func runScriptControl(id: Int) {
        let fn = document?.control(id: id)?.functionName
            ?? PresetDocument.scriptFunctionName(forControlId: id)
        let name = document?.control(id: id)?.name ?? fn
        if let err = lua.check(luaSource) {
            appendConsole("▶ Run \(name) — build failed:\n\(err)")
            simBottomText = ""
            simulatorPresented = true
            return
        }
        appendConsole("▶ Run \(name) …")
        let combined = luaSource + "\n\n\(fn)(nil, 127)\n"
        let result = lua.simulate(combined)
        if !result.output.isEmpty { appendConsole(result.output) }
        if let err = result.error {
            appendConsole("✗ \(err)")
        } else {
            appendConsole("✓ finished")
        }
        simBottomText = result.bottomText ?? ""
        simulatorPresented = true
    }

    /// Jump to the Lua editor so the user can edit a script button's function.
    func editScriptControl(id: Int) {
        editorMode = .script
    }

    /// Replace a script button's code with a fresh source, rewriting its function.
    func replaceScriptControl(id: Int, from source: ScriptSource) {
        guard let body = acquireScriptSource(source) else {
            message = "No script to import."
            return
        }
        let name = document?.control(id: id)?.functionName
            ?? PresetDocument.scriptFunctionName(forControlId: id)
        // Drop any existing definition of this function, then append the new one.
        setLuaSource(Self.removingFunction(named: name, from: luaSource))
        appendScriptFunction(name: name, body: body)
        message = "Replaced script."
    }

    /// Remove a `function <name>(...) ... end` block from Lua source (best-effort,
    /// matched by depth-counting `function`/`end` keywords from the definition).
    static func removingFunction(named name: String, from source: String) -> String {
        let lines = source.components(separatedBy: "\n")
        var out: [String] = []
        var i = 0
        let header = "function \(name)("
        while i < lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(header) {
                // Skip until the matching `end`. Count Lua block openers that pair
                // with `end`: function/if/for/while, plus a bare `do` (the `do` in a
                // for/while header belongs to the loop, so don't count it twice).
                var depth = 0
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    let words = t.split(whereSeparator: { !($0.isLetter || $0.isNumber || $0 == "_") }).map(String.init)
                    let isLoopHeader = words.contains("for") || words.contains("while")
                    for w in words {
                        switch w {
                        case "function", "if", "for", "while": depth += 1
                        case "do" where !isLoopHeader:         depth += 1
                        case "end":                            depth -= 1
                        default:                               break
                        }
                    }
                    i += 1
                    if depth <= 0 { break }
                }
                continue
            }
            out.append(lines[i])
            i += 1
        }
        return out.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }

    func setControlKind(_ id: Int, _ kind: PresetDocument.ControlKind) {
        edit { $0.setControlKind(id: id, kind) }
        // Switching a control to Custom needs a paint callback to draw anything —
        // seed a starter one if the preset's Lua doesn't already define it.
        if kind == .custom {
            let fn = PresetDocument.paintFunctionName(forControlId: id)
            if !luaSource.contains("function \(fn)(") {
                seedCustomPaint(controlId: id, colorHex: document?.control(id: id)?.colorHex ?? "FFFFFF")
            }
        }
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
