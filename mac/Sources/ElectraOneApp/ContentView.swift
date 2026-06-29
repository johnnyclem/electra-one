import SwiftUI
import ElectraKit
import UniformTypeIdentifiers

// ── Color helpers ──────────────────────────────────────────────────────────────

extension Color {
    init(electraHex hex: String) {
        var s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self = Color(
            red: Double((v >> 16) & 0xff) / 255,
            green: Double((v >> 8) & 0xff) / 255,
            blue: Double(v & 0xff) / 255)
    }
}

// ── Root ───────────────────────────────────────────────────────────────────────

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            Sidebar().navigationSplitViewColumnWidth(min: 240, ideal: 270)
        } detail: {
            EditorPane()
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $model.savePickerPresented) { SaveToDeviceSheet() }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { model.newDocument() } label: { Label("New", systemImage: "doc.badge.plus") }
            Button { model.openFile() } label: { Label("Open", systemImage: "folder") }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button { model.addControl() } label: { Label("Add Control", systemImage: "plus.app") }
                .disabled(model.document == nil)
            Button { model.saveToFile() } label: { Label("Save File", systemImage: "square.and.arrow.down") }
                .disabled(model.document == nil)
            Button { model.presentSaveToDevice() } label: { Label("Save to Device", systemImage: "arrow.up.circle") }
                .disabled(model.document == nil || !model.isConnected)
        }
    }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────────

private struct Sidebar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            deviceHeader
            Divider()
            if model.isConnected {
                bankPicker
                Divider()
                slotList
            } else {
                offlineHint
                Spacer()
            }
        }
    }

    @ViewBuilder private var deviceHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            switch model.connection {
            case .connecting:
                Label("Connecting…", systemImage: "bolt.horizontal.circle").font(.headline)
            case .offline:
                HStack {
                    Label("No device", systemImage: "cable.connector.slash")
                        .font(.headline).foregroundStyle(.secondary)
                    Spacer()
                    Button("Retry") { model.reconnect() }.controlSize(.small)
                }
            case .ready:
                Text("Electra One \(model.info?.modelUpper ?? "")").font(.headline)
                Text("fw \(model.info?.versionText ?? "?")  ·  \(model.info?.serial ?? "")")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    private var offlineHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Editing offline").font(.subheadline.bold())
            Text("Create or open a preset to build it visually. Connect an Electra One to load and save presets on the device.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button { model.newDocument() } label: { Label("New", systemImage: "doc.badge.plus") }
                Button { model.openFile() } label: { Label("Open", systemImage: "folder") }
            }
            .controlSize(.small)
        }
        .padding(12)
    }

    private var bankPicker: some View {
        HStack {
            Text("Bank").font(.subheadline.bold())
            Picker("Bank", selection: Binding(get: { model.bank }, set: { model.setBank($0) })) {
                ForEach(0..<model.bankCount, id: \.self) { Text("\($0)").tag($0) }
            }
            .labelsHidden().pickerStyle(.segmented)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var slotList: some View {
        List(selection: Binding(get: { model.openSlot }, set: { if let s = $0 { model.openFromSlot(s) } })) {
            Section("Presets") {
                ForEach(model.slots) { slot in
                    SlotRow(slot: slot).tag(slot.slot)
                }
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
                .font(.system(.body, design: .monospaced)).foregroundStyle(.secondary)
            switch slot.status {
            case .ok:       Text(slot.name ?? "(unnamed)")
            case .empty:    Text("—").foregroundStyle(.tertiary)
            case .scanning: Text("scanning…").italic().foregroundStyle(.secondary)
            case .error:    Label("corrupt", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange).labelStyle(.titleAndIcon)
            case .unknown:  Text("·").foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.vertical, 1)
    }
}

// ── Editor pane ───────────────────────────────────────────────────────────────────

private struct EditorPane: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        if model.document == nil {
            WelcomeView()
        } else {
            VStack(spacing: 0) {
                EditorHeader()
                Divider()
                HStack(spacing: 0) {
                    PresetCanvas()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: .underPageBackgroundColor))
                    Divider()
                    Inspector().frame(width: 290)
                }
                Divider()
                StatusBar()
            }
        }
    }
}

