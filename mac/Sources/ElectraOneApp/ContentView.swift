import SwiftUI
import AppKit
import ElectraKit
import LuaKit
import UniformTypeIdentifiers

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
                                Inspector(multiSelection: $multiSelection).frame(width: 320)
                                if model.showRawJSON {
                                    Divider()
                                    RawJSONPanel()
                                }
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
        .sheet(isPresented: $model.simulatorPresented) { SimulatorSheet() }
        .sheet(isPresented: $model.midiLogPresented) { MidiLogSheet() }
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

            Toggle(isOn: $model.showMiniGuide) {
                Label("Mini guide", systemImage: "rectangle.dashed")
            }
            .toggleStyle(.button)
            .help("Show Electra Mini layout guide (480×320)")

            Toggle(isOn: Binding(
                get: { model.showRawJSON },
                set: { on in
                    model.showRawJSON = on
                    if on { model.refreshRawJSON() }
                }
            )) {
                Label("JSON", systemImage: "curlybraces")
            }
            .toggleStyle(.button)
            .disabled(model.document == nil)
            .help("Raw JSON side panel")

            Button { model.midiLogPresented = true } label: {
                Label("MIDI log", systemImage: "wave.3.right")
            }
            .help("CTRL-port activity log")

            Divider()

            Menu {
                ForEach(PresetDocument.ControlKind.allCases, id: \.self) { kind in
                    Button(kind.displayName) { model.addControl(kind: kind) }
                }
                Divider()
                Menu("Script") {
                    Button("From Lua Editor")      { model.addScriptControl(from: .editor) }
                    Button("Paste from Clipboard") { model.addScriptControl(from: .clipboard) }
                    Button("Import File…")         { model.addScriptControl(from: .file) }
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
            .disabled(!model.canPushToDevice)
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
    // Connector drawing: drag from an edge handle rubber-bands an arrow.
    @State private var hoveredControlId: Int?
    @State private var connectFromId: Int?
    @State private var connectPoint: CGPoint?

    /// Named coordinate space of the screen ZStack, so handle drags report
    /// locations in canvas coordinates rather than their own tiny frames.
    static let canvasSpace = "e1screen"

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
                .onTapGesture { model.selectedControlId = nil; model.selectedConnectorId = nil; multiSelection.removeAll() }
                .gesture(marqueeGesture(scale: scale))

            if showGrid { SlotGridOverlay(scale: scale) }
            ControlSetBands(scale: scale)
            if model.showMiniGuide {
                MiniGuideOverlay(scale: scale)
            }

            // Arrows sit under the controls so they never block control drags;
            // taps in the gaps between nodes still select them.
            ConnectorLayer(scale: scale, dragIDs: dragIDs, dragOffset: dragOffset) { id in
                multiSelection.removeAll()
                model.selectedControlId = nil
                model.selectedConnectorId = id
            }

            ForEach(model.currentControls) { control in
                RichControl(
                    control: control,
                    scale: scale,
                    selected: multiSelection.contains(control.id),
                    liveOffset: dragIDs.contains(control.id) ? dragOffset : .zero,
                    onSelect: { select(control.id) },
                    onRun: { model.runScriptControl(id: control.id) },
                    onHover: { inside in
                        if inside { hoveredControlId = control.id }
                        else if hoveredControlId == control.id { hoveredControlId = nil }
                    },
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

            // Edge handles on the hovered/selected control. While a connect
            // drag is live, key the handles to its source so the gesture's view
            // survives hover changes (removing it would cancel the drag).
            if dragIDs.isEmpty,
               let id = connectFromId ?? handleControlId,
               let c = model.currentControls.first(where: { $0.id == id }) {
                AnchorHandles(
                    rect: scaledRect(c, scale: scale),
                    onHover: { if $0 { hoveredControlId = id } },
                    onDragChanged: { p in connectFromId = id; connectPoint = p },
                    onDragEnded: { p in endConnect(at: p, scale: scale) })
            }

            connectRubberBand(scale: scale)

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
        .coordinateSpace(name: Self.canvasSpace)
    }

    /// Which control shows connector handles: the hovered one, else a single
    /// canvas selection.
    private var handleControlId: Int? {
        hoveredControlId ?? (multiSelection.count == 1 ? multiSelection.first : nil)
    }

    private func scaledRect(_ c: PresetDocument.Control, scale: Double) -> CGRect {
        let off = dragIDs.contains(c.id) ? dragOffset : .zero
        return CGRect(x: c.x * scale + off.width, y: c.y * scale + off.height,
                      width: c.w * scale, height: c.h * scale)
    }

    private func controlAt(_ p: CGPoint, scale: Double, excluding: Int) -> Int? {
        model.currentControls.first {
            $0.id != excluding && scaledRect($0, scale: scale).contains(p)
        }?.id
    }

    /// The live arrow while dragging from a handle, plus a highlight on the
    /// control it would land on.
    @ViewBuilder private func connectRubberBand(scale: Double) -> some View {
        if let fromId = connectFromId, let p = connectPoint,
           let src = model.currentControls.first(where: { $0.id == fromId }) {
            let fromRect = scaledRect(src, scale: scale)
            let (a, dirA) = ConnectorMath.anchor(on: fromRect, toward: p)
            let d = hypot(p.x - a.x, p.y - a.y)
            let dirB = d < 1 ? CGVector(dx: -dirA.dx, dy: -dirA.dy)
                             : CGVector(dx: (a.x - p.x) / d, dy: (a.y - p.y) / d)
            ConnectorMath.path(from: a, dirA: dirA, to: p, dirB: dirB)
                .stroke(ElectraTheme.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 4]))
                .allowsHitTesting(false)
            if let targetId = controlAt(p, scale: scale, excluding: fromId),
               let t = model.currentControls.first(where: { $0.id == targetId }) {
                let r = scaledRect(t, scale: scale)
                RoundedRectangle(cornerRadius: ElectraTheme.controlCornerRadius)
                    .stroke(ElectraTheme.accent, lineWidth: 2)
                    .frame(width: r.width, height: r.height)
                    .position(x: r.midX, y: r.midY)
                    .allowsHitTesting(false)
            }
        }
    }

    private func endConnect(at p: CGPoint, scale: Double) {
        defer { connectFromId = nil; connectPoint = nil }
        guard let from = connectFromId,
              let target = controlAt(p, scale: scale, excluding: from) else { return }
        model.addConnector(from: from, to: .control(target))
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
                    model.selectedConnectorId = nil
                }
                marqueeStart = nil; marqueeRect = nil
            }
    }

    private func group(for id: Int) -> Set<Int> {
        (multiSelection.count > 1 && multiSelection.contains(id)) ? multiSelection : [id]
    }

    private func select(_ id: Int) {
        model.selectedConnectorId = nil
        if NSEvent.modifierFlags.contains(.command) {
            if multiSelection.contains(id) { multiSelection.remove(id) } else { multiSelection.insert(id) }
            model.selectedControlId = multiSelection.count == 1 ? multiSelection.first : nil
        } else {
            multiSelection = [id]
            model.selectedControlId = id
        }
    }
}

