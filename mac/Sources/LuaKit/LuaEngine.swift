import CLua
import Foundation

/// Runs Lua scripts in-process for the editor's build/run preview.
///
/// Device-specific Electra APIs (controls, midi, parameterMap, timer, …) are
/// mocked so scripts execute without the hardware; `print()` output and any
/// compile/runtime errors are captured. An instruction-count guard prevents an
/// infinite loop from hanging the app. True device behaviour comes from
/// uploading the script to the Electra One.
public final class LuaEngine {
    public struct RunResult: Sendable {
        public var output: String
        public var error: String?
        public var ok: Bool { error == nil }
    }

    /// Collects writer output. Held by the C side via an opaque pointer.
    final class Sink { var text = "" }

    public init() {}

    /// Syntax-check only ("Build"). Returns an error message, or nil if it compiles.
    public func check(_ source: String) -> String? {
        let sink = Sink()
        let ctx = Unmanaged.passUnretained(sink).toOpaque()
        let rc = source.withCString { clua_check($0, Self.writer, ctx) }
        return rc == 0 ? nil : sink.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Compile + run, capturing print output and any error.
    public func run(_ source: String) -> RunResult {
        simulate(source).run
    }

    /// Result of a simulator run: the script output plus observable device state
    /// (the status-bar text the script set via `info.setText`).
    public struct SimResult: Sendable {
        public var output: String
        public var error: String?
        public var bottomText: String?
        public var ok: Bool { error == nil }
        var run: RunResult { RunResult(output: output, error: error) }
    }

    /// Compile + run in the mocked Electra environment, capturing print output,
    /// any error, and the simulated status-bar text. This is what the in-app
    /// "Run" simulator uses.
    public func simulate(_ source: String) -> SimResult {
        let sink = Sink()
        let ctx = Unmanaged.passUnretained(sink).toOpaque()
        guard let L = clua_new(Self.writer, ctx) else {
            return SimResult(output: "", error: "could not create Lua state", bottomText: nil)
        }
        defer { clua_close(L) }
        let rc = source.withCString { clua_run(L, $0) }

        // Pull back observable state regardless of success (a script may set the
        // status bar before erroring later).
        var bottom: String? = nil
        var buf = [CChar](repeating: 0, count: 256)
        if clua_global_string(L, "__sim_bottom", &buf, buf.count) == 1 {
            bottom = String(cString: buf)
        }

        if rc == 0 {
            return SimResult(output: sink.text, error: nil, bottomText: bottom)
        } else {
            // The error message was written into the sink as the final line.
            var text = sink.text
            if text.hasSuffix("\n") { text.removeLast() }
            let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            let error = lines.last?.trimmingCharacters(in: .whitespaces)
            let output = lines.dropLast().joined(separator: "\n")
            return SimResult(output: output, error: (error?.isEmpty == false) ? error : "error", bottomText: bottom)
        }
    }

    // ── Custom-control paint rendering ─────────────────────────────────────────

    /// One recorded drawing operation from a script's `graphics.*` calls.
    /// Numeric slots `x/y/a/b/c/d` carry op-specific coordinates (see `op`);
    /// `color` is 24-bit RGB; `text` is set only for the `text` op.
    public struct DrawOp: Sendable {
        public var op: String
        public var x, y, a, b, c, d: Double
        public var color: UInt32
        public var text: String
    }

    public struct PaintResult: Sendable {
        public var ops: [DrawOp]
        public var error: String?
        public var ok: Bool { error == nil }
    }

    /// Load `source`, then run the paint callback the script registered for
    /// `controlId` (via `control:setPaintCallback`) at the given size and
    /// normalized value, returning the recorded draw operations. This is what
    /// lets a script-drawn Custom control render live in the app.
    public func paint(_ source: String, controlId: Int,
                      width: Double, height: Double, fraction: Double) -> PaintResult {
        let sink = Sink()
        let ctx = Unmanaged.passUnretained(sink).toOpaque()
        guard let L = clua_new(Self.writer, ctx) else {
            return PaintResult(ops: [], error: "could not create Lua state")
        }
        defer { clua_close(L) }

        if source.withCString({ clua_run(L, $0) }) != 0 {
            return PaintResult(ops: [], error: Self.lastLine(sink.text))
        }
        if clua_render(L, Int32(controlId), width, height, fraction) != 0 {
            // No paint callback registered for this id, or it errored — not fatal;
            // surface it as an empty canvas with a hint.
            return PaintResult(ops: [], error: "no paint callback for control \(controlId)")
        }
        var buf = [CChar](repeating: 0, count: 64 * 1024)
        guard clua_global_string(L, "__draw_json", &buf, buf.count) == 1 else {
            return PaintResult(ops: [], error: nil)
        }
        return PaintResult(ops: Self.parseOps(String(cString: buf)), error: nil)
    }

    private static func lastLine(_ text: String) -> String {
        var t = text
        if t.hasSuffix("\n") { t.removeLast() }
        return t.split(separator: "\n").last.map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? "error"
    }

    /// Parse the tab-separated op rows emitted by `__serialize`.
    private static func parseOps(_ s: String) -> [DrawOp] {
        s.split(separator: "\n", omittingEmptySubsequences: true).compactMap { line in
            let f = line.split(separator: "\t", maxSplits: 8, omittingEmptySubsequences: false)
            guard f.count >= 8 else { return nil }
            func num(_ i: Int) -> Double { Double(f[i]) ?? 0 }
            return DrawOp(
                op: String(f[0]),
                x: num(1), y: num(2), a: num(3), b: num(4), c: num(5), d: num(6),
                color: UInt32(f[7]) ?? 0xFFFFFF,
                text: f.count >= 9 ? String(f[8]) : "")
        }
    }

    // C writer trampoline: ctx is an unretained Sink pointer.
    private static let writer: @convention(c) (UnsafePointer<CChar>?, Int, UnsafeMutableRawPointer?) -> Void = { ptr, len, ctx in
        guard let ptr, let ctx, len > 0 else { return }
        let sink = Unmanaged<Sink>.fromOpaque(ctx).takeUnretainedValue()
        let data = Data(bytes: ptr, count: len)
        if let s = String(data: data, encoding: .utf8) { sink.text += s }
    }
}
