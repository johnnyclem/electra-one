import SwiftUI
import ElectraKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            Sidebar()
                .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        } detail: {
            DetailPane()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { model.rescan() } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(model.connection != .ready || model.busy)
            }
        }
        .sheet(isPresented: $model.editorPresented) { EditorSheet() }
    }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

private struct Sidebar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            bankPicker
            Divider()
            slotList
        }
    }

    @ViewBuilder private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch model.connection {
            case .connecting:
                Label("Connecting…", systemImage: "bolt.horizontal.circle")
                    .font(.headline)
            case .failed:
                Label("Not connected", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline).foregroundStyle(.red)
            case .ready:
                Text("Electra One \(model.info?.modelUpper ?? "")")
                    .font(.headline)
                Text("fw \(model.info?.versionText ?? "?")  ·  \(model.info?.serial ?? "")")
                    .font(.caption).foregroundStyle(.secondary)
                Text(model.portName)
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    private var bankPicker: some View {
        HStack {
            Text("Bank").font(.subheadline.bold())
            Picker("Bank", selection: Binding(get: { model.bank }, set: { model.setBank($0) })) {
                ForEach(0..<model.bankCount, id: \.self) { Text("\($0)").tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .disabled(model.connection != .ready)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var slotList: some View {
        List(selection: Binding(get: { model.selected }, set: { if let s = $0 { model.select(s) } })) {
            ForEach(model.slots) { slot in
                SlotRow(slot: slot).tag(slot.slot)
            }
        }
        .listStyle(.sidebar)
    }
}

private struct SlotRow: View {
    let slot: SlotState

    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "%02d", slot.slot))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            label
            Spacer()
        }
        .padding(.vertical, 1)
    }

    @ViewBuilder private var label: some View {
        switch slot.status {
        case .ok:
            Text(slot.name ?? "(unnamed)")
        case .empty:
            Text("—").foregroundStyle(.tertiary)
        case .scanning:
            Text("scanning…").foregroundStyle(.secondary).italic()
        case .error:
            Label("corrupt", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange).labelStyle(.titleAndIcon)
        case .unknown:
            Text("·").foregroundStyle(.tertiary)
        }
    }
}

// ── Detail pane ────────────────────────────────────────────────────────────────

private struct DetailPane: View {
    @EnvironmentObject var model: AppModel
    @State private var importing = false

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            statusBar
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result, let slot = model.selected {
                let needsAccess = url.startAccessingSecurityScopedResource()
                model.upload(file: url, to: slot)
                if needsAccess { url.stopAccessingSecurityScopedResource() }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch model.connection {
        case .connecting:
            ProgressView("Connecting to Electra One…")
        case .failed(let why):
            VStack(spacing: 10) {
                Image(systemName: "cable.connector.slash").font(.largeTitle).foregroundStyle(.red)
                Text("Could not connect").font(.title3.bold())
                Text(why).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Try Again") { model.start() }
            }
            .padding(40)
        case .ready:
            readyContent
        }
    }

    @ViewBuilder private var readyContent: some View {
        if model.selected == nil {
            ContentUnavailable("Select a preset", systemImage: "square.grid.2x2",
                               description: "Pick a slot on the left to view it.")
        } else if model.detailLoading {
            ProgressView("Loading preset…")
        } else if model.detailEmpty {
            ContentUnavailable("Empty slot", systemImage: "square.dashed",
                               description: "Slot \(model.selected ?? 0) has no preset. You can upload one here.")
                .overlay(alignment: .bottom) { uploadOnlyBar.padding() }
        } else if let s = model.summary {
            presetDetail(s)
        } else {
            ContentUnavailable("Unreadable preset", systemImage: "exclamationmark.triangle",
                               description: "This slot's data could not be parsed. You can still edit the raw JSON.")
                .overlay(alignment: .bottom) { actionBar.padding() }
        }
    }

    private func presetDetail(_ s: PresetSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(s.name).font(.largeTitle.bold())
                Text("slot \(model.selected ?? 0) · v\(s.version.map(String.init) ?? "?")\(s.projectId.map { " · \($0)" } ?? "")")
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 24) {
                stat("Pages", s.pages)
                stat("Controls", s.controls)
                stat("Devices", s.devices)
            }
            if !s.deviceNames.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Devices").font(.headline)
                    ForEach(Array(s.deviceNames.prefix(8).enumerated()), id: \.offset) { _, n in
                        Text("• \(n)").foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            actionBar
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading) {
            Text("\(value)").font(.title2.monospacedDigit().bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button { if let s = model.selected { model.beginEdit(s) } } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button { if let s = model.selected { model.download(s) } } label: {
                Label("Download", systemImage: "square.and.arrow.down")
            }
            Button { importing = true } label: {
                Label("Upload…", systemImage: "square.and.arrow.up")
            }
            Button { if let s = model.selected { model.activate(s) } } label: {
                Label("Activate", systemImage: "play.circle")
            }
            Spacer()
        }
        .disabled(model.busy)
    }

    private var uploadOnlyBar: some View {
        Button { importing = true } label: {
            Label("Upload a preset…", systemImage: "square.and.arrow.up")
        }
        .disabled(model.busy)
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            if model.busy { ProgressView().controlSize(.small) }
            Text(model.message.isEmpty ? " " : model.message)
                .font(.callout)
                .foregroundStyle(model.message.hasPrefix("Error") ? .red : .secondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }
}

// ── Editor sheet ─────────────────────────────────────────────────────────────

private struct EditorSheet: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit preset — slot \(model.editorSlot ?? 0)").font(.headline)
                Spacer()
            }
            .padding(12)
            Divider()
            TextEditor(text: $model.editorText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 560, minHeight: 420)
            if let err = model.editorError {
                Text(err).foregroundStyle(.red).font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.top, 6)
            }
            Divider()
            HStack {
                Text("Saving uploads the JSON to the slot on your device.")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { model.editorPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("Save to Device") { model.saveEdit() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding(12)
        }
    }
}

// ── Back-compat ContentUnavailableView (macOS 13) ──────────────────────────────

private struct ContentUnavailable: View {
    let title: String
    let systemImage: String
    let description: String
    init(_ title: String, systemImage: String, description: String) {
        self.title = title; self.systemImage = systemImage; self.description = description
    }
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage).font(.system(size: 40)).foregroundStyle(.secondary)
            Text(title).font(.title3.bold())
            Text(description).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