/// Soft 480×320 guide for Electra Mini layout comfort (not a hard clip).
private struct MiniGuideOverlay: View {
    let scale: Double
    var body: some View {
        let w = SlotGeometry.miniGuideWidth * scale
        let h = SlotGeometry.miniGuideHeight * scale
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .foregroundStyle(Color.cyan.opacity(0.55))
                .frame(width: w, height: h)
            Text("Mini \(Int(SlotGeometry.miniGuideWidth))×\(Int(SlotGeometry.miniGuideHeight))")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.cyan.opacity(0.75))
                .padding(4)
                .offset(y: h + 2)
        }
        .frame(width: w, height: h + 16, alignment: .topLeading)
        .allowsHitTesting(false)
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

// MARK: - Connectors (board arrows)

/// Shared curve/arrow geometry for connector rendering. All coordinates are in
/// the scaled canvas space (`DeviceCanvas.canvasSpace`).
enum ConnectorMath {
    /// The point on `rect`'s edge facing `toward`, plus the outward normal of
    /// that edge — horizontal edges win when the target is mostly sideways.
    static func anchor(on rect: CGRect, toward p: CGPoint) -> (point: CGPoint, dir: CGVector) {
        let dx = p.x - rect.midX, dy = p.y - rect.midY
        if abs(dx) >= abs(dy) {
            return dx >= 0
                ? (CGPoint(x: rect.maxX, y: rect.midY), CGVector(dx: 1, dy: 0))
                : (CGPoint(x: rect.minX, y: rect.midY), CGVector(dx: -1, dy: 0))
        } else {
            return dy >= 0
                ? (CGPoint(x: rect.midX, y: rect.maxY), CGVector(dx: 0, dy: 1))
                : (CGPoint(x: rect.midX, y: rect.minY), CGVector(dx: 0, dy: -1))
        }
    }

    /// How far the curve's control points extend along each node's exit normal.
    private static func lead(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dist = hypot(b.x - a.x, b.y - a.y)
        return min(90, max(24, dist * 0.4))
    }

    /// A cubic curve leaving `a` along `dirA` and arriving at `b` against `dirB`
    /// (both are outward edge normals) — the classic diagramming S-curve.
    static func path(from a: CGPoint, dirA: CGVector, to b: CGPoint, dirB: CGVector) -> Path {
        let l = lead(a, b)
        var p = Path()
        p.move(to: a)
        p.addCurve(to: b,
                   control1: CGPoint(x: a.x + dirA.dx * l, y: a.y + dirA.dy * l),
                   control2: CGPoint(x: b.x + dirB.dx * l, y: b.y + dirB.dy * l))
        return p
    }

