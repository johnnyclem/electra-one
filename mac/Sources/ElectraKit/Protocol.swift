import Foundation

/// Electra One SysEx framing and message classification.
///
/// Mirrors lib/protocol.js. Manufacturer ID is `00 21 45`. Requests use op
/// `0x02`; data dumps/uploads use op `0x01`. Uploads always go to the *active*
/// slot — to target a slot, arm it first with `presetSlotSelect` (`0x14 0x08`).
public enum E1Proto {
    public static let sox: UInt8 = 0xF0
    public static let eox: UInt8 = 0xF7
    public static let manufacturer: [UInt8] = [0x00, 0x21, 0x45]

    enum Op {
        static let upload: UInt8 = 0x01
        static let request: UInt8 = 0x02
        static let response: UInt8 = 0x01
        static let selectSlot: UInt8 = 0x14
        static let ackNack: UInt8 = 0x7E
    }

    enum Res {
        static let preset: UInt8 = 0x01
        static let lua: UInt8 = 0x0C
        static let info: UInt8 = 0x7F
        static let runtime: UInt8 = 0x7E
    }

    // ACK/NACK codes carried in the byte after the 0x7E op.
    static let ack: UInt8 = 0x01
    static let nak: UInt8 = 0x00

    static func frame(_ bytes: UInt8...) -> [UInt8] {
        [sox] + manufacturer + bytes + [eox]
    }

    public static func infoRequest() -> [UInt8] {
        frame(Op.request, Res.info)
    }

    public static func presetRequest(bank: Int?, slot: Int?) -> [UInt8] {
        if let b = bank, let s = slot {
            return frame(Op.request, Res.preset, UInt8(b), UInt8(s))
        }
        return frame(Op.request, Res.preset)
    }

    public static func luaRequest(bank: Int?, slot: Int?) -> [UInt8] {
        if let b = bank, let s = slot {
            return frame(Op.request, Res.lua, UInt8(b), UInt8(s))
        }
        return frame(Op.request, Res.lua)
    }

    /// Build a preset-upload message. The JSON body follows the resource byte
    /// directly — there is no bank/slot variant of the upload command.
    public static func presetUpload(json: String) -> [UInt8] {
        let body = Array(json.utf8)
        return [sox] + manufacturer + [Op.upload, Res.preset] + body + [eox]
    }

    /// "Set preset slot" — arm the given bank/slot as the active target.
    public static func presetSlotSelect(bank: Int, slot: Int) -> [UInt8] {
        frame(Op.selectSlot, 0x08, UInt8(bank), UInt8(slot))
    }

    /// Upload a Lua script to the active slot (op `0x01`, resource `0x0C`).
    public static func luaUpload(source: String) -> [UInt8] {
        let body = Array(source.utf8)
        return [sox] + manufacturer + [Op.upload, Res.lua] + body + [eox]
    }

    /// A classified inbound SysEx message.
    public enum Message {
        case data(resource: UInt8, payload: [UInt8])
        case ack
        case nack
        case status(code: UInt8)   // e.g. 0x05 notification — not a result
        case unknown
    }

    public static func classify(_ msg: [UInt8]) -> Message {
        guard msg.count >= 6,
              msg[0] == sox,
              msg[1] == 0x00, msg[2] == 0x21, msg[3] == 0x45,
              msg.last == eox
        else { return .unknown }

        let op = msg[4]
        if op == Op.response {
            let payload = Array(msg[6..<(msg.count - 1)])
            return .data(resource: msg[5], payload: payload)
        }
        if op == Op.ackNack {
            switch msg[5] {
            case ack: return .ack
            case nak: return .nack
            default:  return .status(code: msg[5])
            }
        }
        return .unknown
    }
}
