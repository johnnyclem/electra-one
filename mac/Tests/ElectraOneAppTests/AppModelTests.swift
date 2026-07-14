import XCTest
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

    func test_setLuaSourceSyncsIntoDocument() {
        let m = makeModel()
        m.newDocument()
        m.setLuaSource("print('x')")
        XCTAssertEqual(m.document?.lua, "print('x')")
        XCTAssert(m.dirty)
        m.setLuaSource("")
        XCTAssertEqual(m.document?.lua, nil, "empty editor clears the document's Lua")
    }

    func test_loadingADocumentReplacesStaleEditorLua() {
        let m = makeModel()
        m.newDocument()
        m.setLuaSource("-- script for preset A")
        // Opening a Lua-less document must clear the editor — otherwise preset
        // A's script silently attaches to the new preset on the next push.
        m.newDocument()
        XCTAssert(m.luaSource.isEmpty)
        XCTAssertEqual(m.document?.lua, nil)
    }

    // ── Custom control → generated paint Lua ────────────────────────────────

    func test_addingCustomControlGeneratesPaintCallback() {
        let m = makeModel()
        m.newDocument()
        m.addControl(kind: .custom)

        let id = try! #require(m.selectedControlIdAfterPendingUpdates() ?? m.document?.allControls().last?.id)
        let fn = PresetDocument.paintFunctionName(forControlId: id)
        XCTAssert(m.luaSource.contains("function \(fn)(display)"), "paint callback defined")
        XCTAssert(m.luaSource.contains("setPaintCallback(\(fn))"), "callback registered in preset.onLoad")
        XCTAssertEqual(m.document?.lua, m.luaSource, "generated Lua saved into the document")
        XCTAssertEqual(m.editorMode, .script, "editor jumps to the generated script")
    }

    func test_generatedPaintLuaCompilesAndDraws() {
        let m = makeModel()
        m.newDocument()
        m.addControl(kind: .custom)
        let id = try! #require(m.document?.allControls().last?.id)

        // The generated starter must be valid Lua that actually paints.
        let engine = LuaEngine()
        XCTAssertEqual(engine.check(m.luaSource), nil, "starter script has no syntax errors")

        let result = m.renderCustomControl(id: id, width: 170, height: 120, fraction: 0.5)
        XCTAssertEqual(result.error, nil)
        XCTAssert(!result.ops.isEmpty, "starter paint callback records draw ops")
    }

    func test_renderCustomControlIsCachedUntilSourceChanges() {
        let m = makeModel()
        m.newDocument()
        m.addControl(kind: .custom)
        let id = try! #require(m.document?.allControls().last?.id)

        let a = m.renderCustomControl(id: id, width: 100, height: 80, fraction: 0.5)
        let b = m.renderCustomControl(id: id, width: 100, height: 80, fraction: 0.5)
        XCTAssertEqual(a.ops.count, b.ops.count, "repeat render served consistently (cache hit)")

        // Editing the script must invalidate the cached render.
        m.setLuaSource(m.luaSource + "\n-- touched\n")
        let c = m.renderCustomControl(id: id, width: 100, height: 80, fraction: 0.5)
        XCTAssertEqual(c.error, nil)
        XCTAssert(!c.ops.isEmpty)
    }

    func test_switchingKindToCustomSeedsPaintOnlyOnce() {
        let m = makeModel()
        m.newDocument()
        m.addControl(kind: .fader)
        let id = try! #require(m.document?.allControls().last?.id)

        m.setControlKind(id, .custom)
        let fn = PresetDocument.paintFunctionName(forControlId: id)
        XCTAssert(m.luaSource.contains("function \(fn)("))

        // Toggling away and back must not duplicate the callback.
        m.setControlKind(id, .fader)
        m.setControlKind(id, .custom)
        let occurrences = m.luaSource.components(separatedBy: "function \(fn)(").count - 1
        XCTAssertEqual(occurrences, 1, "paint callback seeded exactly once")
    }

    // ── Script buttons → generated wrapper Lua ───────────────────────────────

    func test_addingScriptControlWrapsEditorSourceInFunction() {
        let m = makeModel()
        m.newDocument()
        m.setLuaSource("print(\"pressed\")")
        m.addScriptControl(from: .editor)

        let control = try! #require(m.document?.allControls().last)
        let fn = PresetDocument.scriptFunctionName(forControlId: control.id)
        XCTAssertEqual(control.functionName, fn, "pad bound to the generated function")
        XCTAssert(m.luaSource.contains("function \(fn)(valueObject, value)"))
        XCTAssert(m.luaSource.contains("print(\"pressed\")"))

        let engine = LuaEngine()
        XCTAssertEqual(engine.check(m.luaSource), nil, "generated wrapper is valid Lua")
    }

    func test_removingFunctionDeletesOnlyThatFunction() {
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
        XCTAssert(out.contains("function keep(a)"))
        XCTAssert(!out.contains("function drop("))
        XCTAssert(out.contains("print(\"tail\")"))
    }

    // ── Misc pure helpers ────────────────────────────────────────────────────

    func test_libraryNameFromPromptIsShortAndNonEmpty() {
        XCTAssertEqual(AppModel.libraryName(fromPrompt: ""), "AI Script")
        XCTAssertEqual(AppModel.libraryName(fromPrompt: "make a step sequencer with sixteen pads and lights"), "make a step sequencer with sixteen")
    }
}

private extension AppModel {
    /// `addControl` defers `selectedControlId` to the next runloop turn; tests
    /// read the created control directly instead of waiting.
    func selectedControlIdAfterPendingUpdates() -> Int? { selectedControlId }
}
