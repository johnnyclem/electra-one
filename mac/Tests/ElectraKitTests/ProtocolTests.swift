import Testing
@testable import ElectraKit

private let sox: UInt8 = 0xF0
private let eox: UInt8 = 0xF7
private let mfr: [UInt8] = [0x00, 0x21, 0x45]

@Suite struct ProtocolTests {
    @Test func infoRequest() {
        #expect(E1Proto.infoRequest() == [sox] + mfr + [0x02, 0x7F, eox])
    }

    @Test func presetRequestActiveVsSlot() {
        #expect(E1Proto.presetRequest(bank: nil, slot: nil) == [sox] + mfr + [0x02, 0x01, eox])
        #expect(E1Proto.presetRequest(bank: 3, slot: 7) == [sox] + mfr + [0x02, 0x01, 3, 7, eox])
    }

    @Test func presetRequestSlotZeroIsReal() {
        // 0 is a valid coordinate — must not collapse to the "active" form.
        #expect(E1Proto.presetRequest(bank: 0, slot: 0) == [sox] + mfr + [0x02, 0x01, 0, 0, eox])
    }

    @Test func luaRequest() {
        #expect(E1Proto.luaRequest(bank: nil, slot: nil) == [sox] + mfr + [0x02, 0x0C, eox])
        #expect(E1Proto.luaRequest(bank: 1, slot: 2) == [sox] + mfr + [0x02, 0x0C, 1, 2, eox])
    }

    @Test func presetUploadLayout() {
        let msg = E1Proto.presetUpload(json: "{\"n\":1}")
        #expect(Array(msg.prefix(6)) == [sox] + mfr + [0x01, 0x01])
        #expect(msg.last == eox)
        let body = Array(msg[6..<(msg.count - 1)])
        #expect(String(bytes: body, encoding: .utf8) == "{\"n\":1}")
    }

    @Test func luaUploadLayout() {
        let msg = E1Proto.luaUpload(source: "print(1)")
        #expect(msg[4] == 0x01)   // op = upload
        #expect(msg[5] == 0x0C)   // resource = lua
        let body = Array(msg[6..<(msg.count - 1)])
        #expect(String(bytes: body, encoding: .utf8) == "print(1)")
    }

    @Test func slotSelectSwitchClear() {
        #expect(E1Proto.presetSlotSelect(bank: 2, slot: 5) == [sox] + mfr + [0x14, 0x08, 2, 5, eox])
        #expect(E1Proto.presetSlotSwitch(bank: 2, slot: 5) == [sox] + mfr + [0x09, 0x08, 2, 5, eox])
        #expect(E1Proto.clearSlot(bank: 1, slot: 4) == [sox] + mfr + [0x05, 0x08, 1, 4, eox])
    }

    @Test func classifyData() {
        let msg = [sox] + mfr + [0x01, 0x01, 0x7B, 0x7D, eox]
        guard case let .data(resource, payload) = E1Proto.classify(msg) else {
            Issue.record("expected .data"); return
        }
        #expect(resource == 0x01)
        #expect(payload == [0x7B, 0x7D])
    }

    @Test func classifyAck() {
        guard case .ack = E1Proto.classify([sox] + mfr + [0x7E, 0x01, eox]) else {
            Issue.record("expected .ack"); return
        }
    }

    @Test func classifyNack() {
        guard case .nack = E1Proto.classify([sox] + mfr + [0x7E, 0x00, eox]) else {
            Issue.record("expected .nack"); return
        }
    }

    @Test func classifyTransientStatusIsNotNack() {
        guard case let .status(code) = E1Proto.classify([sox] + mfr + [0x7E, 0x05, eox]) else {
            Issue.record("expected .status"); return
        }
        #expect(code == 0x05)
    }

    @Test func classifyRejectsBadManufacturer() {
        guard case .unknown = E1Proto.classify([sox, 0x00, 0x00, 0x00, 0x01, 0x01, eox]) else {
            Issue.record("wrong manufacturer should be unknown"); return
        }
    }

    @Test func classifyRejectsMissingEOX() {
        guard case .unknown = E1Proto.classify([sox] + mfr + [0x01, 0x01, 0x00]) else {
            Issue.record("missing EOX should be unknown"); return
        }
    }

    @Test func classifyRejectsTooShort() {
        guard case .unknown = E1Proto.classify([sox, eox]) else {
            Issue.record("too short should be unknown"); return
        }
    }

    @Test func classifySixByteFrameIsUnknownNotACrash() {
        // F0 00 21 45 01 F7 has valid SOX/manufacturer/EOX but no code/resource
        // byte — the shortest valid message is 7 bytes. Must not trap.
        guard case .unknown = E1Proto.classify([sox] + mfr + [0x01, eox]) else {
            Issue.record("6-byte frame should be unknown"); return
        }
    }

    @Test func uploadsAreSevenBitSafe() {
        // SysEx data bytes must be < 0x80; non-ASCII characters are replaced,
        // never emitted as multi-byte UTF-8 (mirrors lib/protocol.js).
        let preset = E1Proto.presetUpload(json: "{\"name\":\"Café — ✓\"}")
        #expect(preset.dropFirst().dropLast().allSatisfy { $0 < 0x80 })
        let lua = E1Proto.luaUpload(source: "print('naïve 中')")
        #expect(lua.dropFirst().dropLast().allSatisfy { $0 < 0x80 })
        // Pure-ASCII bodies still round-trip byte-for-byte.
        let plain = E1Proto.luaUpload(source: "print(1)")
        #expect(String(bytes: plain[6..<(plain.count - 1)], encoding: .utf8) == "print(1)")
    }
}
