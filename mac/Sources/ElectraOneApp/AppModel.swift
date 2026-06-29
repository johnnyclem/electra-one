import Foundation
import SwiftUI
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

    private var scanToken = 0

    init() {
        slots = (0..<slotsPerBank).map { SlotState(slot: $0, status: .unknown) }
    }

    var isConnected: Bool { if case .ready = connection { return true }; return false }

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
                guard let doc = PresetDocument(jsonString: raw) else {
                    throw E1Error.decode("This slot's data isn't valid preset JSON.")
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
    }

    func newDocument() {
        loadDocument(.newPreset(), fileURL: nil, deviceSlot: nil)
        openSlot = nil
        message = "New preset."
    }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            guard let doc = PresetDocument(jsonString: text) else {
                message = "Error: not a valid preset JSON file."
                return
            }
            loadDocument(doc, fileURL: url, deviceSlot: nil)
            openSlot = nil
            message = "Opened \(url.lastPathComponent)."
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
        let b = saveBank, s = saveSlot
        run("Uploading \"\(doc.name)\" → bank \(b), slot \(s)…") {
            try await self.device.putPreset(json: json, bank: b, slot: s)
            self.deviceSlot = (bank: b, slot: s)
            self.dirty = false
            if self.bank == b { self.rescan() }
            return "Saved \"\(doc.name)\" → bank \(b), slot \(s)."
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

    private func edit(_ body: (inout PresetDocument) -> Void) {
        guard var doc = document else { return }
        body(&doc)
        document = doc
        dirty = true
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
        edit { $0.removeControl(id: id) }
        selectedControlId = nil
        message = "Deleted control."
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
