import Foundation

/// Generates Electra One Lua scripts via any OpenAI-compatible chat-completions
/// endpoint (raw HTTP — no SDK). Works with a local Ollama server, OpenAI,
/// LM Studio, vLLM, OpenRouter, etc. Defaults to Ollama at 127.0.0.1:11434.
enum AIClient {
    /// Local Ollama (OpenAI-compatible) server. The API key is ignored by Ollama.
    static let defaultBaseURL = "http://127.0.0.1:11434"
    static let defaultModel = "llama3.1"

    enum AIError: Error, CustomStringConvertible {
        case badURL
        case http(Int, String)
        case network(String)
        case empty

        var description: String {
            switch self {
            case .badURL: return "Invalid endpoint URL. Check the endpoint in AI Settings."
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

    /// Build the chat-completions URL from a user-supplied base. Accepts bare
    /// hosts ("http://127.0.0.1:11434"), "/v1" roots, or a full endpoint.
    static func completionsURL(base: String) -> URL? {
        var b = base.trimmingCharacters(in: .whitespacesAndNewlines)
        if b.isEmpty { b = defaultBaseURL }
        while b.hasSuffix("/") { b.removeLast() }
        let path: String
        if b.hasSuffix("/chat/completions") {
            path = ""
        } else if b.hasSuffix("/v1") {
            path = "/chat/completions"
        } else {
            path = "/v1/chat/completions"
        }
        return URL(string: b + path)
    }

    /// Stream a generation. `onText` is called with the cumulative text so far
    /// (latest-wins, ordered) for live display. Returns the final, fence-stripped
    /// Lua source.
    static func streamLua(request: String,
                          presetContext: String?,
                          baseURL: String,
                          model: String,
                          apiKey: String?,
                          onText: @escaping (String) async -> Void) async throws -> String {
        guard let url = completionsURL(base: baseURL) else { throw AIError.badURL }
        var userText = request
        if let ctx = presetContext, !ctx.isEmpty {
            userText += "\n\nThe current preset's controls (id — name [type]):\n\(ctx)"
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8000,
            "stream": true,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userText],
            ],
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 120
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // OpenAI-style bearer auth. Ollama ignores it; OpenAI/OpenRouter require it.
        if let key = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: req)
        } catch {
            throw AIError.network(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else { throw AIError.network("no response") }

        guard (200..<300).contains(http.statusCode) else {
            var data = Data()
            for try await b in bytes { data.append(b) }
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { ($0?["error"] as? [String: Any])?["message"] as? String }
                ?? String(data: data, encoding: .utf8) ?? "unknown"
            throw AIError.http(http.statusCode, msg)
        }

        var full = ""
        var lastPushed = 0
        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue } // skip "event:" / blank lines
            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { break }
            guard let d = payload.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any]
            else { continue }
            // OpenAI chat-completions streaming: choices[0].delta.content
            if let choices = obj["choices"] as? [[String: Any]],
               let delta = choices.first?["delta"] as? [String: Any],
               let t = delta["content"] as? String, !t.isEmpty {
                full += t
                // Coalesce UI pushes to roughly every ~24 chars to keep highlighting smooth.
                if full.count - lastPushed >= 24 {
                    lastPushed = full.count
                    await onText(full)
                }
            } else if let err = obj["error"] as? [String: Any] {
                let msg = err["message"] as? String ?? "stream error"
                throw AIError.http(http.statusCode, msg)
            }
        }
        await onText(full) // final flush
        let lua = stripFences(full).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lua.isEmpty else { throw AIError.empty }
        return lua
    }

    /// Example prompts surfaced in the AI bar.
    static let examples: [String] = [
        "Make control 13 a list that selects an algorithm (Space, PitchFactor, TimeFactor, ModFactor, H9) and recolors the parameter controls to match each algorithm.",
        "Add an LFO on a timer that sweeps CC 1 from 0 to 127 as a sine wave a few times per second.",
        "When pad 9 is pressed send MIDI Start, and when pad 10 is pressed send MIDI Stop.",
        "Create a 12-item overlay list for control 14 and print the selected label when it changes.",
        "On preset load, set every fader's name to its CC number and color them all blue.",
    ]

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
