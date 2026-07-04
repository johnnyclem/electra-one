import CoreMIDI
import Foundation

public enum E1Error: Error, CustomStringConvertible {
    case notConnected
    case notFound
    case timeout
    case nack
    case empty
    case midi(OSStatus, String)
    case decode(String)

    public var description: String {
        switch self {
        case .notConnected:        return "Not connected to the Electra One."
        case .notFound:            return "Electra One not found — is it plugged in?"
        case .timeout:             return "Timeout — device did not respond."
        case .nack:                return "Device rejected the command (NACK)."
        case .empty:               return "Slot is empty."
        case .midi(let s, let m):  return "MIDI error (\(s)): \(m)"
        case .decode(let m):       return "Decode error: \(m)"
        }
    }
}

public struct PortNames: Sendable {
    public let input: String
    public let output: String

    public init(input: String, output: String) {
        self.input = input
        self.output = output
    }
}

/// CoreMIDI transport for the Electra One.
///
/// Mirrors lib/transport.js: one persistent client/port pair, SysEx exchanges
/// serialized by the owning `E1Device` actor, fragmented responses reassembled
/// until EOX. Large uploads go through `MIDISendSysex`, which streams the
/// message in the background; the device reassembles.
public final class MIDITransport: E1TransportProtocol, @unchecked Sendable {
    private var client = MIDIClientRef()
    private var inPort = MIDIPortRef()
    private var outPort = MIDIPortRef()
    private var source = MIDIEndpointRef()
    private var dest = MIDIEndpointRef()

    private var _connected = false
    private var _portNames: PortNames?

    public var connected: Bool {
        lock.lock(); defer { lock.unlock() }
        return _connected
    }

    public var portNames: PortNames? {
        lock.lock(); defer { lock.unlock() }
        return _portNames
    }

    private let lock = NSLock()
    private var buffer: [UInt8] = []
    private var waiter: ((E1Proto.Message) -> Void)?
    /// Fails the in-flight exchange from outside the message path (disconnect).
    private var waiterFail: ((Error) -> Void)?

    public init() {}

    // ── Discovery ───────────────────────────────────────────────────────────

