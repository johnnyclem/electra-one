import SwiftUI
import AppKit
import ElectraKit
import UniformTypeIdentifiers

// MARK: - Theme (from the UX design, hardware-inspired)

enum ElectraTheme {
    static let background = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let surface = Color(red: 0.16, green: 0.16, blue: 0.18)
    static let surfaceSecondary = Color(red: 0.22, green: 0.22, blue: 0.25)
    static let accent = Color(red: 0.96, green: 0.58, blue: 0.0) // Electra orange
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.45)
    static let bezel = Color(red: 0.15, green: 0.15, blue: 0.17)
    static let bezelHighlight = Color.white.opacity(0.08)

    static let titleFont = Font.system(size: 20, weight: .semibold)
    static let headlineFont = Font.system(size: 15, weight: .semibold)
    static let monoFont = Font.system(size: 11, weight: .regular, design: .monospaced)

    static let controlCornerRadius: CGFloat = 4
    static let bezelCornerRadius: CGFloat = 14
}

extension Color {
    init(electraHex hex: String) {
        var s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self = Color(red: Double((v >> 16) & 0xff) / 255,
                     green: Double((v >> 8) & 0xff) / 255,
                     blue: Double(v & 0xff) / 255)
    }
}

// MARK: - Root

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    @State private var zoom: Double = 1.0
    @State private var showGrid = true
    @State private var snapToGrid = false
    @State private var multiSelection: Set<Int> = []

    var body: some View {
        NavigationSplitView {
            Sidebar().navigationSplitViewColumnWidth(min: 240, ideal: 270)
        } detail: {
            Group {
                switch model.editorMode {
                case .script:
                    ScriptEditor()
                case .design:
                    if model.document == nil {
                        WelcomeView()
                    } else {
                        VStack(spacing: 0) {
                            EditorHeader()
                            Divider()
                            HStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    DeviceCanvas(zoom: $zoom, showGrid: $showGrid, snapToGrid: $snapToGrid, multiSelection: $multiSelection)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(ElectraTheme.background)
                                    BottomBar(zoom: $zoom, showGrid: $showGrid, snapToGrid: $snapToGrid)
                                }
                                Divider()
                                Inspector(multiSelection: $multiSelection).frame(width: 300)
                            }
                            Divider()
                            StatusBar()
                        }
                    }
                }
            }
            // Reflect external single-selection changes (e.g. Add Control) into
            // the canvas selection — without clobbering an active multi-select.
            .onChange(of: model.selectedControlId) { id in
                if let id {
                    let alreadyInMulti = multiSelection.count > 1 && multiSelection.contains(id)
                    if multiSelection != [id] && !alreadyInMulti { multiSelection = [id] }
                } else if multiSelection.count <= 1 {
                    multiSelection.removeAll()
                }
            }
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $model.savePickerPresented) { SaveToDeviceSheet() }
        .preferredColorScheme(.dark)
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { model.newDocument() } label: { Label("New", systemImage: "doc.badge.plus") }
            Button { model.openFile() } label: { Label("Open", systemImage: "folder") }
        }
        ToolbarItem(placement: .principal) {
            Picker("", selection: $model.editorMode) {
                Text("Design").tag(AppModel.EditorMode.design)
                Text("Script").tag(AppModel.EditorMode.script)
            }
            .pickerStyle(.segmented).frame(width: 170)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button { model.undo() } label: { Label("Undo", systemImage: "arrow.uturn.backward") }
                .disabled(!model.canUndo)
            Button { model.redo() } label: { Label("Redo", systemImage: "arrow.uturn.forward") }
                .disabled(!model.canRedo)

            Divider()

            Menu {
                ForEach(PresetDocument.ControlKind.allCases, id: \.self) { kind in
                    Button(kind.displayName) { model.addControl(kind: kind) }
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
            .menuIndicator(.visible)
            .disabled(model.document == nil)
            Button { model.saveToFile() } label: { Label("Save", systemImage: "square.and.arrow.down") }
                .disabled(model.document == nil)
            Button { model.presentSaveToDevice() } label: {
                Label("Push to Device", systemImage: "arrow.up.circle.fill")
            }
            .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
            .disabled(model.document == nil || !model.isConnected)
        }
    }
}

// MARK: - Sidebar

