import Foundation
import SwiftUI
import UniformTypeIdentifiers
import ElectraKit

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

    func addControl() {
        edit { doc in
            let newId = doc.addControl(pageId: currentPageId)
            DispatchQueue.main.async { self.selectedControlId = newId }
        }
        message = "Added control."
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
    /// multi-select drag).
    func moveControls(_ ids: [Int], dx: Double, dy: Double) {
        guard !ids.isEmpty else { return }
        let maxX = PresetDocument.screenWidth, maxY = PresetDocument.screenHeight
        edit { doc in
            for id in ids {
                guard let c = doc.control(id: id) else { continue }
                let nx = max(0, min(maxX - c.w, c.x + dx))
                let ny = max(0, min(maxY - c.h, c.y + dy))
                doc.setControlBounds(id: id, x: nx, y: ny, w: c.w, h: c.h)
            }
        }
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
