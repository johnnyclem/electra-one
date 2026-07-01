// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ElectraOne",
    platforms: [.macOS(.v13)],
    targets: [
        // Vendored Lua 5.4 interpreter (C).
        .target(
            name: "CLua",
            cSettings: [.define("LUA_USE_MACOSX")]
        ),
        // Swift wrapper around Lua: build/run scripts, capture output.
        .target(
            name: "LuaKit",
            dependencies: ["CLua"]
        ),
        // Shared core: MIDI transport, SysEx protocol, high-level device ops.
        .target(
            name: "ElectraKit"
        ),
        // The SwiftUI Mac app.
        .executableTarget(
            name: "ElectraOneApp",
            dependencies: ["ElectraKit", "LuaKit"]
        ),
        // Headless probe used to verify CoreMIDI talks to the hardware.
        .executableTarget(
            name: "e1probe",
            dependencies: ["ElectraKit", "LuaKit"]
        ),
        // Unit tests for the pure/offline layers (protocol, geometry, document
        // model, project import, Lua engine). No hardware required.
        .testTarget(
            name: "ElectraKitTests",
            dependencies: ["ElectraKit", "LuaKit"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