private struct Sidebar: View {
    @EnvironmentObject var model: AppModel
    @State private var slotToClear: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header.padding(12)
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
        .confirmationDialog(
            slotToClear.map { "Clear bank \(model.bank), slot \($0)?" } ?? "Clear slot?",
            isPresented: Binding(get: { slotToClear != nil }, set: { if !$0 { slotToClear = nil } }),
            titleVisibility: .visible,
            presenting: slotToClear
        ) { slot in
            Button("Clear Slot", role: .destructive) { model.clearSlot(slot); slotToClear = nil }
            Button("Cancel", role: .cancel) { slotToClear = nil }
        } message: { _ in
            Text("This permanently removes the preset and any Lua from this slot on the device. It can't be undone.")
        }
    }

    @ViewBuilder private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            switch model.connection {
            case .connecting:
                Label("Connecting…", systemImage: "bolt.horizontal.circle").font(ElectraTheme.headlineFont)
            case .offline:
                HStack {
                    Label("No device", systemImage: "cable.connector.slash")
                        .font(ElectraTheme.headlineFont).foregroundStyle(ElectraTheme.textSecondary)
                    Spacer()
                    Button("Retry") { model.reconnect() }.controlSize(.small)
                }
            case .ready:
                Text("Electra One \(model.info?.modelUpper ?? "")").font(ElectraTheme.headlineFont)
                Text("fw \(model.info?.versionText ?? "?")  ·  \(model.info?.serial ?? "")")
                    .font(ElectraTheme.monoFont).foregroundStyle(ElectraTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bankPicker: some View {
        HStack {
            Text("Bank").font(.caption).foregroundStyle(ElectraTheme.textSecondary)
            Picker("", selection: Binding(get: { model.bank }, set: { model.setBank($0) })) {
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
                        .contextMenu {
                            if slot.status == .ok {
                                Button("Open") { model.openFromSlot(slot.slot) }
                            }
                            if slot.status == .ok || slot.status == .error {
                                Button("Clear Slot on Device…", role: .destructive) { slotToClear = slot.slot }
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var offlineHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Editing offline").font(.subheadline.bold())
            Text("Create or open a preset to build it visually. Connect an Electra One to load and push presets.")
                .font(.caption).foregroundStyle(ElectraTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button { model.newDocument() } label: { Label("New", systemImage: "doc.badge.plus") }
                Button { model.openFile() } label: { Label("Open", systemImage: "folder") }
            }
            .controlSize(.small)
        }
        .padding(12)
    }
}

private struct SlotRow: View {
    let slot: SlotState
    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "%02d", slot.slot)).font(ElectraTheme.monoFont).foregroundStyle(ElectraTheme.textTertiary)
            switch slot.status {
            case .ok:       Text(slot.name ?? "(unnamed)")
            case .empty:    Text("—").foregroundStyle(ElectraTheme.textTertiary)
            case .scanning: Text("scanning…").italic().foregroundStyle(ElectraTheme.textSecondary)
            case .error:    Label("corrupt", systemImage: "exclamationmark.triangle").foregroundStyle(.orange).labelStyle(.titleAndIcon)
            case .unknown:  Text("·").foregroundStyle(ElectraTheme.textTertiary)
            }
            Spacer()
        }
        .padding(.vertical, 1)
    }
}

// MARK: - Header + page tabs

