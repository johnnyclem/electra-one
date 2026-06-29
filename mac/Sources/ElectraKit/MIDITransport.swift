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
}

/// CoreMIDI transport for the Electra One.
///
/// Mirrors lib/transport.js: one persistent client/port pair, SysEx exchanges
/// serialized by the owning `E1Device` actor, fragmented responses reassembled
/// until EOX. Large uploads are sent in a single packet list (CoreMIDI splits
/// them on the wire); the device reassembles.
public final class MIDITransport: @unchecked Sendable {
    private var client = MIDIClientRef()
    private var inPort = MIDIPortRef()
    private var outPort = MIDIPortRef()
    private var source = MIDIEndpointRef()
    private var dest = MIDIEndpointRef()

    public private(set) var connected = false
    public private(set) var portNames: PortNames?

    private let lock = NSLock()
    private var buffer: [UInt8] = []
    private var waiter: ((E1Proto.Message) -> Void)?

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
        var st = MIDIClientCreateWithBlock("ElectraOne" as CFString, &c, nil)
        guard st == noErr else { throw E1Error.midi(st, "MIDIClientCreate") }
        client = c

        var ip = MIDIPortRef()
        st = MIDIInputPortCreateWithBlock(client, "ElectraOneIn" as CFString, &ip) { [weak self] listPtr, _ in
            self?.receive(listPtr)
        }
        guard st == noErr else { throw E1Error.midi(st, "MIDIInputPortCreate") }
        inPort = ip

        var op = MIDIPortRef()
        st = MIDIOutputPortCreate(client, "ElectraOneOut" as CFString, &op)
        guard st == noErr else { throw E1Error.midi(st, "MIDIOutputPortCreate") }
        outPort = op

        guard let (src, srcName) = bestSource(), let (dst, dstName) = bestDest() else {
            throw E1Error.notFound
        }
        source = src
        dest = dst

        st = MIDIPortConnectSource(inPort, source, nil)
        guard st == noErr else { throw E1Error.midi(st, "MIDIPortConnectSource") }

        let names = PortNames(input: srcName, output: dstName)
        portNames = names
        connected = true
        return names
    }

    public func disconnect() {
        if source != 0 { MIDIPortDisconnectSource(inPort, source) }
        if inPort != 0 { MIDIPortDispose(inPort) }
        if outPort != 0 { MIDIPortDispose(outPort) }
        if client != 0 { MIDIClientDispose(client) }
        inPort = 0; outPort = 0; client = 0; source = 0; dest = 0
        connected = false
        lock.lock(); buffer = []; waiter = nil; lock.unlock()
    }

    // ── Receive + reassembly ────────────────────────────────────────────────

    private func receive(_ listPtr: UnsafePointer<MIDIPacketList>) {
        for pkt in listPtr.unsafeSequence() {
            let len = Int(pkt.pointee.length)
            let bytes = withUnsafeBytes(of: pkt.pointee.data) { Array($0.prefix(len)) }
            feed(bytes)
        }
    }

    private func feed(_ bytes: [UInt8]) {
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

    /// Send a request and await the first `data` response.
    public func query(_ bytes: [UInt8], timeout: TimeInterval = 6) async throws -> (resource: UInt8, payload: [UInt8]) {
        try await withCheckedThrowingContinuation { cont in
            let state = ResumeOnce()
            let finish: (Result<(resource: UInt8, payload: [UInt8]), Error>) -> Void = { result in
                guard state.tryResume() else { return }
                self.lock.lock(); self.waiter = nil; self.lock.unlock()
                cont.resume(with: result)
            }
            lock.lock()
            waiter = { msg in
                if case let .data(resource, payload) = msg {
                    finish(.success((resource: resource, payload: payload)))
                }
            }
            lock.unlock()
            scheduleTimeout(timeout) { finish(.failure(E1Error.timeout)) }
            do { try send(bytes) } catch { finish(.failure(error)) }
        }
    }

    /// Send a command and await ACK (resolve) or NACK (throw).
    public func command(_ bytes: [UInt8], timeout: TimeInterval = 6) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let state = ResumeOnce()
            let finish: (Result<Void, Error>) -> Void = { result in
                guard state.tryResume() else { return }
                self.lock.lock(); self.waiter = nil; self.lock.unlock()
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
            lock.unlock()
            scheduleTimeout(timeout) { finish(.failure(E1Error.timeout)) }
            do { try send(bytes) } catch { finish(.failure(error)) }
        }
    }

    private func scheduleTimeout(_ seconds: TimeInterval, _ fire: @escaping () -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds, execute: fire)
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
