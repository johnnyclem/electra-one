import XCTest
import Foundation
@testable import ElectraKit

private let sox: UInt8 = 0xF0
private let eox: UInt8 = 0xF7
private let mfr: [UInt8] = [0x00, 0x21, 0x45]

final class ProtocolTests: XCTestCase {
    func test_infoRequest() {
        XCTAssertEqual(E1Proto.infoRequest(), [sox] + mfr + [0x02, 0x7F, eox])
    }

    func test_presetRequestActiveVsSlot() {
        XCTAssertEqual(E1Proto.presetRequest(bank: nil, slot: nil), [sox] + mfr + [0x02, 0x01, eox])
        XCTAssertEqual(E1Proto.presetRequest(bank: 3, slot: 7), [sox] + mfr + [0x02, 0x01, 3, 7, eox])
    }

    func test_presetRequestSlotZeroIsReal() {
        // 0 is a valid coordinate — must not collapse to the "active" form.
        XCTAssertEqual(E1Proto.presetRequest(bank: 0, slot: 0), [sox] + mfr + [0x02, 0x01, 0, 0, eox])
    }

    func test_luaRequest() {
        XCTAssertEqual(E1Proto.luaRequest(bank: nil, slot: nil), [sox] + mfr + [0x02, 0x0C, eox])
        XCTAssertEqual(E1Proto.luaRequest(bank: 1, slot: 2), [sox] + mfr + [0x02, 0x0C, 1, 2, eox])
    }

    func test_presetUploadLayout() {
        let msg = E1Proto.presetUpload(json: "{\"n\":1}")
        XCTAssertEqual(Array(msg.prefix(6)), [sox] + mfr + [0x01, 0x01])
        XCTAssertEqual(msg.last, eox)
        let body = Array(msg[6..<(msg.count - 1)])
        XCTAssertEqual(String(bytes: body, encoding: .utf8), "{\"n\":1}")
    }

    func test_luaUploadLayout() {
        let msg = E1Proto.luaUpload(source: "print(1)")
        XCTAssertEqual(msg[4], 0x01)   // op = upload
        XCTAssertEqual(msg[5], 0x0C)   // resource = lua
        let body = Array(msg[6..<(msg.count - 1)])
        XCTAssertEqual(String(bytes: body, encoding: .utf8), "print(1)")
    }

    func test_slotSelectSwitchClear() {
        XCTAssertEqual(E1Proto.presetSlotSelect(bank: 2, slot: 5), [sox] + mfr + [0x14, 0x08, 2, 5, eox])
        XCTAssertEqual(E1Proto.presetSlotSwitch(bank: 2, slot: 5), [sox] + mfr + [0x09, 0x08, 2, 5, eox])
        XCTAssertEqual(E1Proto.clearSlot(bank: 1, slot: 4), [sox] + mfr + [0x05, 0x08, 1, 4, eox])
    }

    func test_classifyData() {
        let msg = [sox] + mfr + [0x01, 0x01, 0x7B, 0x7D, eox]
        guard case let .data(resource, payload) = E1Proto.classify(msg) else {
            XCTFail(String(describing: "expected .data")); return
        }
        XCTAssertEqual(resource, 0x01)
        XCTAssertEqual(payload, [0x7B, 0x7D])
    }

    func test_classifyAck() {
        guard case .ack = E1Proto.classify([sox] + mfr + [0x7E, 0x01, eox]) else {
            XCTFail(String(describing: "expected .ack")); return
        }
    }

    func test_classifyNack() {
        guard case .nack = E1Proto.classify([sox] + mfr + [0x7E, 0x00, eox]) else {
            XCTFail(String(describing: "expected .nack")); return
        }
    }

    func test_classifyTransientStatusIsNotNack() {
        guard case let .status(code) = E1Proto.classify([sox] + mfr + [0x7E, 0x05, eox]) else {
            XCTFail(String(describing: "expected .status")); return
        }
        XCTAssertEqual(code, 0x05)
    }

    func test_classifyRejectsBadManufacturer() {
        guard case .unknown = E1Proto.classify([sox, 0x00, 0x00, 0x00, 0x01, 0x01, eox]) else {
            XCTFail(String(describing: "wrong manufacturer should be unknown")); return
        }
    }

    func test_classifyRejectsMissingEOX() {
        guard case .unknown = E1Proto.classify([sox] + mfr + [0x01, 0x01, 0x00]) else {
            XCTFail(String(describing: "missing EOX should be unknown")); return
        }
    }

    func test_classifyRejectsTooShort() {
        guard case .unknown = E1Proto.classify([sox, eox]) else {
            XCTFail(String(describing: "too short should be unknown")); return
        }
    }

    func test_classifySixByteFrameIsUnknownNotACrash() {
        // F0 00 21 45 01 F7 has valid SOX/manufacturer/EOX but no code/resource
        // byte — the shortest valid message is 7 bytes. Must not trap.
        guard case .unknown = E1Proto.classify([sox] + mfr + [0x01, eox]) else {
            XCTFail(String(describing: "6-byte frame should be unknown")); return
        }
    }

    func test_uploadsAreSevenBitSafe() {
        // SysEx data bytes must be < 0x80; non-ASCII characters are replaced,
        // never emitted as multi-byte UTF-8 (mirrors lib/protocol.js).
        let preset = E1Proto.presetUpload(json: "{\"name\":\"Café — ✓\"}")
        XCTAssert(preset.dropFirst().dropLast().allSatisfy { $0 < 0x80 })
        let lua = E1Proto.luaUpload(source: "print('naïve 中')")
        XCTAssert(lua.dropFirst().dropLast().allSatisfy { $0 < 0x80 })
        // Pure-ASCII bodies still round-trip byte-for-byte.
        let plain = E1Proto.luaUpload(source: "print(1)")
        XCTAssertEqual(String(bytes: plain[6..<(plain.count - 1)], encoding: .utf8), "print(1)")
    }
}
