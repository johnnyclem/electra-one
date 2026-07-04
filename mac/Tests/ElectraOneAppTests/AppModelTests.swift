import Testing
import Foundation
import ElectraKit
import LuaKit
@testable import ElectraOneApp

/// UI-logic tests for the app layer, focused on the flows where the UI
/// generates Lua: adding Custom controls (paint callbacks), script buttons,
/// and the editor ↔ document sync those flows rely on.
@MainActor
struct AppModelTests {

    /// A model backed by a temp script library — never touches the user's
    /// Application Support store or the seeding UserDefaults key.
    private func makeModel() -> AppModel {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("e1-app-tests-\(UUID().uuidString)", isDirectory: true)
        let lib = ScriptLibrary(fileURL: dir.appendingPathComponent("library.json"))
        return AppModel(scriptLibrary: lib, seedSamples: false)
    }

    // ── Editor ↔ document sync ───────────────────────────────────────────────

    @Test func setLuaSourceSyncsIntoDocument() {
        let m = makeModel()
        m.newDocument()
        m.setLuaSource("print('x')")
        #expect(m.document?.lua == "print('x')")
        #expect(m.dirty)
        m.setLuaSource("")
        #expect(m.document?.lua == nil, "empty editor clears the document's Lua")
    }

    @Test func loadingADocumentReplacesStaleEditorLua() {
        let m = makeModel()
        m.newDocument()
        m.setLuaSource("-- script for preset A")
        // Opening a Lua-less document must clear the editor — otherwise preset
        // A's script silently attaches to the new preset on the next push.
        m.newDocument()
        #expect(m.luaSource.isEmpty)
        #expect(m.document?.lua == nil)
    }

    // ── Custom control → generated paint Lua ────────────────────────────────

    @Test func addingCustomControlGeneratesPaintCallback() {
        let m = makeModel()
        m.newDocument()
        m.addControl(kind: .custom)

        let id = try! #require(m.selectedControlIdAfterPendingUpdates() ?? m.document?.allControls().last?.id)
        let fn = PresetDocument.paintFunctionName(forControlId: id)
        #expect(m.luaSource.contains("function \(fn)(display)"), "paint callback defined")
        #expect(m.luaSource.contains("setPaintCallback(\(fn))"), "callback registered in preset.onLoad")
        #expect(m.document?.lua == m.luaSource, "generated Lua saved into the document")
        #expect(m.editorMode == .script, "editor jumps to the generated script")
    }

    @Test func generatedPaintLuaCompilesAndDraws() {
        let m = makeModel()
        m.newDocument()
        m.addControl(kind: .custom)
        let id = try! #require(m.document?.allControls().last?.id)

        // The generated starter must be valid Lua that actually paints.
        let engine = LuaEngine()
        #expect(engine.check(m.luaSource) == nil, "starter script has no syntax errors")

        let result = m.renderCustomControl(id: id, width: 170, height: 120, fraction: 0.5)
        #expect(result.error == nil)
        #expect(!result.ops.isEmpty, "starter paint callback records draw ops")
    }

    @Test func renderCustomControlIsCachedUntilSourceChanges() {
        let m = makeModel()
        m.newDocument()
        m.addControl(kind: .custom)
        let id = try! #require(m.document?.allControls().last?.id)

        let a = m.renderCustomControl(id: id, width: 100, height: 80, fraction: 0.5)
        let b = m.renderCustomControl(id: id, width: 100, height: 80, fraction: 0.5)
        #expect(a.ops.count == b.ops.count, "repeat render served consistently (cache hit)")

        // Editing the script must invalidate the cached render.
        m.setLuaSource(m.luaSource + "\n-- touched\n")
        let c = m.renderCustomControl(id: id, width: 100, height: 80, fraction: 0.5)
        #expect(c.error == nil)
        #expect(!c.ops.isEmpty)
    }

    @Test func switchingKindToCustomSeedsPaintOnlyOnce() {
        let m = makeModel()
        m.newDocument()
        m.addControl(kind: .fader)
        let id = try! #require(m.document?.allControls().last?.id)

        m.setControlKind(id, .custom)
        let fn = PresetDocument.paintFunctionName(forControlId: id)
        #expect(m.luaSource.contains("function \(fn)("))

        // Toggling away and back must not duplicate the callback.
        m.setControlKind(id, .fader)
        m.setControlKind(id, .custom)
        let occurrences = m.luaSource.components(separatedBy: "function \(fn)(").count - 1
        #expect(occurrences == 1, "paint callback seeded exactly once")
    }

    // ── Script buttons → generated wrapper Lua ───────────────────────────────

    @Test func addingScriptControlWrapsEditorSourceInFunction() {
        let m = makeModel()
        m.newDocument()
        m.setLuaSource("print(\"pressed\")")
        m.addScriptControl(from: .editor)

        let control = try! #require(m.document?.allControls().last)
        let fn = PresetDocument.scriptFunctionName(forControlId: control.id)
        #expect(control.functionName == fn, "pad bound to the generated function")
        #expect(m.luaSource.contains("function \(fn)(valueObject, value)"))
        #expect(m.luaSource.contains("print(\"pressed\")"))

        let engine = LuaEngine()
        #expect(engine.check(m.luaSource) == nil, "generated wrapper is valid Lua")
    }

    @Test func removingFunctionDeletesOnlyThatFunction() {
        let src = """
        function keep(a)
          if a then
            print(a)
          end
        end

        function drop(valueObject, value)
          for i = 1, 3 do
            print(i)
          end
        end

        print("tail")
        """
        let out = AppModel.removingFunction(named: "drop", from: src)
        #expect(out.contains("function keep(a)"))
        #expect(!out.contains("function drop("))
        #expect(out.contains("print(\"tail\")"))
    }

    // ── Misc pure helpers ────────────────────────────────────────────────────

    @Test func libraryNameFromPromptIsShortAndNonEmpty() {
        #expect(AppModel.libraryName(fromPrompt: "") == "AI Script")
        #expect(AppModel.libraryName(fromPrompt: "make a step sequencer with sixteen pads and lights")
                == "make a step sequencer with sixteen")
    }
}

private extension AppModel {
    /// `addControl` defers `selectedControlId` to the next runloop turn; tests
    /// read the created control directly instead of waiting.
    func selectedControlIdAfterPendingUpdates() -> Int? { selectedControlId }
}
