import XCTest
import Foundation
@testable import ElectraKit
@testable import LuaKit

/// Every shipped example must at least compile and run cleanly in the offline
/// simulator (top-level code + entry points, with the Electra API mocked). Paint
/// and callback bodies only fire on real hardware, but their enclosing script
/// still has to load without error — that's what these guard.
final class ExampleScriptsTests: XCTestCase {
    let lua = LuaEngine()

    func test_libraryHasAtLeastTwelveExamples() {
        XCTAssert(ExampleLuaScripts.all.count >= 12)
    }

    func test_exampleNamesAreUnique() {
        let names = ExampleLuaScripts.all.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
    }

    func test_everyExampleSyntaxChecks() {
        for ex in ExampleLuaScripts.all {
            XCTAssertEqual(lua.check(ex.source), nil, "\(ex.name) failed to compile")
        }
    }

    func test_everyExampleRunsInSimulator() {
        for ex in ExampleLuaScripts.all {
            let r = lua.simulate(ex.source)
            XCTAssert(r.ok, "\(ex.name) errored at run time: \(r.error ?? "?")")
        }
    }

    func test_everyExampleSetsStatusText() {
        // Each example calls info.setText somewhere at load time so the in-app
        // Run preview shows something meaningful, not a blank bar.
        for ex in ExampleLuaScripts.all where ex.name != "Hello World (example)" {
            let r = lua.simulate(ex.source)
            XCTAssertEqual(r.bottomText?.isEmpty, false, "\(ex.name) set no status text")
        }
    }
}