private struct WelcomeView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "slider.horizontal.2.square").font(.system(size: 54)).foregroundStyle(.secondary)
            Text("Electra One Preset Editor").font(.title2.bold())
            Text(model.isConnected
                 ? "Pick a preset slot on the left to edit it, or start a new one."
                 : "Build a preset offline, or connect an Electra One to load one.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            HStack {
                Button { model.newDocument() } label: { Label("New Preset", systemImage: "doc.badge.plus") }
                    .buttonStyle(.borderedProminent)
                Button { model.openFile() } label: { Label("Open File…", systemImage: "folder") }
            }
        }
        .padding(50).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EditorHeader: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Preset name", text: Binding(
                    get: { model.document?.name ?? "" },
                    set: { model.setPresetName($0) }))
                    .textFieldStyle(.plain).font(.title.bold())
                Spacer()
            }
            if !model.subtitle.isEmpty {
                Text(model.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            PageTabs()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

private struct PageTabs: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(model.document?.pages ?? []) { page in
                    let on = page.id == model.currentPageId
                    Button {
                        model.currentPageId = page.id
                        model.selectedControlId = nil
                    } label: {
                        Text(page.name)
                            .font(.callout.weight(on ? .semibold : .regular))
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(on ? Color.accentColor.opacity(0.18) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// ── The Electra "screen" ─────────────────────────────────────────────────────────

private struct PresetCanvas: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / PresetDocument.screenWidth,
                            geo.size.height / PresetDocument.screenHeight)
            let cw = PresetDocument.screenWidth * scale
            let ch = PresetDocument.screenHeight * scale
            ZStack {
                Color.clear
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color.black)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.08)))
                        .onTapGesture { model.selectedControlId = nil }
                    ForEach(model.currentControls) { control in
                        ControlCell(
                            control: control,
                            scale: scale,
                            selected: model.selectedControlId == control.id,
                            onSelect: { model.selectedControlId = control.id },
                            onMove: { dx, dy in
                                let nx = max(0, min(PresetDocument.screenWidth - control.w, control.x + dx))
                                let ny = max(0, min(PresetDocument.screenHeight - control.h, control.y + dy))
                                model.setControlBounds(control.id, x: nx, y: ny, w: control.w, h: control.h)
                            })
                    }
                    if model.currentControls.isEmpty {
                        Text("No controls on this page.\nUse “Add Control” to place one.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: cw, height: ch)
                    }
                }
                .frame(width: cw, height: ch)
                .clipped()
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(16)
    }
}

private struct ControlCell: View {
    let control: PresetDocument.Control
    let scale: Double
    let selected: Bool
    let onSelect: () -> Void
    let onMove: (Double, Double) -> Void

    @State private var drag: CGSize = .zero

    private var color: Color { Color(electraHex: control.colorHex) }
    private var w: CGFloat { control.w * scale }
    private var h: CGFloat { control.h * scale }

