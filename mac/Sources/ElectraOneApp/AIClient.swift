import Foundation

/// Generates Electra One Lua scripts via the Anthropic Messages API (raw HTTP —
/// no official Swift SDK). Defaults to Claude Opus 4.8.
enum AIClient {
    static let defaultModel = "claude-opus-4-8"
    static let models = ["claude-opus-4-8", "claude-sonnet-4-6", "claude-haiku-4-5"]

    enum AIError: Error, CustomStringConvertible {
        case noKey
        case http(Int, String)
        case network(String)
        case empty

        var description: String {
            switch self {
            case .noKey: return "No API key. Add your Anthropic API key in AI Settings."
            case .http(let code, let msg): return "API error \(code): \(msg)"
            case .network(let m): return "Network error: \(m)"
            case .empty: return "The model returned no script."
            }
        }
    }

    private static let systemPrompt = """
    You generate Lua scripts for the Electra One MIDI controller's scripting engine. \
    Output ONLY raw Lua source code — no Markdown fences, no prose, no explanation.

    Electra One Lua API (use these exact names):
    - Lifecycle callbacks you may define: onLoad(), onReady(), onEnter(). Use onReady() for setup.
    - print(...) logs to the console.
    - controller.getModel() -> "mk2"|"mini"; controller.getFirmwareVersion() -> string.
    - info.setText(string) shows text in the status bar.
    - Controls: local c = controls.get(id)  -- id is the control's numeric id
        c:setName(string); c:setColor(color); c:setVisible(bool); c:setSlot(n)
        local v = c:getValue()        -- value object
        v:setOverlayId(overlayId)     -- attach a list overlay
        v:setMin(n); v:setMax(n); v:setDefault(n)
    - Colors are constants: WHITE, RED, ORANGE, BLUE, GREEN, PURPLE (or 6-hex strings like "F49500").
    - Overlays (dropdown lists): overlays.create(overlayId, { {value=0,label="A"}, {value=1,label="B"} })
    - parameterMap.set(deviceId, type, parameterNumber, value); parameterMap.get(deviceId, type, parameterNumber)
      types: PT_CC7, PT_CC14, PT_NRPN, PT_RPN, PT_NOTE, PT_PROGRAM, PT_VIRTUAL
    - MIDI out: midi.sendControlChange(port, channel, cc, value); midi.sendProgramChange(port, channel, program);
      midi.sendNoteOn(port, channel, note, vel); midi.sendNoteOff(...); midi.sendSysex(port, {bytes})  -- ports: PORT_1, PORT_2, PORT_CTRL
    - MIDI in callbacks: function midi.onControlChange(midiInput, channel, cc, value) ... end
    - Timer: timer.setPeriod(ms); timer.enable(); timer.disable(); function timer.onTick() ... end
    - List/virtual control callbacks are bound in the preset JSON via values[].function = "name";
      such a function has signature function name(valueObject, value) and can call valueObject:getControl().
    - Persistence: persist(table); recall(table).

    Write idiomatic, working scripts. Prefer onReady() for initialization. Keep comments concise.
    """

    static func generateLua(request: String, presetContext: String?, model: String, apiKey: String) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw AIError.network("bad URL")
        }
        var userText = request
        if let ctx = presetContext, !ctx.isEmpty {
            userText += "\n\nThe current preset's controls (id — name [type]):\n\(ctx)"
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8000,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userText]],
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 120
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw AIError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw AIError.network("no response") }
        guard (200..<300).contains(http.statusCode) else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { ($0?["error"] as? [String: Any])?["message"] as? String }
                ?? String(data: data, encoding: .utf8) ?? "unknown"
            throw AIError.http(http.statusCode, msg)
        }

        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = obj["content"] as? [[String: Any]] else {
            throw AIError.empty
        }
        let text = content
            .filter { ($0["type"] as? String) == "text" }
            .compactMap { $0["text"] as? String }
            .joined()
        let lua = stripFences(text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lua.isEmpty else { throw AIError.empty }
        return lua
    }

    /// Remove ```lua / ``` fences if the model wrapped the code despite instructions.
    private static func stripFences(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.hasPrefix("```") else { return s }
        if let firstNewline = t.firstIndex(of: "\n") {
            t = String(t[t.index(after: firstNewline)...])  // drop opening fence line
        }
        if let range = t.range(of: "```", options: .backwards) {
            t = String(t[..<range.lowerBound])
        }
        return t
    }
}
