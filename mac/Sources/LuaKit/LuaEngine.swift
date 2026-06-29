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
        let sink = Sink()
        let ctx = Unmanaged.passUnretained(sink).toOpaque()
        guard let L = clua_new(Self.writer, ctx) else {
            return RunResult(output: "", error: "could not create Lua state")
        }
        defer { clua_close(L) }
        let rc = source.withCString { clua_run(L, $0) }
        if rc == 0 {
            return RunResult(output: sink.text, error: nil)
        } else {
            // The error message was written into the sink as the final line.
            var text = sink.text
            if text.hasSuffix("\n") { text.removeLast() }
            let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            let error = lines.last?.trimmingCharacters(in: .whitespaces)
            let output = lines.dropLast().joined(separator: "\n")
            return RunResult(output: output, error: (error?.isEmpty == false) ? error : "error")
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
