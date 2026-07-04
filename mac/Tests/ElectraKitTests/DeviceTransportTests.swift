import Testing
import Foundation
@testable import ElectraKit

/// A scripted in-memory transport so `E1Device` can be exercised without
/// CoreMIDI or hardware. Query payloads are consumed front-first; running out
/// simulates a device that stopped answering (timeout).
final class MockTransport: E1TransportProtocol, @unchecked Sendable {
    var connected = false
    var queryPayloads: [[UInt8]] = []
    var sent: [[UInt8]] = []

    @discardableResult
    func connect() throws -> PortNames {
        connected = true
        return PortNames(input: "Mock In", output: "Mock Out")
    }

    func disconnect() { connected = false }

    func query(_ bytes: [UInt8], timeout: TimeInterval) async throws -> (resource: UInt8, payload: [UInt8]) {
        sent.append(bytes)
        guard !queryPayloads.isEmpty else { throw E1Error.timeout }
        let resource = bytes.count > 5 ? bytes[5] : 0
        return (resource: resource, payload: queryPayloads.removeFirst())
    }

    func command(_ bytes: [UInt8], timeout: TimeInterval) async throws {
        sent.append(bytes)
    }
}

@Suite struct DeviceTransportTests {

    @Test func connectAndDisconnectHappyPath() async throws {
        let transport = MockTransport()
        let device = E1Device(transport: transport)
        let ports = try await device.connect()
        #expect(ports.input == "Mock In")
        #expect(ports.output == "Mock Out")
        #expect(await device.isConnected)
        await device.disconnect()
        #expect(!(await device.isConnected))
    }

    @Test func getInfoDecodesDeviceInfo() async throws {
        let transport = MockTransport()
        let json = #"{"model":"mk2","versionText":"4.0.0","serial":"E1-123"}"#
        transport.queryPayloads = [Array(json.utf8)]
        let device = E1Device(transport: transport)
        let info = try await device.getInfo()
        #expect(info.model == "mk2")
        #expect(info.versionText == "4.0.0")
        #expect(info.serial == "E1-123")
        #expect(info.modelUpper == "MK2")
        // The request on the wire was an info request.
        #expect(transport.sent.first == E1Proto.infoRequest())
    }

    @Test func getPresetRawThrowsEmptyForEmptySlot() async {
        let transport = MockTransport()
        transport.queryPayloads = [[]]
        let device = E1Device(transport: transport)
        do {
            _ = try await device.getPresetRaw(bank: 0, slot: 0)
            Issue.record("expected E1Error.empty")
        } catch E1Error.empty {
            // expected
        } catch {
            Issue.record("expected E1Error.empty, got \(error)")
        }
    }

    @Test func getLuaThrowsEmptyForEmptySlot() async {
        let transport = MockTransport()
        transport.queryPayloads = [[]]
        let device = E1Device(transport: transport)
        do {
            _ = try await device.getLua(bank: 0, slot: 0)
            Issue.record("expected E1Error.empty")
        } catch E1Error.empty {
            // expected
        } catch {
            Issue.record("expected E1Error.empty, got \(error)")
        }
    }

    @Test func getLuaThrowsDecodeForNonUTF8Payload() async {
        let transport = MockTransport()
        transport.queryPayloads = [[0xFF, 0xFE, 0xFD]]   // not valid UTF-8
        let device = E1Device(transport: transport)
        do {
            _ = try await device.getLua(bank: 0, slot: 0)
            Issue.record("expected E1Error.decode")
        } catch E1Error.decode {
            // expected
        } catch {
            Issue.record("expected E1Error.decode, got \(error)")
        }
    }

    @Test func getLuaReturnsScriptText() async throws {
        let transport = MockTransport()
        transport.queryPayloads = [Array("print(1)".utf8)]
        let device = E1Device(transport: transport)
        let lua = try await device.getLua(bank: 0, slot: 0)
        #expect(lua == "print(1)")
    }

    @Test func scanSlotClassifiesOkEmptyErrorAndTimeout() async {
        let transport = MockTransport()
        transport.queryPayloads = [
            Array(#"{"name":"Bass","pages":[{"id":1}],"controls":[]}"#.utf8),  // ok
            [],                                                                // empty
            Array("not json".utf8),                                            // error
        ]
        let device = E1Device(transport: transport)

        let ok = await device.scanSlot(bank: 0, slot: 0)
        #expect(ok.status == .ok)
        #expect(ok.name == "Bass")

        let empty = await device.scanSlot(bank: 0, slot: 1)
        #expect(empty.status == .empty)

        let bad = await device.scanSlot(bank: 0, slot: 2)
        #expect(bad.status == .error)
        #expect(bad.error != nil)

        // Payloads exhausted → the mock times out → scanned as empty.
        let timedOut = await device.scanSlot(bank: 0, slot: 3)
        #expect(timedOut.status == .empty)
    }
}