    /// Filled triangle arrowhead landing at `tip`; `outward` is the target
    /// edge's outward normal (the arrow flies in against it).
    static func arrowhead(at tip: CGPoint, outward: CGVector, size: CGFloat = 9) -> Path {
        let perp = CGVector(dx: -outward.dy, dy: outward.dx)
        var p = Path()
        p.move(to: tip)
        p.addLine(to: CGPoint(x: tip.x + outward.dx * size + perp.dx * size * 0.55,
                              y: tip.y + outward.dy * size + perp.dy * size * 0.55))
        p.addLine(to: CGPoint(x: tip.x + outward.dx * size - perp.dx * size * 0.55,
                              y: tip.y + outward.dy * size - perp.dy * size * 0.55))
        p.closeSubpath()
        return p
    }

    /// The cubic's point at t = 0.5, where the label sits.
    static func midpoint(from a: CGPoint, dirA: CGVector, to b: CGPoint, dirB: CGVector) -> CGPoint {
        let l = lead(a, b)
        let c1 = CGPoint(x: a.x + dirA.dx * l, y: a.y + dirA.dy * l)
        let c2 = CGPoint(x: b.x + dirB.dx * l, y: b.y + dirB.dy * l)
        return CGPoint(x: (a.x + 3 * c1.x + 3 * c2.x + b.x) / 8,
                       y: (a.y + 3 * c1.y + 3 * c2.y + b.y) / 8)
    }
}

/// All connector arrows on the current page. Control→control arrows run node to
/// node; control→page arrows land on a floating page pill that navigates when
/// clicked. Arrows track live drags so they follow controls being moved.
private struct ConnectorLayer: View {
    @EnvironmentObject var model: AppModel
    let scale: Double
    let dragIDs: Set<Int>
    let dragOffset: CGSize
    let onSelect: (Int) -> Void

    var body: some View {
        let rects = Dictionary(model.currentControls.map { ($0.id, rect(for: $0)) },
                               uniquingKeysWith: { first, _ in first })
        ZStack(alignment: .topLeading) {
            ForEach(model.currentConnectors) { conn in
                arrow(conn, rects: rects)
            }
        }
    }

    @ViewBuilder private func arrow(_ conn: PresetDocument.Connector, rects: [Int: CGRect]) -> some View {
        if let from = rects[conn.fromControlId] {
            switch conn.target {
            case .control(let t):
                if let to = rects[t] {
                    ConnectorArrow(connector: conn, fromRect: from, toRect: to, pillName: nil,
                                   selected: model.selectedConnectorId == conn.id,
                                   onSelect: { onSelect(conn.id) }, onFollow: {})
                }
            case .page(let pid):
                let name = model.document?.pages.first { $0.id == pid }?.name ?? "Page \(pid)"
                ConnectorArrow(connector: conn, fromRect: from,
                               toRect: pillRect(from: from, name: name), pillName: name,
                               selected: model.selectedConnectorId == conn.id,
                               onSelect: { onSelect(conn.id) },
                               onFollow: { model.followConnector(conn) })
            }
        }
    }

    private func rect(for c: PresetDocument.Control) -> CGRect {
        let off = dragIDs.contains(c.id) ? dragOffset : .zero
        return CGRect(x: c.x * scale + off.width, y: c.y * scale + off.height,
                      width: c.w * scale, height: c.h * scale)
    }

    /// A page pill floats beside its source control — to the right when there's
    /// room, else to the left — and stays inside the canvas vertically.
    private func pillRect(from: CGRect, name: String) -> CGRect {
        let w = min(160, max(64, 34 + CGFloat(name.count) * 7))
        let h: CGFloat = 24
        let gap: CGFloat = 56
        var x = from.maxX + gap
        if x + w > SlotGeometry.canvasWidth * scale - 8 { x = from.minX - gap - w }
        let y = min(max(4, from.midY - h / 2), SlotGeometry.canvasHeight * scale - h - 4)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

/// One connector: curve + arrowhead, optional midpoint label, optional page
/// pill at the target end. Only the stroke (widened) and the pill hit-test.
private struct ConnectorArrow: View {
    let connector: PresetDocument.Connector
    let fromRect: CGRect
    let toRect: CGRect
    let pillName: String?
    let selected: Bool
    let onSelect: () -> Void
    let onFollow: () -> Void

    var body: some View {
        let (a, dirA) = ConnectorMath.anchor(on: fromRect, toward: CGPoint(x: toRect.midX, y: toRect.midY))
        let (b, dirB) = ConnectorMath.anchor(on: toRect, toward: CGPoint(x: fromRect.midX, y: fromRect.midY))
        let curve = ConnectorMath.path(from: a, dirA: dirA, to: b, dirB: dirB)
        let color = selected ? Color.white : Color(electraHex: connector.colorHex)

        ZStack(alignment: .topLeading) {
            curve.stroke(color.opacity(selected ? 1 : 0.85),
                         style: StrokeStyle(lineWidth: selected ? 2.5 : 1.5, lineCap: .round))
                .contentShape(curve.strokedPath(StrokeStyle(lineWidth: 14)))
                .onTapGesture { onSelect() }

            ConnectorMath.arrowhead(at: b, outward: dirB)
                .fill(color)
                .allowsHitTesting(false)

            if !connector.label.isEmpty {
                Text(connector.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(ElectraTheme.surfaceSecondary))
                    .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
                    .position(ConnectorMath.midpoint(from: a, dirA: dirA, to: b, dirB: dirB))
                    .allowsHitTesting(false)
            }

            if let name = pillName {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.square.fill").font(.system(size: 10))
                    Text(name).font(.system(size: 10, weight: .semibold)).lineLimit(1)
                }
                .foregroundStyle(color)
                .frame(width: toRect.width, height: toRect.height)
                .background(Capsule().fill(ElectraTheme.surfaceSecondary))
                .overlay(Capsule().stroke(color.opacity(0.7), lineWidth: 1))
                .contentShape(Capsule())
                .onTapGesture { onFollow() }
                .position(x: toRect.midX, y: toRect.midY)
                .help("Go to \(name)")
            }
        }
    }
}

/// Four edge dots on a control; dragging from one rubber-bands a new connector.
/// Reports drag locations in the canvas coordinate space.
private struct AnchorHandles: View {
    let rect: CGRect
    let onHover: (Bool) -> Void
    let onDragChanged: (CGPoint) -> Void
    let onDragEnded: (CGPoint) -> Void

