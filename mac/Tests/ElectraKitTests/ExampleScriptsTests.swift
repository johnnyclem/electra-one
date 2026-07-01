import Testing
@testable import ElectraKit
@testable import LuaKit

/// Every shipped example must at least compile and run cleanly in the offline
/// simulator (top-level code + entry points, with the Electra API mocked). Paint
/// and callback bodies only fire on real hardware, but their enclosing script
/// still has to load without error — that's what these guard.
@Suite struct ExampleScriptsTests {
    let lua = LuaEngine()

    @Test func libraryHasAtLeastTwelveExamples() {
        #expect(ExampleLuaScripts.all.count >= 12)
    }

    @Test func exampleNamesAreUnique() {
        let names = ExampleLuaScripts.all.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test func everyExampleSyntaxChecks() {
        for ex in ExampleLuaScripts.all {
            #expect(lua.check(ex.source) == nil, "\(ex.name) failed to compile")
        }
    }

    @Test func everyExampleRunsInSimulator() {
        for ex in ExampleLuaScripts.all {
            let r = lua.simulate(ex.source)
            #expect(r.ok, "\(ex.name) errored at run time: \(r.error ?? "?")")
        }
    }

    @Test func everyExampleSetsStatusText() {
        // Each example calls info.setText somewhere at load time so the in-app
        // Run preview shows something meaningful, not a blank bar.
        for ex in ExampleLuaScripts.all where ex.name != "Hello World (example)" {
            let r = lua.simulate(ex.source)
            #expect(r.bottomText?.isEmpty == false, "\(ex.name) set no status text")
        }
    }
}
