import SwiftUI
import ElectraKit

// MARK: - Save to device

struct SaveToDeviceSheet: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save to Device").font(ElectraTheme.headlineFont)
            Text("Upload the open preset (and Lua) to a bank/slot on the Electra One.")
                .font(.callout).foregroundStyle(ElectraTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                labeled("Bank") {
                    Picker("", selection: $model.saveBank) {
                        ForEach(0..<model.bankCount, id: \.self) { Text("\($0)").tag($0) }
                    }.labelsHidden()
                }
                labeled("Slot") {
                    Picker("", selection: $model.saveSlot) {
                        ForEach(0..<model.slotsPerBank, id: \.self) { Text("\($0)").tag($0) }
                    }.labelsHidden()
                }
            }

            Toggle(isOn: $model.activateAfterSave) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activate after save")
                    Text("Switch the Mini to this slot so it becomes the live preset.")
                        .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
                }
            }
            .toggleStyle(.switch)

            HStack {
                Spacer()
                Button("Cancel") { model.savePickerPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("Upload") { model.confirmSaveToDevice() }
                    .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(ElectraTheme.background)
    }

    private func labeled<V: View>(_ title: String, @ViewBuilder _ content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(ElectraTheme.textSecondary)
            content()
        }
    }
}

// MARK: - Raw JSON panel

struct RawJSONPanel: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("RAW JSON").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
                Spacer()
                Button("Refresh") { model.refreshRawJSON() }.controlSize(.small)
                Button("Apply") { model.applyRawJSON() }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
                Button { model.showRawJSON = false } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
            }
            .padding(10)
            if let err = model.rawJSONError {
                Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal, 10)
            }
            TextEditor(text: $model.rawJSONText)
                .font(ElectraTheme.monoFont)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.black.opacity(0.35))
            Text("Apply replaces the preset object (Lua script is kept). Connectors and unknown keys round-trip.")
                .font(.caption2).foregroundStyle(ElectraTheme.textTertiary)
                .padding(10)
        }
        .frame(minWidth: 320, idealWidth: 380)
        .background(ElectraTheme.surface)
        .onAppear { model.refreshRawJSON() }
        .onChange(of: model.dirty) { _ in
            if model.showRawJSON { model.refreshRawJSON() }
        }
    }
}

// MARK: - MIDI log sheet

struct MidiLogSheet: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("MIDI activity", systemImage: "cable.connector")
                    .font(ElectraTheme.headlineFont)
                Spacer()
                Button("Clear") { model.clearMidiLog() }
                Button("Close") { model.midiLogPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            Text("Logs app ↔ device CTRL SysEx exchanges (load/save/scan). Analog MIDI IO to pedals is not mirrored here.")
                .font(.caption).foregroundStyle(ElectraTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if model.midiLogLines.isEmpty {
                        Text("No activity yet. Open a slot or save to device.")
                            .foregroundStyle(ElectraTheme.textTertiary)
                            .padding()
                    } else {
                        ForEach(Array(model.midiLogLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(ElectraTheme.monoFont)
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 560, height: 400)
        .background(ElectraTheme.background)
    }
}