private struct EditorHeader: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Preset name", text: Binding(get: { model.document?.name ?? "" }, set: { model.setPresetName($0) }))
                .textFieldStyle(.plain).font(ElectraTheme.titleFont)
            if !model.subtitle.isEmpty {
                Text(model.subtitle).font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            }
            PageTabs()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(ElectraTheme.surface)
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
                            .background(on ? ElectraTheme.accent.opacity(0.22) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Device canvas (bezel + screen)

private struct DeviceCanvas: View {
    @EnvironmentObject var model: AppModel
    @Binding var zoom: Double
    @Binding var showGrid: Bool
    @Binding var snapToGrid: Bool
    @Binding var multiSelection: Set<Int>

    // Live group-drag (lifted from the controls so the whole selection moves).
    @State private var dragIDs: Set<Int> = []
    @State private var dragOffset: CGSize = .zero
    // Marquee selection.
    @State private var marqueeStart: CGPoint?
    @State private var marqueeRect: CGRect?

    private let screenW = PresetDocument.screenWidth
    private let screenH = PresetDocument.screenHeight

    var body: some View {
        GeometryReader { geo in
            let pad: CGFloat = 80
            let fit = min((geo.size.width - pad) / screenW, (geo.size.height - pad) / screenH)
            let scale = max(0.05, fit * zoom)

            ScrollView([.horizontal, .vertical]) {
                bezel(scale: scale)
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
            .overlay(alignment: .top) {
                if multiSelection.count > 1 {
                    AlignmentToolbar(selectedIDs: multiSelection) { multiSelection.removeAll() }
                        .padding(.top, 10)
                }
            }
        }
    }

    private func bezel(scale: Double) -> some View {
        let sw = screenW * scale, sh = screenH * scale
        return VStack(spacing: 6) {
            portLabels
            screen(scale: scale)
                .frame(width: sw, height: sh)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: ElectraTheme.bezelCornerRadius).fill(ElectraTheme.bezel)
                .overlay(RoundedRectangle(cornerRadius: ElectraTheme.bezelCornerRadius).stroke(ElectraTheme.bezelHighlight, lineWidth: 1))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }

    private var portLabels: some View {
        let isMini = (model.info?.model ?? "").lowercased().contains("mini")
        let labels = isMini
            ? ["USB DEVICE", "USB HOST", "MIDI 1 OUT", "MIDI 1 IN"]
            : ["USB DEVICE", "USB HOST", "MIDI 1 OUT", "MIDI 2 OUT", "MIDI 1 IN", "MIDI 2 IN"]
        return HStack(spacing: 0) {
            ForEach(labels, id: \.self) { l in
                Text(l).font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(ElectraTheme.textTertiary).frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }

    private func screen(scale: Double) -> some View {
        ZStack(alignment: .topLeading) {
            Color.black
                .contentShape(Rectangle())
                .onTapGesture { model.selectedControlId = nil; multiSelection.removeAll() }
                .gesture(marqueeGesture(scale: scale))

            if showGrid { SlotGridOverlay(scale: scale) }
            ControlSetBands(scale: scale)

            ForEach(model.currentControls) { control in
                RichControl(
                    control: control,
                    scale: scale,
                    selected: multiSelection.contains(control.id),
                    liveOffset: dragIDs.contains(control.id) ? dragOffset : .zero,
                    onSelect: { select(control.id) },
                    onDragChanged: { t in
                        if dragIDs.isEmpty { dragIDs = group(for: control.id) }
                        dragOffset = t
                    },
                    onDragEnded: { t in
                        let ids = dragIDs.isEmpty ? [control.id] : Array(dragIDs)
                        model.moveControls(ids, dx: Double(t.width) / scale, dy: Double(t.height) / scale, snap: snapToGrid)
                        dragIDs = []; dragOffset = .zero
                    })
            }

            if let r = marqueeRect {
                Rectangle().fill(ElectraTheme.accent.opacity(0.12))
                    .overlay(Rectangle().stroke(ElectraTheme.accent, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                    .frame(width: r.width, height: r.height)
                    .position(x: r.midX, y: r.midY)
                    .allowsHitTesting(false)
            }

            if model.currentControls.isEmpty {
                Text("No controls on this page.\nUse Add to place one.")
                    .multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.4))
                    .frame(width: screenW * scale, height: screenH * scale)
            }
        }
    }

    private func marqueeGesture(scale: Double) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in
                let start = marqueeStart ?? v.startLocation
                marqueeStart = start
                marqueeRect = CGRect(x: min(start.x, v.location.x), y: min(start.y, v.location.y),
                                     width: abs(v.location.x - start.x), height: abs(v.location.y - start.y))
            }
            .onEnded { _ in
                if let r = marqueeRect {
                    let model_ = CGRect(x: r.minX / scale, y: r.minY / scale, width: r.width / scale, height: r.height / scale)
                    let hits = model.currentControls.filter {
                        model_.intersects(CGRect(x: $0.x, y: $0.y, width: $0.w, height: $0.h))
                    }.map(\.id)
                    multiSelection = Set(hits)
                    model.selectedControlId = hits.count == 1 ? hits.first : nil
                }
                marqueeStart = nil; marqueeRect = nil
            }
    }

    private func group(for id: Int) -> Set<Int> {
        (multiSelection.count > 1 && multiSelection.contains(id)) ? multiSelection : [id]
    }

    private func select(_ id: Int) {
        if NSEvent.modifierFlags.contains(.command) {
            if multiSelection.contains(id) { multiSelection.remove(id) } else { multiSelection.insert(id) }
            model.selectedControlId = multiSelection.count == 1 ? multiSelection.first : nil
        } else {
            multiSelection = [id]
            model.selectedControlId = id
        }
    }
}

private struct SlotGridOverlay: View {
    let scale: Double
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(1...SlotGeometry.slotsPerPage, id: \.self) { slot in
                let b = SlotGeometry.bounds(forSlot: slot)
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    .frame(width: b.w * scale, height: b.h * scale)
                    .position(x: (b.x + b.w / 2) * scale, y: (b.y + b.h / 2) * scale)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ControlSetBands: View {
    let scale: Double
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach([2, 4], id: \.self) { row in
                let y = (SlotGeometry.originY + Double(row) * SlotGeometry.pitchY) * scale
                Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: SlotGeometry.canvasWidth * scale, y: y))
                }
                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                Text("CS \(row / 2 + 1)").font(.system(size: max(7, 9 * scale * 1.4)))
                    .foregroundStyle(.white.opacity(0.22)).position(x: 18, y: y + 9)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Control

private struct RichControl: View {
    let control: PresetDocument.Control
    let scale: Double
    let selected: Bool
    let liveOffset: CGSize          // applied to the whole selection during a group drag
    let onSelect: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void

    private var color: Color { Color(electraHex: control.colorHex) }
    private var w: CGFloat { control.w * scale }
    private var h: CGFloat { control.h * scale }

    var body: some View {
        cell
            .frame(width: w, height: h)
            .position(x: (control.x + control.w / 2) * scale + liveOffset.width,
                      y: (control.y + control.h / 2) * scale + liveOffset.height)
            // Tap + drag coexist cleanly via simultaneousGesture.
            .simultaneousGesture(TapGesture().onEnded { onSelect() })
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { onDragChanged($0.translation) }
                    .onEnded { onDragEnded($0.translation) }
            )
    }

    @ViewBuilder private var cell: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ElectraTheme.controlCornerRadius)
                .fill(color.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: ElectraTheme.controlCornerRadius)
                    .stroke(color.opacity(0.7), lineWidth: 1))
            VStack(spacing: 2) {
                Text(control.name.isEmpty ? control.type.uppercased() : control.name)
                    .font(.system(size: max(7, 11 * scale * 1.6), weight: .semibold))
                    .foregroundStyle(color).lineLimit(1).padding(.top, 3)
                graphic
                Spacer(minLength: 0)
            }
            .padding(3)
        }
        .overlay(RoundedRectangle(cornerRadius: ElectraTheme.controlCornerRadius)
            .stroke(selected ? Color.white : .clear, lineWidth: 2))
    }

    @ViewBuilder private var graphic: some View {
        switch control.kind {
        case .pad:
            RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 1))
                .frame(maxWidth: .infinity).frame(height: max(8, h * 0.4))
        case .list:
            RoundedRectangle(cornerRadius: 2).stroke(color.opacity(0.7))
                .overlay(Text("▾").font(.system(size: max(7, 9 * scale * 1.4))).foregroundStyle(color))
                .frame(height: max(8, h * 0.35))
        case .vfader:
            HStack {
                Spacer()
                GeometryReader { g in
                    ZStack(alignment: .bottom) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(color).frame(height: g.size.height * fillFraction)
                    }
                }
                .frame(width: max(4, 6 * scale * 1.4))
                Spacer()
            }
        case .knob:
            KnobShape(color: color, fraction: fillFraction)
                .padding(.vertical, 2)
        case .adsr:
            ADSRShape(color: color).padding(.horizontal, 2).padding(.bottom, 2)
        case .fader:
            VStack(spacing: 2) {
                Spacer(minLength: 0)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(color).frame(width: g.size.width * fillFraction)
                    }
                }
                .frame(height: max(4, 6 * scale * 1.4))
                Text(valueLabel).font(.system(size: max(6, 8 * scale * 1.4), design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var fillFraction: CGFloat { 0.6 } // representative (no live value offline)

    private var valueLabel: String {
        if let p = control.parameterNumber, let t = control.messageType { return "\(t) \(p)" }
        return control.messageType ?? ""
    }
}

/// Rotary knob: a track arc, a value arc, and a pointer (270° sweep).
private struct KnobShape: View {
    let color: Color
    let fraction: CGFloat
    private let start = Angle(degrees: 135)
    private let sweep = 270.0

    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height)
            let lw = max(1.5, side * 0.12)
            ZStack {
                Circle().trim(from: 0, to: 0.75)
                    .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: lw, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle().trim(from: 0, to: 0.75 * fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: lw, lineCap: .round))
                    .rotationEffect(.degrees(135))
                // pointer
                Path { p in
                    p.move(to: CGPoint(x: side / 2, y: side / 2))
                    let a = (start.degrees + sweep * Double(fraction)) * .pi / 180
                    p.addLine(to: CGPoint(x: side / 2 + cos(a) * side * 0.32,
                                          y: side / 2 + sin(a) * side * 0.32))
                }
                .stroke(color, style: StrokeStyle(lineWidth: max(1, lw * 0.6), lineCap: .round))
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Classic ADSR envelope outline (attack ramp, decay to sustain, hold,
/// release) drawn across the control's body.
private struct ADSRShape: View {
    let color: Color
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let attackX = w * 0.18, decayX = w * 0.38, sustainEndX = w * 0.7
            let sustainY = h * 0.45
            Path { p in
                p.move(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: attackX, y: 0))            // attack
                p.addLine(to: CGPoint(x: decayX, y: sustainY))       // decay
                p.addLine(to: CGPoint(x: sustainEndX, y: sustainY))  // sustain
                p.addLine(to: CGPoint(x: w, y: h))                   // release
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h))
                    p.addLine(to: CGPoint(x: attackX, y: 0))
                    p.addLine(to: CGPoint(x: decayX, y: sustainY))
                    p.addLine(to: CGPoint(x: sustainEndX, y: sustainY))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(color.opacity(0.15))
            )
        }
    }
}

