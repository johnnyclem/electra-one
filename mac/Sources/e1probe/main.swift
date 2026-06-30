import ElectraKit
import LuaKit
import Foundation

@main
struct Probe {
    static func main() async {
        if CommandLine.arguments.contains("lua") { luaSelfTest(); return }
        if CommandLine.arguments.contains("doc") { docSelfTest(); return }
        await probeDevice()
    }

    static func luaSelfTest() {
        let lua = LuaEngine()
        let r1 = lua.run(#"print("hello", 1 + 2)"#)
        print("1) print: ok=\(r1.ok) out=\(r1.output.debugDescription)")

        let r2 = lua.run(#"""
        local c = controls.get(13)
        c:setColor(RED)
        parameterMap.set(1, PT_CC7, 5, 100)
        print("electra api ran")
        """#)
        print("2) electra mock: ok=\(r2.ok) out=\(r2.output.debugDescription) err=\(r2.error ?? "-")")

        print("3) syntax check 'print(': \(lua.check("print(") ?? "OK")")

        let r4 = lua.run("while true do end")
        print("4) loop guard: ok=\(r4.ok) err=\(r4.error ?? "-")")

        let r5 = lua.run(#"function onReady() print("ready!") end"#)
        print("5) entrypoint: ok=\(r5.ok) out=\(r5.output.debugDescription)")

        let r6 = lua.simulate(#"""
        info.setText("patch 12")
        print("model:", controller.getModel())
        """#)
        print("6) simulator: ok=\(r6.ok) bottom=\(r6.bottomText.debugDescription) out=\(r6.output.debugDescription)")
        print("✓ lua self-test done")
    }

    /// Offline model check — no device needed.
    static func docSelfTest() {
        // Round-trip the bundled demo preset, if present.
        let path = "../presets/b0_s00_Demo_Preset.json"
        if let text = try? String(contentsOfFile: path, encoding: .utf8),
           let doc = PresetDocument(jsonString: text) {
            print("Loaded \"\(doc.name)\"  pages: \(doc.pages.count)  controls: \(doc.allControls().count)")

            // Round-trip must preserve every top-level key.
            func topKeys(_ s: String) -> Set<String> {
                guard let o = (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [String: Any] else { return [] }
                return Set(o.keys)
            }
            let before = topKeys(text), after = topKeys(doc.jsonString())
            print("Top-level keys preserved: \(before == after)  (\(before.sorted().joined(separator: ",")))")

            // Mutate one control; confirm only that control's name changed and counts hold.
            var edited = doc
            if let first = doc.allControls().first {
                edited.setControlName(id: first.id, "RENAMED")
                let ok = edited.control(id: first.id)?.name == "RENAMED"
                    && edited.allControls().count == doc.allControls().count
                print("Targeted edit preserves structure: \(ok)")
            }
        } else {
            print("(demo preset not found at \(path) — testing template instead)")
        }

        // Import the example .eproj project (repo moved it into projects/).
        let eprojCandidates = ["../projects/eventide_h9_max.eproj", "../eventide_h9_max.eproj"]
        let eprojPath = eprojCandidates.first { FileManager.default.fileExists(atPath: $0) } ?? eprojCandidates[0]
        if let text = try? String(contentsOfFile: eprojPath, encoding: .utf8) {
            print("isProject(eproj): \(PresetDocument.isProject(text))")
            if let doc = PresetDocument.load(fileText: text) {
                let controls = doc.allControls()
                print("Imported \"\(doc.name)\"  controls: \(controls.count)  lua: \(doc.lua != nil ? "\(doc.lua!.count) chars" : "none")")
                if let c = controls.first {
                    print("  first control: id=\(c.id) type=\(c.type) name=\"\(c.name)\" bounds=(\(Int(c.x)),\(Int(c.y)),\(Int(c.w)),\(Int(c.h))) set=\(c.controlSetId) pot=\(c.potId ?? -1)")
                }
                let types = Set(controls.map { $0.type }).sorted().joined(separator: ",")
                print("  control types: \(types)")
                print("  serialized preset re-parses: \(PresetDocument(jsonString: doc.jsonString()) != nil)")
                print("  no project keys leaked: \(!doc.jsonString().contains("\"tiles\"") && !doc.jsonString().contains("schemaVersion"))")
            } else {
                print("✗ failed to import eproj")
            }
        } else {
            print("(eproj example not found at \(eprojPath))")
        }

        // Template + addControl.
        var fresh = PresetDocument.newPreset(name: "Test")
        let id = fresh.addControl(pageId: 1)
        let c = fresh.control(id: id)
        print("New preset: control added id=\(id) type=\(c?.type ?? "?") bounds=(\(Int(c?.x ?? 0)),\(Int(c?.y ?? 0)),\(Int(c?.w ?? 0)),\(Int(c?.h ?? 0)))")
        print("Re-parse of serialized template valid: \(PresetDocument(jsonString: fresh.jsonString()) != nil)")

        // Control kinds: knob (fader+dial) and ADSR (4 values).
        let knobId = fresh.addControl(kind: .knob, pageId: 1)
        let knob = fresh.control(id: knobId)
        print("Knob: type=\(knob?.type ?? "?") variant=\(knob?.variant ?? "-") kind=\(knob?.kind.rawValue ?? "?")")
        let adsrId = fresh.addControl(kind: .adsr, pageId: 1)
        let adsr = fresh.control(id: adsrId)
        let adsrVals = fresh.controlValues(id: adsrId)
        print("ADSR: type=\(adsr?.type ?? "?") kind=\(adsr?.kind.rawValue ?? "?") valueCount=\(adsr?.valueCount ?? -1) values=\(adsrVals.map { "\($0.valueId):\($0.parameterNumber ?? -1)" }.joined(separator: ","))")
        // Switch the knob to ADSR then back — structure must stay valid.
        fresh.setControlKind(id: knobId, .adsr)
        let switched = fresh.controlValues(id: knobId).count
        fresh.setControlKind(id: knobId, .fader)
        let collapsed = fresh.controlValues(id: knobId).count
        print("Kind switch knob→adsr→fader value counts: \(switched) then \(collapsed)")
        print("Re-parse after kind edits valid: \(PresetDocument(jsonString: fresh.jsonString()) != nil)")
        print("✓ doc self-test done")
    }

    static func probeDevice() async {
        let device = E1Device()
        do {
            let ports = try await device.connect()
            print("Connected → in: \(ports.input) | out: \(ports.output)")

            let info = try await device.getInfo()
            print("Device   → \(info.modelUpper)  fw \(info.versionText ?? "?")  serial \(info.serial ?? "?")")

            print("Scanning bank 0 …")
            for slot in 0..<6 {
                let s = await device.scanSlot(bank: 0, slot: slot)
                let detail = s.name ?? s.error ?? "—"
                print(String(format: "  [%02d] %-7@ %@", slot, s.status.rawValue as NSString, detail))
            }

            // Round-trip a read of slot 1 to prove large fragmented reads work.
            if let summary = try? await device.summarize(bank: 0, slot: 1) {
                print("Slot 1   → \"\(summary.name)\"  controls: \(summary.controls)  pages: \(summary.pages)")
            }

            await device.disconnect()
            print("✓ probe completed")
        } catch {
            print("ERROR: \(error)")
            await device.disconnect()
            exit(1)
        }
    }
}