    private var points: [CGPoint] {
        [CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.midY),
         CGPoint(x: rect.midX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.midY)]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(points.enumerated()), id: \.offset) { _, pt in
                Circle()
                    .fill(ElectraTheme.accent)
                    .overlay(Circle().stroke(.white, lineWidth: 1))
                    .frame(width: 9, height: 9)
                    .contentShape(Circle().inset(by: -5))
                    .position(pt)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named(DeviceCanvas.canvasSpace))
                            .onChanged { onDragChanged($0.location) }
                            .onEnded { onDragEnded($0.location) }
                    )
                    .onHover { onHover($0) }
                    .help("Drag to connect")
            }
        }
    }
}

// MARK: - Control

private struct RichControl: View {
    @EnvironmentObject var model: AppModel
    let control: PresetDocument.Control
    let scale: Double
    let selected: Bool
    let liveOffset: CGSize          // applied to the whole selection during a group drag
    let onSelect: () -> Void
    var onRun: () -> Void = {}
    var onHover: (Bool) -> Void = { _ in }   // canvas tracks hover for connector handles
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
            // Double-click runs a script button; single tap selects. Tap + drag
            // coexist cleanly via simultaneousGesture.
            .simultaneousGesture(TapGesture(count: 2).onEnded { if control.isScript { onRun() } })
            .simultaneousGesture(TapGesture().onEnded { onSelect() })
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { onDragChanged($0.translation) }
                    .onEnded { onDragEnded($0.translation) }
            )
            .onHover { onHover($0) }
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
        .overlay(alignment: .topTrailing) { if control.isScript { runBadge } }
    }

    /// A ▶ badge on script buttons; clicking it runs the script (without selecting).
    private var runBadge: some View {
        Image(systemName: "play.circle.fill")
            .font(.system(size: max(10, 12 * scale * 1.4)))
            .foregroundStyle(.white, color)
            .padding(2)
            .contentShape(Circle())
            .onTapGesture { onRun() }
            .help("Run script")
    }

    @ViewBuilder private var graphic: some View {
        if control.isScript {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: max(10, 14 * scale * 1.4), weight: .semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
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
            FaderShape(color: color, fraction: fillFraction, vertical: true)
                .padding(.vertical, 2)
        case .knob:
            KnobShape(color: color, fraction: fillFraction)
                .padding(.vertical, 2)
        case .custom:
            CustomControlCanvas(controlId: control.id, fraction: fillFraction)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        case .adsr:
            ADSRShape(color: color).padding(.horizontal, 2).padding(.bottom, 2)
        case .fader:
            VStack(spacing: 2) {
                FaderShape(color: color, fraction: fillFraction, vertical: false)
                    .frame(maxHeight: .infinity)
                Text(valueLabel).font(.system(size: max(6, 8 * scale * 1.4), design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
            }
        }
    }

    private var fillFraction: CGFloat { 0.6 } // representative (no live value offline)

    private var valueLabel: String {
        if let p = control.parameterNumber, let t = control.messageType { return "\(t) \(p)" }
        return control.messageType ?? ""
    }
}

/// Renders a Custom control by running its Lua paint callback and replaying the
/// recorded `graphics.*` draw ops on a Canvas. This is what makes a script-drawn
/// control actually appear — and it updates live as the paint script is edited.
private struct CustomControlCanvas: View {
    @EnvironmentObject var model: AppModel
    let controlId: Int
    let fraction: Double

    var body: some View {
        GeometryReader { g in
            let W = Double(g.size.width), H = Double(g.size.height)
            let result = model.renderCustomControl(id: controlId, width: W, height: H, fraction: fraction)
            Canvas { ctx, _ in
                for op in result.ops { Self.draw(op, in: &ctx) }
            }
            .overlay {
                if result.ops.isEmpty {
                    Text(result.error != nil ? "paint: attach a\nsetPaintCallback" : "empty")
                        .font(.system(size: 8)).multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
    }

    private static func draw(_ op: LuaEngine.DrawOp, in ctx: inout GraphicsContext) {
        let c = Color(rgb: op.color)
        let (x, y, a, b, cc, d) = (op.x, op.y, op.a, op.b, op.c, op.d)
        switch op.op {
        case "pixel":
            ctx.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)), with: .color(c))
        case "line":
            var p = Path(); p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: a, y: b))
            ctx.stroke(p, with: .color(c), lineWidth: 1)
        case "rect":
            ctx.stroke(Path(CGRect(x: x, y: y, width: a, height: b)), with: .color(c), lineWidth: 1)
        case "fillRect":
            ctx.fill(Path(CGRect(x: x, y: y, width: a, height: b)), with: .color(c))
        case "roundRect":
            ctx.stroke(Path(roundedRect: CGRect(x: x, y: y, width: a, height: b), cornerRadius: cc), with: .color(c), lineWidth: 1)
        case "fillRoundRect":
            ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: a, height: b), cornerRadius: cc), with: .color(c))
        case "triangle", "fillTriangle":
            var p = Path()
            p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: a, y: b))
            p.addLine(to: CGPoint(x: cc, y: d)); p.closeSubpath()
            if op.op == "triangle" { ctx.stroke(p, with: .color(c), lineWidth: 1) } else { ctx.fill(p, with: .color(c)) }
        case "circle", "fillCircle":
            let r = CGRect(x: x - a, y: y - a, width: a * 2, height: a * 2)
            if op.op == "circle" { ctx.stroke(Path(ellipseIn: r), with: .color(c), lineWidth: 1) } else { ctx.fill(Path(ellipseIn: r), with: .color(c)) }
        case "ellipse", "fillEllipse":
            let r = CGRect(x: x - a, y: y - b, width: a * 2, height: b * 2)
            if op.op == "ellipse" { ctx.stroke(Path(ellipseIn: r), with: .color(c), lineWidth: 1) } else { ctx.fill(Path(ellipseIn: r), with: .color(c)) }
        case "curve":
            // Filled quarter-circle segment (b selects the quadrant 0..3).
            var p = Path(); let start = [180.0, 270.0, 90.0, 0.0][Int(b) % 4]
            p.move(to: CGPoint(x: x, y: y))
            p.addArc(center: CGPoint(x: x, y: y), radius: a,
                     startAngle: .degrees(start), endAngle: .degrees(start + 90), clockwise: false)
            p.closeSubpath(); ctx.fill(p, with: .color(c))
        case "text":
            let text = Text(op.text).font(.system(size: 10)).foregroundColor(c)
            let anchor: UnitPoint = b == 1 ? .top : (b == 2 ? .topTrailing : .topLeading)
            let px = b == 1 ? x + a / 2 : (b == 2 ? x + a : x)
            ctx.draw(text, at: CGPoint(x: px, y: y), anchor: anchor)
        default: break
        }
    }
}