// MARK: - Alignment toolbar (multi-select)

private struct AlignmentToolbar: View {
    @EnvironmentObject var model: AppModel
    let selectedIDs: Set<Int>
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text("\(selectedIDs.count) selected").font(.caption).foregroundStyle(ElectraTheme.textSecondary).padding(.horizontal, 4)
            Divider().frame(height: 14)
            btn("align.horizontal.left") { align(.left) }
            btn("align.horizontal.center") { align(.centerH) }
            btn("align.horizontal.right") { align(.right) }
            Divider().frame(height: 14)
            btn("align.vertical.top") { align(.top) }
            btn("align.vertical.center") { align(.centerV) }
            btn("align.vertical.bottom") { align(.bottom) }
            Divider().frame(height: 14)
            btn("arrow.left.and.right") { model.distributeControls(Array(selectedIDs), axis: .horizontal) }
                .disabled(selectedIDs.count < 3).help("Distribute horizontally")
            btn("arrow.up.and.down") { model.distributeControls(Array(selectedIDs), axis: .vertical) }
                .disabled(selectedIDs.count < 3).help("Distribute vertically")
            Divider().frame(height: 14)
            btn("plus.square.on.square") { model.duplicateControls(Array(selectedIDs)) }.help("Duplicate")
            Button(role: .destructive) { model.deleteControls(Array(selectedIDs)); onClear() } label: {
                Image(systemName: "trash")
            }.buttonStyle(.borderless)
            Button("Clear") { onClear() }.buttonStyle(.bordered).controlSize(.small)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(.ultraThinMaterial).clipShape(Capsule()).shadow(radius: 6)
    }

    private func btn(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon) }.buttonStyle(.borderless)
    }

    private func align(_ edge: AppModel.AlignEdge) { model.alignControls(Array(selectedIDs), to: edge) }
}