    var body: some View {
        cell
            .frame(width: w, height: h)
            .position(x: (control.x + control.w / 2) * scale + drag.width,
                      y: (control.y + control.h / 2) * scale + drag.height)
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { drag = $0.translation }
                    .onEnded { v in onMove(Double(v.translation.width) / scale, Double(v.translation.height) / scale); drag = .zero }
            )
            .onTapGesture { onSelect() }
    }

    @ViewBuilder private var cell: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(selected ? Color.white : color.opacity(0.5),
                                lineWidth: selected ? 2 : 1))
            VStack(spacing: 2) {
                Text(control.name.isEmpty ? control.type : control.name)
                    .font(.system(size: max(7, 11 * scale * 1.6), weight: .semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .padding(.top, 3)
                graphic
                Spacer(minLength: 0)
            }
            .padding(3)
        }
    }

    @ViewBuilder private var graphic: some View {
        switch control.type {
        case "pad":
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 1))
                .frame(maxWidth: .infinity)
                .frame(height: max(8, h * 0.4))
        case "list":
            RoundedRectangle(cornerRadius: 2)
                .stroke(color.opacity(0.7))
                .overlay(Text("▾").font(.system(size: max(7, 9 * scale * 1.4))).foregroundStyle(color))
                .frame(height: max(8, h * 0.35))
        default: // fader / dial / others
            VStack(spacing: 2) {
                Spacer(minLength: 0)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(color).frame(width: g.size.width * fillFraction)
                    }
                }
                .frame(height: max(4, 6 * scale * 1.4))
                Text(valueLabel)
                    .font(.system(size: max(6, 8 * scale * 1.4), design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var fillFraction: CGFloat {
        let lo = Double(control.minValue ?? 0)
        let hi = Double(control.maxValue ?? 127)
        guard hi > lo else { return 0.5 }
        return 0.6 // representative; we don't track live values offline
    }

    private var valueLabel: String {
        if let p = control.parameterNumber, let t = control.messageType {
            return "\(t) \(p)"
        }
        return control.messageType ?? ""
    }
}

// ── Inspector ─────────────────────────────────────────────────────────────────────

private struct Inspector: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let c = model.selectedControl {
                    controlInspector(c)
                } else {
                    presetInspector
                }
            }
            .padding(14)
        }
    }

    @ViewBuilder private var presetInspector: some View {
        Text("Preset").font(.headline)
        labeled("Name") {
            TextField("Name", text: Binding(get: { model.document?.name ?? "" }, set: { model.setPresetName($0) }))
        }
        if let page = (model.document?.pages.first { $0.id == model.currentPageId }) {
            labeled("Current page") {
                TextField("Page name", text: Binding(get: { page.name }, set: { model.renamePage(page.id, $0) }))
            }
        }
        if let lua = model.luaInfo {
            Label(lua, systemImage: "curlybraces.square")
                .font(.caption).foregroundStyle(.purple)
        }
        Divider()
        Text("\(model.currentControls.count) control(s) on this page")
            .font(.caption).foregroundStyle(.secondary)
        Text("Select a control to edit it, or “Add Control” to place a new one. Drag controls to reposition.")
            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func controlInspector(_ c: PresetDocument.Control) -> some View {
        HStack {
            Text("Control").font(.headline)
            Spacer()
            Button(role: .destructive) { model.deleteSelectedControl() } label: {
                Image(systemName: "trash")
            }.buttonStyle(.borderless)
        }
        labeled("Name") {
            TextField("Name", text: Binding(get: { c.name }, set: { model.setControlName(c.id, $0) }))
        }
        labeled("Type") {
            Picker("", selection: Binding(get: { c.type }, set: { model.setControlType(c.id, $0) })) {
                ForEach(["fader", "pad", "list"], id: \.self) { Text($0.capitalized).tag($0) }
            }.labelsHidden()
        }
        labeled("Color") {
            HStack(spacing: 6) {
                ForEach(PresetDocument.palette, id: \.self) { hex in
                    Circle().fill(Color(electraHex: hex))
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.primary.opacity(c.colorHex.caseInsensitiveCompare(hex) == .orderedSame ? 0.9 : 0.15), lineWidth: 2))
                        .onTapGesture { model.setControlColor(c.id, hex: hex) }
                }
            }
        }
        Divider()
        Text("MIDI").font(.subheadline.bold())
        labeled("Message") {
            Picker("", selection: Binding(get: { c.messageType ?? "cc7" }, set: { model.setControlMessageType(c.id, $0) })) {
                ForEach(["cc7", "cc14", "nrpn", "rpn", "note", "program", "start", "stop"], id: \.self) { Text($0).tag($0) }
            }.labelsHidden()
        }
        labeled("Parameter #") {
            TextField("", value: Binding(
                get: { c.parameterNumber ?? 0 },
                set: { model.setControlParameterNumber(c.id, $0) }), format: .number)
        }
        Divider()
        Text("Position").font(.subheadline.bold())
        HStack {
            numField("X", c.x) { model.setControlBounds(c.id, x: $0, y: c.y, w: c.w, h: c.h) }
            numField("Y", c.y) { model.setControlBounds(c.id, x: c.x, y: $0, w: c.w, h: c.h) }
        }
        HStack {
            numField("W", c.w) { model.setControlBounds(c.id, x: c.x, y: c.y, w: $0, h: c.h) }
            numField("H", c.h) { model.setControlBounds(c.id, x: c.x, y: c.y, w: c.w, h: $0) }
        }
    }

    private func labeled<V: View>(_ title: String, @ViewBuilder _ content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }

    private func numField(_ label: String, _ value: Double, _ set: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField("", value: Binding(get: { Int(value) }, set: { set(Double($0)) }), format: .number)
        }
    }
}

// ── Status bar + sheets ────────────────────────────────────────────────────────────

private struct StatusBar: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        HStack(spacing: 8) {
            if model.busy { ProgressView().controlSize(.small) }
            Text(model.message.isEmpty ? " " : model.message)
                .font(.callout).lineLimit(1)
                .foregroundStyle(model.message.hasPrefix("Error") ? .red : .secondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }
}

private struct SaveToDeviceSheet: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save to Device").font(.headline)
            Text("Upload “\(model.documentTitle)” to a slot. This overwrites whatever is there.")
                .font(.callout).foregroundStyle(.secondary)
            HStack(spacing: 20) {
                Stepper("Bank \(model.saveBank)", value: $model.saveBank, in: 0...(model.bankCount - 1))
                Stepper("Slot \(model.saveSlot)", value: $model.saveSlot, in: 0...(model.slotsPerBank - 1))
            }
            HStack {
                Spacer()
                Button("Cancel") { model.savePickerPresented = false }.keyboardShortcut(.cancelAction)
                Button("Upload") { model.confirmSaveToDevice() }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            }
        }
        .padding(20).frame(width: 380)
    }
}