/// Hardware-style fader: a recessed slot, a colored fill up to the value, and a
/// chunky metallic cap (thumb) with a colored indicator line — modelled on the
/// Electra One's physical faders. Works vertically (bottom→top) or horizontally
/// (left→right).
private struct FaderShape: View {
    let color: Color
    var fraction: CGFloat
    var vertical: Bool = true

    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                if vertical {
                    let trackW = max(3, W * 0.20)
                    let capW = min(W * 0.74, trackW + 12)
                    let capH = max(6, H * 0.15)
                    let travel = max(0, H - capH)
                    let capCenterY = capH / 2 + travel * (1 - min(max(fraction, 0), 1))
                    slot(width: trackW, height: H)
                    // colored fill from the bottom up to the cap centre
                    Capsule().fill(color.opacity(0.9))
                        .frame(width: trackW, height: max(0, H - capCenterY))
                        .frame(height: H, alignment: .bottom)
                    cap(w: capW, h: capH, axisVertical: true)
                        .position(x: W / 2, y: capCenterY)
                } else {
                    let trackH = max(3, H * 0.34)
                    let capH = min(H, max(H * 0.82, trackH + 10))
                    let capW = max(6, W * 0.10)
                    let travel = max(0, W - capW)
                    let capCenterX = capW / 2 + travel * min(max(fraction, 0), 1)
                    slot(width: W, height: trackH)
                    Capsule().fill(color.opacity(0.9))
                        .frame(width: max(0, capCenterX), height: trackH)
                        .frame(width: W, alignment: .leading)
                    cap(w: capW, h: capH, axisVertical: false)
                        .position(x: capCenterX, y: H / 2)
                }
            }
            .frame(width: W, height: H)
        }
    }

    /// The recessed track the cap rides in.
    private func slot(width: CGFloat, height: CGFloat) -> some View {
        Capsule().fill(Color.black.opacity(0.5))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            .frame(width: width, height: height)
    }

    /// A metallic cap with a colored indicator line across its short axis.
    private func cap(w: CGFloat, h: CGFloat, axisVertical: Bool) -> some View {
        let r = max(1.5, min(w, h) * 0.28)
        return RoundedRectangle(cornerRadius: r)
            .fill(LinearGradient(colors: [Color(white: 0.92), Color(white: 0.56), Color(white: 0.74)],
                                 startPoint: axisVertical ? .top : .leading,
                                 endPoint: axisVertical ? .bottom : .trailing))
            .frame(width: w, height: h)
            .overlay(
                Group {
                    if axisVertical {
                        Capsule().fill(color).frame(width: w * 0.66, height: max(1.5, h * 0.2))
                    } else {
                        Capsule().fill(color).frame(width: max(1.5, w * 0.2), height: h * 0.66)
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: r).stroke(Color.black.opacity(0.4), lineWidth: 0.75))
            .shadow(color: .black.opacity(0.55), radius: 1.5, y: 1)
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
                // metallic hub (the physical knob cap)
                Circle()
                    .fill(RadialGradient(colors: [Color(white: 0.30), Color(white: 0.13)],
                                         center: .init(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: side * 0.5))
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .frame(width: side * 0.52, height: side * 0.52)
                    .shadow(color: .black.opacity(0.5), radius: 1.5, y: 1)
                // pointer
                Path { p in
                    let a = (start.degrees + sweep * Double(fraction)) * .pi / 180
                    p.move(to: CGPoint(x: side / 2 + cos(a) * side * 0.10,
                                       y: side / 2 + sin(a) * side * 0.10))
                    p.addLine(to: CGPoint(x: side / 2 + cos(a) * side * 0.30,
                                          y: side / 2 + sin(a) * side * 0.30))
                }
                .stroke(color, style: StrokeStyle(lineWidth: max(1.5, lw * 0.7), lineCap: .round))
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
            if model.aiBarPresented {
                aiBar
                Divider()
            }
            VSplitView {
                LuaCodeView(text: Binding(get: { model.luaSource }, set: { model.setLuaSource($0) }))
                    .frame(minHeight: 180)
                ConsolePane(text: model.luaConsole) { model.clearConsole() }
                    .frame(minHeight: 120)
            }
        }
        .background(ElectraTheme.background)
        .sheet(isPresented: $model.aiSettingsPresented) { AISettingsSheet() }
        .sheet(isPresented: $model.libraryPresented) { ScriptLibrarySheet() }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button { model.luaBuild() } label: { Label("Build", systemImage: "hammer") }
            Button { model.luaRun() } label: { Label("Run", systemImage: "play.fill") }
                .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
            Divider().frame(height: 16)
            Button { model.aiBarPresented.toggle() } label: { Label("AI", systemImage: "sparkles") }
                .tint(.purple)
            Divider().frame(height: 16)
            Button { model.libraryPresented = true } label: { Label("Library", systemImage: "books.vertical") }
            Button { model.saveCurrentToLibrary() } label: { Label("Save to Library", systemImage: "text.badge.plus") }
                .disabled(!model.canSaveToLibrary)
            Divider().frame(height: 16)
            Button { model.importLua() } label: { Label("Import…", systemImage: "square.and.arrow.down") }
            Button { model.exportLua() } label: { Label("Export…", systemImage: "square.and.arrow.up") }
            Button { model.presentSaveToDevice() } label: { Label("Push to Device", systemImage: "arrow.up.circle") }
                .disabled(!model.canPushToDevice)
            Spacer()
            if let doc = model.document {
                Text("attached to “\(doc.name.isEmpty ? "preset" : doc.name)”")
                    .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            } else {
                Text("scratch script — Push to Device wraps it in a new preset")
                    .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            }
        }
        .padding(.horizontal, 14).padding(.top, 16).padding(.bottom, 8)
        .background(ElectraTheme.surface)
    }

    private var aiBar: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(AIClient.examples, id: \.self) { ex in
                    Button(ex) { model.aiPrompt = ex }
                }
            } label: {
                Image(systemName: "sparkles").foregroundStyle(.purple)
            }
            .menuStyle(.borderlessButton).frame(width: 28).help("Example prompts")
            TextField("Describe the script you want (e.g. “make control 13 a 5-item algorithm list that recolors the params”)",
                      text: $model.aiPrompt)
                .textFieldStyle(.roundedBorder)
                .onSubmit { model.generateScript() }
                .disabled(model.aiBusy)
            if model.aiBusy {
                ProgressView().controlSize(.small)
            } else {
                Button { model.generateScript() } label: { Label("Generate", systemImage: "wand.and.stars") }
                    .buttonStyle(.borderedProminent).tint(.purple)
                    .disabled(model.aiPrompt.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Button { model.aiSettingsPresented = true } label: { Image(systemName: "gearshape") }
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.purple.opacity(0.08))
    }
}

