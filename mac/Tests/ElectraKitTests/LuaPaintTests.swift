import Testing
@testable import LuaKit

/// The graphics recorder: a script that registers a paint callback via
/// `control:setPaintCallback` should produce replayable draw ops.
@Suite struct LuaPaintTests {
    let lua = LuaEngine()

    static let script = """
    local c = controls.get(1)
    c:setPaintCallback(function(obj)
      local b = obj:getBounds()
      graphics.setColor(RED)
      graphics.fillRect(0, 0, b[WIDTH], b[HEIGHT])
      graphics.setColor(WHITE)
      graphics.print(0, 10, "hi", b[WIDTH], CENTER)
    end)
    """

    @Test func recordsDrawOps() {
        let r = lua.paint(Self.script, controlId: 1, width: 100, height: 40, fraction: 0.5)
        #expect(r.ok, "paint errored: \(r.error ?? "?")")
        #expect(r.ops.count == 2)
        let rect = r.ops.first { $0.op == "fillRect" }
        #expect(rect != nil)
        #expect(rect?.a == 100)      // width from getBounds()[WIDTH]
        #expect(rect?.b == 40)       // height
        #expect(rect?.color == 0xF20530) // RED
        let text = r.ops.first { $0.op == "text" }
        #expect(text?.text == "hi")
    }

    @Test func missingCallbackIsNotFatal() {
        // A script with no paint callback for the id returns an error string but
        // never crashes.
        let r = lua.paint("print('nothing')", controlId: 9, width: 10, height: 10, fraction: 0)
        #expect(r.ops.isEmpty)
        #expect((r.error ?? "").contains("no paint callback"))
    }

    @Test func erroringCallbackSurfacesRealError() {
        // A callback that throws must report its message — not be silently
        // swallowed as an empty canvas or misreported as "no callback".
        let s = """
        controls.get(3):setPaintCallback(function(o)
          error('kaboom')
        end)
        """
        let r = lua.paint(s, controlId: 3, width: 10, height: 10, fraction: 0)
        #expect(!r.ok)
        #expect((r.error ?? "").contains("kaboom"))
        #expect(!(r.error ?? "").contains("no paint callback"))
        #expect(r.ops.isEmpty)
    }

    @Test func valueFractionReachesCallback() {
        let s = """
        controls.get(2):setPaintCallback(function(o)
          local h = o:getBounds()[HEIGHT]
          local filled = h * (o:getValue() / 127)
          graphics.fillRect(0, h - filled, 10, filled)
        end)
        """
        let r = lua.paint(s, controlId: 2, width: 10, height: 100, fraction: 1.0)
        #expect(r.ok)
        let rect = r.ops.first { $0.op == "fillRect" }
        #expect(rect?.b == 100) // fraction 1.0 → value 127 → full height
    }
}
