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
                    .keyboardShortcut("u", modifiers: .command)
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
                Button("Duplicate Control") {
                    if let id = model.selectedControlId { model.duplicateControls([id]) }
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(model.selectedControlId == nil)
            }
            CommandGroup(after: .sidebar) {
                Button("Design Mode") { model.editorMode = .design }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Script Mode") { model.editorMode = .script }
                    .keyboardShortcut("2", modifiers: .command)
            }
            CommandMenu("Script") {
                Button("Build") { model.luaBuild() }
                    .keyboardShortcut("b", modifiers: .command)
                    .disabled(model.editorMode != .script)
                Button("Run") { model.luaRun() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(model.editorMode != .script)
                Divider()
                Button("Script Library…") { model.editorMode = .script; model.libraryPresented = true }
                    .keyboardShortcut("l", modifiers: [.command, .shift])
                Button("Save to Library") { model.saveCurrentToLibrary() }
                    .keyboardShortcut("s", modifiers: [.command, .option])
                    .disabled(!model.canSaveToLibrary)
                Divider()
                Button("Import Lua…") { model.importLua() }
                Button("Export Lua…") { model.exportLua() }
            }
        }
    }
}
