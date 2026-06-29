import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct ElectraOneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Electra One") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 500)
                .onAppear { model.start() }
        }
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Rescan Bank") { model.rescan() }
                    .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