// MARK: - Inspector (full)

private struct Inspector: View {
    @EnvironmentObject var model: AppModel
    @Binding var multiSelection: Set<Int>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if multiSelection.count > 1 {
                    multiInspector
                } else if let c = model.selectedControl {
                    controlInspector(c)
                } else {
                    presetInspector
                }
            }
            .padding(14)
        }
        .background(ElectraTheme.surface)
    }

    private var multiInspector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(multiSelection.count) CONTROLS").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
            Text("Use the alignment bar above the canvas, drag to move them together, or delete.")
                .font(.caption).foregroundStyle(ElectraTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive) { model.deleteControls(Array(multiSelection)); multiSelection.removeAll() } label: {
                Label("Delete \(multiSelection.count)", systemImage: "trash")
            }
        }
    }

    @ViewBuilder private var presetInspector: some View {
        Text("PRESET").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
        labeled("Name") {
            TextField("Name", text: Binding(get: { model.document?.name ?? "" }, set: { model.setPresetName($0) }))
                .textFieldStyle(.roundedBorder)
        }
        if let page = (model.document?.pages.first { $0.id == model.currentPageId }) {
            labeled("Current page") {
                TextField("Page name", text: Binding(get: { page.name }, set: { model.renamePage(page.id, $0) }))
                    .textFieldStyle(.roundedBorder)
            }
        }
        if let lua = model.luaInfo {
            Label(lua, systemImage: "curlybraces.square").font(.caption).foregroundStyle(.purple)
        }
        Divider()
        Text("\(model.currentControls.count) control(s) on this page").font(.caption).foregroundStyle(ElectraTheme.textSecondary)
        Text("Select a control to edit it, ⌘-click to multi-select, drag to move. Add places a new one.")
            .font(.caption).foregroundStyle(ElectraTheme.textTertiary).fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func controlInspector(_ c: PresetDocument.Control) -> some View {
        HStack {
            Text("CONTROL").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
            Spacer()
            Button { model.duplicateControls([c.id]) } label: { Image(systemName: "plus.square.on.square") }.buttonStyle(.borderless)
            Button(role: .destructive) { model.deleteSelectedControl() } label: { Image(systemName: "trash") }.buttonStyle(.borderless)
        }
        labeled("Name") {
            TextField("Name", text: Binding(get: { c.name }, set: { model.setControlName(c.id, $0) })).textFieldStyle(.roundedBorder)
        }
        labeled("Kind") {
            Picker("", selection: Binding(get: { c.kind }, set: { model.setControlKind(c.id, $0) })) {
                ForEach(PresetDocument.ControlKind.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }.labelsHidden()
        }
        labeled("Color") {
            HStack(spacing: 6) {
                ForEach(PresetDocument.palette, id: \.self) { hex in
                    Circle().fill(Color(electraHex: hex)).frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.primary.opacity(c.colorHex.caseInsensitiveCompare(hex) == .orderedSame ? 0.9 : 0.15), lineWidth: 2))
                        .onTapGesture { model.setControlColor(c.id, hex: hex) }
                }
            }
        }
        Divider()
        Text("MIDI").font(.subheadline.bold())
        if c.kind == .adsr {
            ForEach(model.document?.controlValues(id: c.id) ?? [], id: \.valueId) { v in
                labeled("\(v.valueId.capitalized) CC") {
                    TextField("", value: Binding(
                        get: { v.parameterNumber ?? 0 },
                        set: { model.setValueParameterNumber(c.id, valueId: v.valueId, $0) }), format: .number)
                        .textFieldStyle(.roundedBorder)
                }
            }
        } else {
            labeled("Message") {
                Picker("", selection: Binding(get: { c.messageType ?? "cc7" }, set: { model.setControlMessageType(c.id, $0) })) {
                    ForEach(["cc7", "cc14", "nrpn", "rpn", "note", "program", "start", "stop"], id: \.self) { Text($0).tag($0) }
                }.labelsHidden()
            }
            labeled("Parameter #") {
                TextField("", value: Binding(get: { c.parameterNumber ?? 0 }, set: { model.setControlParameterNumber(c.id, $0) }), format: .number)
                    .textFieldStyle(.roundedBorder)
            }
        }
        Divider()
        Text("POSITION").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
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
            Text(title).font(.caption).foregroundStyle(ElectraTheme.textSecondary)
            content()
        }
    }

    private func numField(_ label: String, _ value: Double, _ set: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            TextField("", value: Binding(get: { Int(value) }, set: { set(Double($0)) }), format: .number).textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Bottom bar (grid + zoom)

private struct BottomBar: View {
    @EnvironmentObject var model: AppModel
    @Binding var zoom: Double
    @Binding var showGrid: Bool
    @Binding var snapToGrid: Bool

    var body: some View {
        HStack(spacing: 8) {
            Toggle(isOn: $showGrid) { Label("Grid", systemImage: "grid") }.toggleStyle(.button).controlSize(.small)
            Toggle(isOn: $snapToGrid) { Label("Snap", systemImage: "square.grid.2x2") }.toggleStyle(.button).controlSize(.small)
            Spacer()
            HStack(spacing: 8) {
                Button { zoom = max(0.5, zoom - 0.1) } label: { Image(systemName: "minus.magnifyingglass") }.buttonStyle(.borderless)
                Slider(value: $zoom, in: 0.5...2.0).frame(width: 120)
                Button { zoom = min(2.0, zoom + 0.1) } label: { Image(systemName: "plus.magnifyingglass") }.buttonStyle(.borderless)
                Text("\(Int(zoom * 100))%").font(ElectraTheme.monoFont).frame(width: 40, alignment: .trailing)
                Button("Fit") { zoom = 1.0 }.controlSize(.small)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(ElectraTheme.surface)
    }
}

// MARK: - Status bar

private struct StatusBar: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        HStack(spacing: 8) {
            if model.busy { ProgressView().controlSize(.small) }
            Text(model.message.isEmpty ? " " : model.message)
                .font(.callout).lineLimit(1)
                .foregroundStyle(model.message.hasPrefix("Error") ? .red : ElectraTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(ElectraTheme.surface)
    }
}

// MARK: - Lua script editor

private struct ScriptEditor: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            VSplitView {
                LuaCodeView(text: Binding(get: { model.luaSource }, set: { model.setLuaSource($0) }))
                    .frame(minHeight: 180)
                ConsolePane(text: model.luaConsole) { model.clearConsole() }
                    .frame(minHeight: 120)
            }
        }
        .background(ElectraTheme.background)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button { model.luaBuild() } label: { Label("Build", systemImage: "hammer") }
            Button { model.luaRun() } label: { Label("Run", systemImage: "play.fill") }
                .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
            Divider().frame(height: 16)
            Button { model.importLua() } label: { Label("Import…", systemImage: "square.and.arrow.down") }
            Button { model.exportLua() } label: { Label("Export…", systemImage: "square.and.arrow.up") }
            Button { model.presentSaveToDevice() } label: { Label("Push to Device", systemImage: "arrow.up.circle") }
                .disabled(model.document == nil || !model.isConnected)
            Spacer()
            if let doc = model.document {
                Text("attached to “\(doc.name.isEmpty ? "preset" : doc.name)”")
                    .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            } else {
                Text("scratch — open or create a preset to push to device")
                    .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(ElectraTheme.surface)
    }
}

private struct ConsolePane: View {
    let text: String
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("CONSOLE").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
                Spacer()
                Button { onClear() } label: { Label("Clear", systemImage: "trash") }
                    .buttonStyle(.borderless).controlSize(.small)
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    Text(text.isEmpty ? "— output appears here —" : text)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(text.isEmpty ? ElectraTheme.textTertiary : .white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(10)
                    Color.clear.frame(height: 1).id("bottom")
                }
                .onChange(of: text) { _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
            }
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }
}

