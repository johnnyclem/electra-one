import XCTest
import Foundation
@testable import LuaKit

final class LuaEngineTests: XCTestCase {
    let lua = LuaEngine()

    func test_checkPassesValidSource() {
        XCTAssertEqual(lua.check("local x = 1 + 2"), nil)
    }

    func test_checkReportsSyntaxError() {
        let err = lua.check("print(")
        XCTAssertNotEqual(err, nil)
        XCTAssert((err ?? "").contains("unexpected symbol") || (err ?? "").contains("eof"))
    }

    func test_runCapturesPrintOutput() {
        let r = lua.run(#"print("hello", 1 + 2)"#)
        XCTAssert(r.ok)
        XCTAssertEqual(r.output, "hello\t3\n")
    }

    func test_infiniteLoopGuardStopsExecution() {
        let r = lua.run("while true do end")
        XCTAssert(!r.ok)
        XCTAssert((r.error ?? "").contains("instruction limit"))
    }

    func test_mockedElectraAPIDoesNotCrash() {
        let r = lua.run(#"""
        local c = controls.get(13)
        c:setColor(RED)
        c:setName("X")
        parameterMap.set(1, PT_CC7, 5, 100)
        midi.sendControlChange(PORT_1, 1, 74, 64)
        print("ok")
        """#)
        XCTAssert(r.ok)
        XCTAssert(r.output.contains("ok"))
    }

    func test_entryPointsAreInvoked() {
        let r = lua.run(#"function onReady() print("ready!") end"#)
        XCTAssert(r.ok)
        XCTAssert(r.output.contains("ready!"))
    }

    func test_simulatorCapturesBottomText() {
        let r = lua.simulate(#"""
        info.setText("patch 12")
        print("model:", controller.getModel())
        """#)
        XCTAssert(r.ok)
        XCTAssertEqual(r.bottomText, "patch 12")
        XCTAssert(r.output.contains("mk2"))
    }

    func test_simulatorReportsRuntimeError() {
        let r = lua.simulate("error('boom')")
        XCTAssert(!r.ok)
        XCTAssert((r.error ?? "").contains("boom"))
    }
}
