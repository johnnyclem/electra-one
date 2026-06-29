import Foundation
import SwiftUI
import ElectraKit

/// UI state + orchestration. All published state lives on the main actor; the
/// actual MIDI work happens on the `E1Device` actor.
@MainActor
final class AppModel: ObservableObject {
    enum ConnectionState: Equatable {
        case connecting, ready, failed(String)
    }

    let slotsPerBank = 12
    let bankCount = 6

    private let device = E1Device()

    @Published var connection: ConnectionState = .connecting
    @Published var info: DeviceInfo?
    @Published var portName: String = ""

    @Published var bank: Int = 0
    @Published var slots: [SlotState] = []
    @Published var selected: Int? = nil

    @Published var summary: PresetSummary?
    @Published var detailLoading = false
    @Published var detailEmpty = false

    @Published var busy = false
    @Published var message: String = ""

    // Editor sheet
    @Published var editorPresented = false
    @Published var editorText: String = ""
    @Published var editorSlot: Int? = nil
    @Published var editorError: String?

    private var scanToken = 0

    init() {
        slots = (0..<slotsPerBank).map { SlotState(slot: $0, status: .unknown) }
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────

    func start() {
        Task {
            do {
                let ports = try await device.connect()
                portName = ports.input
                info = try await device.getInfo()
                connection = .ready
                rescan()
            } catch {
                connection = .failed(describe(error))
            }
        }
    }

    func shutdown() {
        Task { await device.disconnect() }
    }

    // ── Scanning ──────────────────────────────────────────────────────────

    func setBank(_ newBank: Int) {
        guard newBank != bank, newBank >= 0, newBank < bankCount else { return }
        bank = newBank
        selected = nil
        summary = nil
        detailEmpty = false
        rescan()
    }

    func rescan() {
        scanToken += 1
        let token = scanToken
        let targetBank = bank
        slots = (0..<slotsPerBank).map { SlotState(slot: $0, status: .scanning) }
        Task {
            for slot in 0..<slotsPerBank {
                let result = await device.scanSlot(bank: targetBank, slot: slot)
                if token != scanToken { return }  // a newer scan started
                slots[slot] = result
            }
            if token == scanToken { message = "Scanned bank \(targetBank)." }
        }
    }

    // ── Detail ────────────────────────────────────────────────────────────

    func select(_ slot: Int) {
        selected = slot
        loadDetail(slot)
    }

    func loadDetail(_ slot: Int) {
        detailLoading = true
        detailEmpty = false
        summary = nil
        let targetBank = bank
        Task {
            do {
                let s = try await device.summarize(bank: targetBank, slot: slot)
                if selected == slot { summary = s; message = "Viewing \"\(s.name)\"." }
            } catch let e as E1Error where isEmpty(e) {
                if selected == slot { detailEmpty = true }
            } catch {
                if selected == slot { message = "Error: \(describe(error))" }
            }
            if selected == slot { detailLoading = false }
        }
    }

    // ── Operations ────────────────────────────────────────────────────────

    func download(_ slot: Int) {
        let targetBank = bank
        run("Downloading slot \(slot)…") {
            let pretty = try await self.device.getPresetPretty(bank: targetBank, slot: slot)
            let name = PresetNaming.fileName(for: E1Device.summarize(text: pretty)?.name)
            return await MainActor.run { self.savePanel(suggested: name, contents: pretty) }
        }
    }

    func activate(_ slot: Int) {
        let targetBank = bank
        run("Activating bank \(targetBank), slot \(slot)…") {
            try await self.device.switchSlot(bank: targetBank, slot: slot)
            return "Activated bank \(targetBank), slot \(slot) on device."
        }
    }

    func upload(file: URL, to slot: Int) {
        let targetBank = bank
        run("Uploading \(file.lastPathComponent) → slot \(slot)…") {
            let text = try String(contentsOf: file, encoding: .utf8)
            guard let data = text.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["name"] != nil, obj["controls"] != nil
            else { throw E1Error.decode("File does not look like an Electra preset (missing name/controls).") }
            try await self.device.putPreset(json: text, bank: targetBank, slot: slot)
            self.rescan()
            return "Uploaded \"\(obj["name"] as? String ?? "preset")\" → bank \(targetBank), slot \(slot)."
        }
    }

    // ── Editing ───────────────────────────────────────────────────────────

    func beginEdit(_ slot: Int) {
        let targetBank = bank
        busy = true
        message = "Loading slot \(slot) for editing…"
        Task {
            do {
                let pretty = try await device.getPresetPretty(bank: targetBank, slot: slot)
                editorText = pretty
                editorSlot = slot
                editorError = nil
                editorPresented = true
                message = ""
            } catch let e as E1Error where isEmpty(e) {
                message = "Slot is empty — nothing to edit."
            } catch {
                message = "Error: \(describe(error))"
            }
            busy = false
        }
    }

    func saveEdit() {
        guard let slot = editorSlot else { return }
        let text = editorText
        let targetBank = bank
        // Validate before sending.
        guard let data = text.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            editorError = "Invalid JSON — fix it before saving."
            return
        }
        editorError = nil
        editorPresented = false
        run("Saving edits → bank \(targetBank), slot \(slot)…") {
            try await self.device.putPreset(json: text, bank: targetBank, slot: slot)
            self.rescan()
            if self.selected == slot { self.loadDetail(slot) }
            return "Saved edits → bank \(targetBank), slot \(slot)."
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    /// Run an async operation with busy/status handling. The closure returns a
    /// status string to display on success.
    private func run(_ msg: String, _ op: @escaping () async throws -> String) {
        busy = true
        message = msg
        Task {
            do {
                let done = try await op()
                message = done
            } catch {
                message = "Error: \(describe(error))"
            }
            busy = false
        }
    }

    private func savePanel(suggested: String, contents: String) -> String {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggested
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return "Download cancelled." }
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            return "Saved → \(url.path)"
        } catch {
            return "Save failed: \(error.localizedDescription)"
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
        let base = (name ?? "preset")
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "_")
        let safe = base.isEmpty ? "preset" : base
        return "\(safe).json"
    }
}
