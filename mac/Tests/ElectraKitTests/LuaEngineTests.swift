import Testing
@testable import LuaKit

@Suite struct LuaEngineTests {
    let lua = LuaEngine()

    @Test func checkPassesValidSource() {
        #expect(lua.check("local x = 1 + 2") == nil)
    }

    @Test func checkReportsSyntaxError() {
        let err = lua.check("print(")
        #expect(err != nil)
        #expect((err ?? "").contains("unexpected symbol") || (err ?? "").contains("eof"))
    }

    @Test func runCapturesPrintOutput() {
        let r = lua.run(#"print("hello", 1 + 2)"#)
        #expect(r.ok)
        #expect(r.output == "hello\t3\n")
    }

    @Test func infiniteLoopGuardStopsExecution() {
        let r = lua.run("while true do end")
        #expect(!r.ok)
        #expect((r.error ?? "").contains("instruction limit"))
    }

    @Test func mockedElectraAPIDoesNotCrash() {
        let r = lua.run(#"""
        local c = controls.get(13)
        c:setColor(RED)
        c:setName("X")
        parameterMap.set(1, PT_CC7, 5, 100)
        midi.sendControlChange(PORT_1, 1, 74, 64)
        print("ok")
        """#)
        #expect(r.ok)
        #expect(r.output.contains("ok"))
    }

    @Test func entryPointsAreInvoked() {
        let r = lua.run(#"function onReady() print("ready!") end"#)
        #expect(r.ok)
        #expect(r.output.contains("ready!"))
    }

    @Test func simulatorCapturesBottomText() {
        let r = lua.simulate(#"""
        info.setText("patch 12")
        print("model:", controller.getModel())
        """#)
        #expect(r.ok)
        #expect(r.bottomText == "patch 12")
        #expect(r.output.contains("mk2"))
    }

    @Test func simulatorReportsRuntimeError() {
        let r = lua.simulate("error('boom')")
        #expect(!r.ok)
        #expect((r.error ?? "").contains("boom"))
    }
}
