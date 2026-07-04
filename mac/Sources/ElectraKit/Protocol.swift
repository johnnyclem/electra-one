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

    /// Hardware layout: 6 banks × 12 preset slots (mirrors lib/protocol.js).
    public static let banks = 6
    public static let slotsPerBank = 12

    enum Op {
        static let upload: UInt8 = 0x01
        static let request: UInt8 = 0x02
        static let response: UInt8 = 0x01
        static let remove: UInt8 = 0x05
        static let switchActive: UInt8 = 0x09   // "Switch" — activates/loads a resource
        static let selectSlot: UInt8 = 0x14     // "updateRuntime" — Set Preset Slot only arms it
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

    static func frame(_ bytes: [UInt8]) -> [UInt8] {
        [sox] + manufacturer + bytes + [eox]
    }

    static func frame(_ bytes: UInt8...) -> [UInt8] {
        frame(bytes)
    }

    /// Clamp a bank into its hardware range — `UInt8(_:)` would trap on
    /// out-of-range Ints, and the API is non-throwing.
    private static func bankByte(_ bank: Int) -> UInt8 {
        UInt8(min(max(bank, 0), banks - 1))
    }

    /// Clamp a slot into its hardware range (see `bankByte`).
    private static func slotByte(_ slot: Int) -> UInt8 {
        UInt8(min(max(slot, 0), slotsPerBank - 1))
    }

    /// SysEx data bytes must be 7-bit (< 0x80), but UTF-8 emits high bytes for
    /// non-ASCII characters — which would corrupt the stream. Replace such
    /// scalars with '?'; the JS twin (lib/protocol.js) likewise coerces bodies
    /// to 7-bit via Node's 'ascii' encoding.
    private static func asciiBody(_ text: String) -> [UInt8] {
        text.unicodeScalars.map { $0.isASCII ? UInt8($0.value) : 0x3F /* '?' */ }
    }

    public static func infoRequest() -> [UInt8] {
        frame(Op.request, Res.info)
    }

    public static func presetRequest(bank: Int?, slot: Int?) -> [UInt8] {
        if let b = bank, let s = slot {
            return frame(Op.request, Res.preset, bankByte(b), slotByte(s))
        }
        return frame(Op.request, Res.preset)
    }

    public static func luaRequest(bank: Int?, slot: Int?) -> [UInt8] {
        if let b = bank, let s = slot {
            return frame(Op.request, Res.lua, bankByte(b), slotByte(s))
        }
        return frame(Op.request, Res.lua)
    }

    /// Build a preset-upload message. The JSON body follows the resource byte
    /// directly — there is no bank/slot variant of the upload command.
    public static func presetUpload(json: String) -> [UInt8] {
        frame([Op.upload, Res.preset] + asciiBody(json))
    }

    /// "Set preset slot" (op `0x14`, res `0x08`) — arm the given bank/slot as the
    /// target for subsequent file operations. Does NOT load the preset.
    public static func presetSlotSelect(bank: Int, slot: Int) -> [UInt8] {
        frame(Op.selectSlot, 0x08, bankByte(bank), slotByte(slot))
    }

    /// "Switch preset slot" (op `0x09`, res `0x08`) — make the slot active and
    /// load its preset (the controller switches to display/run it).
    public static func presetSlotSwitch(bank: Int, slot: Int) -> [UInt8] {
        frame(Op.switchActive, 0x08, bankByte(bank), slotByte(slot))
    }

    /// Upload a Lua script to the active slot (op `0x01`, resource `0x0C`).
    public static func luaUpload(source: String) -> [UInt8] {
        frame([Op.upload, Res.lua] + asciiBody(source))
    }

    /// "Clear preset slot" (op `0x05`, resource `0x08`) — permanently removes
    /// all files in the slot (preset + Lua), freeing a burned/corrupt slot.
    public static func clearSlot(bank: Int, slot: Int) -> [UInt8] {
        frame(Op.remove, 0x08, bankByte(bank), slotByte(slot))
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
        // Shortest valid message is 7 bytes: F0 00 21 45 <op> <code/res> F7.
        guard msg.count >= 7,
              msg[0] == sox,
              Array(msg[1...3]) == manufacturer,
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
