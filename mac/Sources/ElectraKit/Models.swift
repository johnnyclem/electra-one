import Foundation

/// Hardware/firmware info returned by the device. Extra keys are ignored.
public struct DeviceInfo: Codable, Sendable {
    public var model: String?
    public var hwRevision: String?
    public var versionText: String?
    public var serial: String?

    public var modelUpper: String { (model ?? "?").uppercased() }
}

/// Lightweight summary of a preset, parsed for display without modelling the
/// full Electra schema.
public struct PresetSummary: Sendable {
    public var name: String
    public var version: Int?
    public var projectId: String?
    public var pages: Int
    public var controls: Int
    public var devices: Int
    public var deviceNames: [String]
}

public enum SlotStatus: String, Sendable {
    case unknown, scanning, ok, empty, error
}

public struct SlotState: Identifiable, Sendable, Equatable {
    public var slot: Int
    public var status: SlotStatus
    public var name: String?
    public var error: String?

    public var id: Int { slot }

    public init(slot: Int, status: SlotStatus, name: String? = nil, error: String? = nil) {
        self.slot = slot
        self.status = status
        self.name = name
        self.error = error
    }
}