// MARK: - Welcome + Save sheet

private struct WelcomeView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "slider.horizontal.2.square").font(.system(size: 54)).foregroundStyle(ElectraTheme.textTertiary)
            Text("Electra One Preset Editor").font(.title2.bold())
            Text(model.isConnected
                 ? "Pick a preset slot on the left to edit it, or start a new one."
                 : "Build a preset offline, or connect an Electra One to load one.")
                .foregroundStyle(ElectraTheme.textSecondary).multilineTextAlignment(.center)
            HStack {
                Button { model.newDocument() } label: { Label("New Preset", systemImage: "doc.badge.plus") }
                    .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
                Button { model.openFile() } label: { Label("Open File…", systemImage: "folder") }
            }
        }
        .padding(50).frame(maxWidth: .infinity, maxHeight: .infinity).background(ElectraTheme.background)
    }
}

private struct SaveToDeviceSheet: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Push to Device").font(.headline)
            Text("Upload “\(model.documentTitle)” to a slot. This overwrites whatever is there.")
                .font(.callout).foregroundStyle(ElectraTheme.textSecondary)
            HStack(spacing: 20) {
                Stepper("Bank \(model.saveBank)", value: $model.saveBank, in: 0...(model.bankCount - 1))
                Stepper("Slot \(model.saveSlot)", value: $model.saveSlot, in: 0...(model.slotsPerBank - 1))
            }
            HStack {
                Spacer()
                Button("Cancel") { model.savePickerPresented = false }.keyboardShortcut(.cancelAction)
                Button("Upload") { model.confirmSaveToDevice() }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
            }
        }
        .padding(20).frame(width: 380)
    }
}
