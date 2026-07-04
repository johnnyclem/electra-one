import Foundation

/// One saved Lua script in the user's library. Scripts are captured here from
/// the editor (manual save), from AI generation, and from file imports so the
/// user builds up a reusable collection independent of any single preset.
struct LibraryScript: Codable, Identifiable, Equatable {
    enum Origin: String, Codable {
        case created    // hand-written / saved from the editor
        case generated  // produced by AI generation
        case imported   // read in from a .lua file
        case sample     // seeded example shipped with the app

        var label: String {
            switch self {
            case .created:   return "Created"
            case .generated: return "AI"
            case .imported:  return "Imported"
            case .sample:    return "Example"
            }
        }
    }

    let id: UUID
    var name: String
    var source: String
    var origin: Origin
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, source: String, origin: Origin,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.source = source
        self.origin = origin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var lineCount: Int { source.split(whereSeparator: \.isNewline).count }
}

/// Persistent, on-disk store for the script library. Backed by a single JSON
/// file in Application Support so the collection survives across launches and is
/// easy to inspect or back up. All access is synchronous and cheap (the library
/// is small text); saves are best-effort and never block the UI meaningfully.
final class ScriptLibrary {
    private(set) var scripts: [LibraryScript]
    private let fileURL: URL

    /// `fileURL` is injectable so tests can point the library at a temp file
    /// instead of the user's real Application Support store.
    init(fileURL: URL = ScriptLibrary.storeURL()) {
        self.fileURL = fileURL
        scripts = ScriptLibrary.load(from: fileURL)
    }

    /// Insert a new script (newest first) and persist. Returns the stored value.
    @discardableResult
    func add(_ script: LibraryScript) -> LibraryScript {
        scripts.insert(script, at: 0)
        save()
        return script
    }

    /// Replace the source of an existing script (bumping `updatedAt`), or no-op.
    func updateSource(id: UUID, source: String) {
        guard let i = scripts.firstIndex(where: { $0.id == id }) else { return }
        scripts[i].source = source
        scripts[i].updatedAt = Date()
        save()
    }

    func rename(id: UUID, to name: String) {
        guard let i = scripts.firstIndex(where: { $0.id == id }) else { return }
        scripts[i].name = name
        scripts[i].updatedAt = Date()
        save()
    }

    func remove(id: UUID) {
        scripts.removeAll { $0.id == id }
        save()
    }

    func contains(source: String) -> Bool {
        let needle = source.trimmingCharacters(in: .whitespacesAndNewlines)
        return scripts.contains { $0.source.trimmingCharacters(in: .whitespacesAndNewlines) == needle }
    }

    /// Seed the built-in example scripts, at most once per `version`. Only adds
    /// examples whose name isn't already present, so a user's own edits and
    /// deletions survive; bump `version` to push a refreshed set to existing
    /// users. Newly-added examples land at the top in declared order.
    @discardableResult
    func seedExamples(_ examples: [(name: String, source: String)], version: Int) -> Bool {
        let key = "ScriptLibrary.seededExamplesVersion"
        guard UserDefaults.standard.integer(forKey: key) < version else { return false }
        let existing = Set(scripts.map(\.name))
        var added = false
        for ex in examples.reversed() where !existing.contains(ex.name) {
            scripts.insert(LibraryScript(name: ex.name, source: ex.source, origin: .sample), at: 0)
            added = true
        }
        UserDefaults.standard.set(version, forKey: key)
        if added { save() }
        return added
    }

    /// A unique, human-friendly default name given a desired base.
    func uniqueName(basedOn base: String) -> String {
        let trimmed = base.trimmingCharacters(in: .whitespaces)
        let root = trimmed.isEmpty ? "Untitled Script" : trimmed
        var candidate = root
        var n = 2
        let existing = Set(scripts.map(\.name))
        while existing.contains(candidate) {
            candidate = "\(root) \(n)"
            n += 1
        }
        return candidate
    }

    // ── Persistence ──────────────────────────────────────────────────────────

    private func save() {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601
            let data = try enc.encode(scripts)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("ScriptLibrary save failed: \(error)")
        }
    }

    private static func load(from url: URL) -> [LibraryScript] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return (try? dec.decode([LibraryScript].self, from: data)) ?? []
    }

    private static func storeURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                appropriateFor: nil, create: true))
            ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return base
            .appendingPathComponent("ElectraOne", isDirectory: true)
            .appendingPathComponent("script-library.json")
    }
}