    private static func displayName(_ endpoint: MIDIEndpointRef) -> String {
        var cf: Unmanaged<CFString>?
        let st = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &cf)
        guard st == noErr, let name = cf?.takeRetainedValue() else { return "" }
        return name as String
    }

    private static func score(_ name: String) -> Int {
        guard name.contains("Electra") else { return -1 }
        if name.contains("CTRL")    { return 3 }
        if name.contains("PORT 3")  { return 2 }
        if name.contains("MIDIIN3") { return 2 }
        return 1
    }

    public static func listPorts() -> (inputs: [String], outputs: [String]) {
        let ins = (0..<MIDIGetNumberOfSources()).map { displayName(MIDIGetSource($0)) }
        let outs = (0..<MIDIGetNumberOfDestinations()).map { displayName(MIDIGetDestination($0)) }
        return (ins, outs)
    }

    private func bestSource() -> (MIDIEndpointRef, String)? {
        var best: (MIDIEndpointRef, String, Int)?
        for i in 0..<MIDIGetNumberOfSources() {
            let ep = MIDIGetSource(i)
            let name = MIDITransport.displayName(ep)
            let s = MIDITransport.score(name)
            if s >= 0, best == nil || s > best!.2 { best = (ep, name, s) }
        }
        return best.map { ($0.0, $0.1) }
    }

    private func bestDest() -> (MIDIEndpointRef, String)? {
        var best: (MIDIEndpointRef, String, Int)?
        for i in 0..<MIDIGetNumberOfDestinations() {
            let ep = MIDIGetDestination(i)
            let name = MIDITransport.displayName(ep)
            let s = MIDITransport.score(name)
            if s >= 0, best == nil || s > best!.2 { best = (ep, name, s) }
        }
        return best.map { ($0.0, $0.1) }
    }

    // ── Lifecycle ───────────────────────────────────────────────────────────

    @discardableResult
    public func connect() throws -> PortNames {
        if connected, let p = portNames { return p }

        var c = MIDIClientRef()
        var ip = MIDIPortRef()
        var op = MIDIPortRef()
        // Tear down whatever was created so far when a later step fails, so a
        // failed connect never leaks the client/ports.
        func cleanup() {
            if ip != 0 { MIDIPortDispose(ip) }
            if op != 0 { MIDIPortDispose(op) }
            if c != 0 { MIDIClientDispose(c) }
        }

        var st = MIDIClientCreateWithBlock("ElectraOne" as CFString, &c, nil)
        guard st == noErr else { throw E1Error.midi(st, "MIDIClientCreate") }

        st = MIDIInputPortCreateWithBlock(c, "ElectraOneIn" as CFString, &ip) { [weak self] listPtr, _ in
            self?.receive(listPtr)
        }
        guard st == noErr else { cleanup(); throw E1Error.midi(st, "MIDIInputPortCreate") }

        st = MIDIOutputPortCreate(c, "ElectraOneOut" as CFString, &op)
        guard st == noErr else { cleanup(); throw E1Error.midi(st, "MIDIOutputPortCreate") }

        guard let (src, srcName) = bestSource(), let (dst, dstName) = bestDest() else {
            cleanup(); throw E1Error.notFound
        }

        st = MIDIPortConnectSource(ip, src, nil)
        guard st == noErr else { cleanup(); throw E1Error.midi(st, "MIDIPortConnectSource") }

        let names = PortNames(input: srcName, output: dstName)
        lock.lock()
        client = c; inPort = ip; outPort = op
        source = src; dest = dst
        _portNames = names
        _connected = true
        lock.unlock()
        return names
    }

    public func disconnect() {
        if source != 0 { MIDIPortDisconnectSource(inPort, source) }
        if inPort != 0 { MIDIPortDispose(inPort) }
        if outPort != 0 { MIDIPortDispose(outPort) }
        if client != 0 { MIDIClientDispose(client) }
        lock.lock()
        inPort = 0; outPort = 0; client = 0; source = 0; dest = 0
        _connected = false
        buffer = []
        let fail = waiterFail
        waiter = nil; waiterFail = nil
        lock.unlock()
        // Fail any in-flight exchange immediately instead of leaving it to
        // time out.
        fail?(E1Error.notConnected)
    }

    // ── Receive + reassembly ────────────────────────────────────────────────

    private func receive(_ listPtr: UnsafePointer<MIDIPacketList>) {
        // `MIDIPacket.data` is declared as a 256-byte tuple, but CoreMIDI packs
        // longer packets contiguously past it — read via the packet pointer +
        // the field's offset so the full `length` bytes are captured.
        let dataOffset = MemoryLayout<MIDIPacket>.offset(of: \MIDIPacket.data)!
        for pkt in listPtr.unsafeSequence() {
            let len = Int(pkt.pointee.length)
            let bytes = [UInt8](UnsafeRawBufferPointer(
                start: UnsafeRawPointer(pkt) + dataOffset, count: len))
            feed(bytes)
        }
    }

    private func feed(_ raw: [UInt8]) {
        // MIDI realtime bytes (0xF8…0xFF) may be interleaved mid-SysEx —
        // drop them before reassembly.
        let bytes = raw.filter { $0 < 0xF8 }
        var deliver: ((E1Proto.Message) -> Void)?
        var message: E1Proto.Message?

        lock.lock()
        if bytes.first == E1Proto.sox {
            buffer = bytes
        } else if !buffer.isEmpty {
            buffer += bytes
        } else {
            lock.unlock()
            return
        }
        if buffer.last == E1Proto.eox {
            let complete = buffer
            buffer = []
            message = E1Proto.classify(complete)
            deliver = waiter
        }
        lock.unlock()

        if let d = deliver, let m = message { d(m) }
    }

    // ── Send ────────────────────────────────────────────────────────────────

    private func send(_ bytes: [UInt8]) throws {
        guard connected else { throw E1Error.notConnected }
        // Everything we exchange is SysEx; route it through MIDISendSysex,
        // which streams arbitrarily large messages in the background. A single
        // MIDIPacketList caps out at 64 KB (and its add can fail silently),
        // while presets/Lua can be several hundred KB.
        if bytes.first == E1Proto.sox {
            try sendSysex(bytes)
        } else {
            try sendPacketList(bytes)
        }
    }

    private func sendSysex(_ bytes: [UInt8]) throws {
        // The request struct and payload must outlive this call — CoreMIDI
        // sends asynchronously and frees nothing. The completion proc
        // deallocates both.
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: max(1, bytes.count))
        data.update(from: bytes, count: bytes.count)
        let request = UnsafeMutablePointer<MIDISysexSendRequest>.allocate(capacity: 1)
        request.initialize(to: MIDISysexSendRequest(
            destination: dest,
            data: data,
            bytesToSend: UInt32(bytes.count),
            complete: false,
            reserved: (0, 0, 0),
            completionProc: { req in
                UnsafeMutablePointer(mutating: req.pointee.data).deallocate()
                req.deallocate()
            },
            completionRefCon: nil))

        let st = MIDISendSysex(request)
        guard st == noErr else {
            data.deallocate()
            request.deallocate()
            throw E1Error.midi(st, "MIDISendSysex")
        }
    }

    private func sendPacketList(_ bytes: [UInt8]) throws {
        let listSize = bytes.count + 128
        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: listSize,
            alignment: MemoryLayout<MIDIPacketList>.alignment)
        defer { raw.deallocate() }
        let listPtr = raw.assumingMemoryBound(to: MIDIPacketList.self)

        let packet = MIDIPacketListInit(listPtr)
        let added: UnsafeMutablePointer<MIDIPacket>? = bytes.withUnsafeBufferPointer { buf in
            MIDIPacketListAdd(listPtr, listSize, packet, 0, bytes.count, buf.baseAddress!)
        }
        guard added != nil else { throw E1Error.midi(-1, "packet list overflow") }

        let st = MIDISend(outPort, dest, listPtr)
        guard st == noErr else { throw E1Error.midi(st, "MIDISend") }
    }

    // ── Exchanges ───────────────────────────────────────────────────────────
    //
    // The owning E1Device actor guarantees one exchange at a time, so a single
    // `waiter` slot is sufficient.

    /// Send a request and await the first `data` response. A NACK fails the
    /// exchange immediately (no point waiting for the timeout).
    public func query(_ bytes: [UInt8], timeout: TimeInterval = 6) async throws -> (resource: UInt8, payload: [UInt8]) {
        try await withCheckedThrowingContinuation { cont in
            let state = ResumeOnce()
            var timeoutItem: DispatchWorkItem?
            let finish: (Result<(resource: UInt8, payload: [UInt8]), Error>) -> Void = { result in
                guard state.tryResume() else { return }
                self.lock.lock(); self.waiter = nil; self.waiterFail = nil; self.lock.unlock()
                timeoutItem?.cancel()
                cont.resume(with: result)
            }
            lock.lock()
            waiter = { msg in
                switch msg {
                case let .data(resource, payload):
                    finish(.success((resource: resource, payload: payload)))
                case .nack:
                    finish(.failure(E1Error.nack))
                default:
                    break // ignore notifications; keep waiting
                }
            }
            waiterFail = { finish(.failure($0)) }
            lock.unlock()
            timeoutItem = scheduleTimeout(timeout) { finish(.failure(E1Error.timeout)) }
            do { try send(bytes) } catch { finish(.failure(error)) }
        }
    }

    /// Send a command and await ACK (resolve) or NACK (throw).
    public func command(_ bytes: [UInt8], timeout: TimeInterval = 6) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let state = ResumeOnce()
            var timeoutItem: DispatchWorkItem?
            let finish: (Result<Void, Error>) -> Void = { result in
                guard state.tryResume() else { return }
                self.lock.lock(); self.waiter = nil; self.waiterFail = nil; self.lock.unlock()
                timeoutItem?.cancel()
                cont.resume(with: result)
            }
            lock.lock()
            waiter = { msg in
                switch msg {
                case .ack:  finish(.success(()))
                case .nack: finish(.failure(E1Error.nack))
                default:    break // ignore notifications/data; keep waiting
                }
            }
            waiterFail = { finish(.failure($0)) }
            lock.unlock()
            timeoutItem = scheduleTimeout(timeout) { finish(.failure(E1Error.timeout)) }
            do { try send(bytes) } catch { finish(.failure(error)) }
        }
    }

    /// Schedule a cancellable timeout — `finish` cancels it so the closure
    /// doesn't linger after fast completions.
    private func scheduleTimeout(_ seconds: TimeInterval, _ fire: @escaping () -> Void) -> DispatchWorkItem {
        let item = DispatchWorkItem(block: fire)
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds, execute: item)
        return item
    }
}

/// One-shot guard so a continuation resumes exactly once.
private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    func tryResume() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}