// MARK: - Script library

/// Browsable list of every saved Lua script. Load one into the editor, rename,
/// or delete. Populated by manual "Save to Library", AI generation, and imports.
private struct ScriptLibrarySheet: View {
    @EnvironmentObject var model: AppModel
    @State private var search = ""
    @State private var renaming: UUID?
    @State private var renameText = ""
    @State private var selection: UUID?

    private var filtered: [LibraryScript] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return model.libraryScripts }
        return model.libraryScripts.filter {
            $0.name.lowercased().contains(q) || $0.source.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Script Library", systemImage: "books.vertical")
                    .font(ElectraTheme.headlineFont)
                Spacer()
                Text("\(model.libraryScripts.count) script\(model.libraryScripts.count == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 10)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(ElectraTheme.textTertiary)
                TextField("Search scripts", text: $search).textFieldStyle(.plain)
            }
            .padding(8)
            .background(ElectraTheme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 16)

            Divider().padding(.top, 10)

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.system(size: 28)).foregroundStyle(ElectraTheme.textTertiary)
                    Text(model.libraryScripts.isEmpty
                         ? "No saved scripts yet.\nGenerate, import, or “Save to Library” to build your collection."
                         : "No scripts match “\(search)”.")
                        .font(.callout).multilineTextAlignment(.center)
                        .foregroundStyle(ElectraTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else {
                List(selection: $selection) {
                    ForEach(filtered) { script in
                        row(script)
                            .tag(script.id)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }

            Divider()
            HStack {
                Button("Save Current Script to Library") { model.saveCurrentToLibrary() }
                    .disabled(!model.canSaveToLibrary)
                Spacer()
                Button("Load") { if let s = selected { model.loadFromLibrary(s) } }
                    .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
                    .disabled(selected == nil)
                Button("Close") { model.libraryPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
        }
        .frame(width: 560, height: 460)
        .background(ElectraTheme.background)
    }

    private var selected: LibraryScript? {
        model.libraryScripts.first { $0.id == selection }
    }

    @ViewBuilder private func row(_ script: LibraryScript) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                if renaming == script.id {
                    TextField("Name", text: $renameText, onCommit: { commitRename(script.id) })
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                } else {
                    Text(script.name).font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                }
                HStack(spacing: 6) {
                    originBadge(script.origin)
                    Text("\(script.lineCount) line\(script.lineCount == 1 ? "" : "s")")
                    Text("·")
                    Text(script.updatedAt, style: .date)
                    if script.id == model.activeLibraryScriptId {
                        Text("· in editor").foregroundStyle(ElectraTheme.accent)
                    }
                }
                .font(.caption2).foregroundStyle(ElectraTheme.textTertiary)
            }
            Spacer()
            if renaming == script.id {
                Button("Done") { commitRename(script.id) }.controlSize(.small)
            } else {
                Menu {
                    Button("Load into Editor") { model.loadFromLibrary(script) }
                    Button("Rename…") { renaming = script.id; renameText = script.name }
                    Divider()
                    Button("Delete", role: .destructive) { model.deleteLibraryScript(script.id) }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(ElectraTheme.textSecondary)
                }
                .menuStyle(.borderlessButton).frame(width: 28)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { model.loadFromLibrary(script) }
    }

    private func originBadge(_ origin: LibraryScript.Origin) -> some View {
        Text(origin.label.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(ElectraTheme.surfaceSecondary)
            .clipShape(Capsule())
            .foregroundStyle(ElectraTheme.textSecondary)
    }

    private func commitRename(_ id: UUID) {
        model.renameLibraryScript(id, to: renameText)
        renaming = nil
    }
}

private struct AISettingsSheet: View {
    @EnvironmentObject var model: AppModel
    @State private var keyField: String = ""
    @State private var availableModels: [String] = []
    @State private var loadingModels = false
    @State private var modelsError: String?

    private func loadModels() {
        loadingModels = true
        modelsError = nil
        let base = model.aiBaseURL
        let key = Keychain.apiKey()
        Task {
            do {
                let ids = try await AIClient.listModels(baseURL: base, apiKey: key)
                await MainActor.run {
                    availableModels = ids
                    loadingModels = false
                    if ids.isEmpty { modelsError = "No models reported by the endpoint." }
                    // Only auto-pick when nothing is set — a hand-typed model
                    // (e.g. one the endpoint doesn't list) must survive Refresh.
                    else if model.aiModel.isEmpty, let first = ids.first { model.aiModel = first }
                }
            } catch {
                await MainActor.run {
                    loadingModels = false
                    modelsError = "\(error)"
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AI Settings").font(.headline)
            Text("Generation uses any OpenAI-compatible chat-completions endpoint — a local Ollama / LM Studio server, OpenAI, OpenRouter, etc. The endpoint and model are stored as preferences; the API key (optional for local servers) is kept in the macOS Keychain.")
                .font(.callout).foregroundStyle(ElectraTheme.textSecondary).fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Endpoint").font(.caption).foregroundStyle(ElectraTheme.textSecondary)
                TextField(AIClient.defaultBaseURL, text: $model.aiBaseURL)
                    .textFieldStyle(.roundedBorder)
                Text("Base URL; “/v1/chat/completions” is appended automatically. Ollama default: \(AIClient.defaultBaseURL)")
                    .font(.caption2).foregroundStyle(ElectraTheme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Model").font(.caption).foregroundStyle(ElectraTheme.textSecondary)
                    Spacer()
                    Button { loadModels() } label: {
                        if loadingModels { Text("Loading…") }
                        else { Label("Refresh", systemImage: "arrow.clockwise") }
                    }
                    .buttonStyle(.borderless).controlSize(.small).disabled(loadingModels)
                }
                HStack {
                    if !availableModels.isEmpty {
                        Picker("", selection: $model.aiModel) {
                            ForEach(availableModels, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                    }
                    TextField(AIClient.defaultModel, text: $model.aiModel)
                        .textFieldStyle(.roundedBorder)
                }
                if let err = modelsError {
                    Text(err).font(.caption2).foregroundStyle(.orange).lineLimit(2)
                } else {
                    Text("Pick a model the endpoint serves, or type one (e.g. llama3.1, gemma3, ornith:latest).")
                        .font(.caption2).foregroundStyle(ElectraTheme.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API key (optional)").font(.caption).foregroundStyle(ElectraTheme.textSecondary)
                HStack {
                    SecureField(model.apiKeyPresent ? "•••••••••• (stored)" : "leave blank for local servers", text: $keyField)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") { model.saveAPIKey(keyField); keyField = "" }
                        .disabled(keyField.trimmingCharacters(in: .whitespaces).isEmpty)
                    if model.apiKeyPresent {
                        Button("Remove", role: .destructive) { model.clearAPIKey() }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Done") { model.aiSettingsPresented = false }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20).frame(width: 460)
        .onAppear { loadModels() }
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

// MARK: - Simulator (Run)

/// The in-app simulator: renders the attached preset's screen, the status-bar
/// text the script set via `info.setText`, and the console output from the run.
/// The script executes against a mocked Electra environment (see LuaEngine), so
/// this is a preview — true device behaviour comes from Push to Device.
private struct SimulatorSheet: View {
    @EnvironmentObject var model: AppModel
    private let screenW = PresetDocument.screenWidth
    private let screenH = PresetDocument.screenHeight

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            screen.background(Color.black)
            Divider()
            console
        }
        .frame(width: 760, height: 640)
        .background(ElectraTheme.background)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Label("Simulator", systemImage: "play.rectangle.fill").font(.headline)
            Text(model.document?.name.isEmpty == false ? model.document!.name : "Lua Script")
                .foregroundStyle(ElectraTheme.textSecondary)
            Spacer()
            Button { model.luaRun() } label: { Label("Run Again", systemImage: "play.fill") }
                .buttonStyle(.bordered)
            Button("Done") { model.simulatorPresented = false }
                .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
        }
        .padding(12)
        .background(ElectraTheme.surface)
    }

    private var currentControls: [PresetDocument.Control] {
        model.document?.controls(onPage: model.currentPageId) ?? []
    }

    private var screen: some View {
        GeometryReader { geo in
            let pad: CGFloat = 28
            let scale = max(0.05, min((geo.size.width - pad) / screenW,
                                      (geo.size.height - pad - 26) / screenH))
            VStack(spacing: 6) {
                ZStack(alignment: .topLeading) {
                    Color.black
                    ForEach(currentControls) { control in
                        RichControl(control: control, scale: scale, selected: false, liveOffset: .zero,
                                    onSelect: {},
                                    onRun: { model.runScriptControl(id: control.id) },
                                    onDragChanged: { _ in }, onDragEnded: { _ in })
                    }
                    if currentControls.isEmpty {
                        Text(model.document == nil
                             ? "Script-only run — no preset screen to render.\nUse Push to Device to run it on hardware."
                             : "No controls on this page.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: screenW * scale, height: screenH * scale)
                    }
                }
                .frame(width: screenW * scale, height: screenH * scale)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                // Bottom status bar — reflects info.setText() from the run.
                Text(model.simBottomText.isEmpty
                     ? (model.document?.name.isEmpty == false ? model.document!.name : "Electra One")
                     : model.simBottomText)
                    .font(.system(size: max(8, 10 * scale), weight: .medium, design: .monospaced))
                    .foregroundStyle(model.simBottomText.isEmpty ? ElectraTheme.textTertiary : ElectraTheme.accent)
                    .lineLimit(1)
                    .frame(width: screenW * scale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(pad / 2)
        }
    }

    private var console: some View {
        ConsolePane(text: model.luaConsole, onClear: { model.clearConsole() })
            .frame(height: 190)
    }
}

