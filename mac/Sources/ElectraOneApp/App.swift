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
            CommandGroup(replacing: .newItem) {
                Button("New Preset") { model.newDocument() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Open…") { model.openFile() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { model.saveToFile() }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(model.document == nil)
                Button("Save As…") { model.saveToFileAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(model.document == nil)
                Button("Save to Device…") { model.presentSaveToDevice() }
                    .keyboardShortcut("d", modifiers: .command)
                    .disabled(model.document == nil || !model.isConnected)
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { model.undo() }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(!model.canUndo)
                Button("Redo") { model.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!model.canRedo)
            }
            CommandGroup(after: .toolbar) {
                Button("Rescan Bank") { model.rescan() }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(!model.isConnected)
                Button("Add Control") { model.addControl() }
                    .keyboardShortcut("k", modifiers: .command)
                    .disabled(model.document == nil)
            }
        }
    }
}
