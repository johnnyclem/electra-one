// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ElectraOne",
    platforms: [.macOS(.v13)],
    targets: [
        // Shared core: MIDI transport, SysEx protocol, high-level device ops.
        .target(
            name: "ElectraKit"
        ),
        // The SwiftUI Mac app.
        .executableTarget(
            name: "ElectraOneApp",
            dependencies: ["ElectraKit"]
        ),
        // Headless probe used to verify CoreMIDI talks to the hardware.
        .executableTarget(
            name: "e1probe",
            dependencies: ["ElectraKit"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
