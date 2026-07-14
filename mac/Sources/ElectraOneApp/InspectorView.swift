import SwiftUI
import ElectraKit

/// Right-hand inspector: preset / control / connector editing.
/// Always exposes MIDI binding + Lua function + pot for controls (P0/P1).
struct Inspector: View {
    @EnvironmentObject var model: AppModel
    @Binding var multiSelection: Set<Int>

    private static let messageTypes = [
        "cc7", "cc14", "nrpn", "rpn", "note", "program",
        "virtual", "start", "stop", "SysEx", "pitchbend",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if multiSelection.count > 1 {
                    multiInspector
                } else if let k = model.selectedConnector {
                    connectorInspector(k)
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

    // MARK: Multi

    private var multiInspector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(multiSelection.count) CONTROLS")
                .font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
            Text("Use the alignment bar above the canvas, drag to move them together, or delete.")
                .font(.caption).foregroundStyle(ElectraTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive) {
                model.deleteControls(Array(multiSelection))
                multiSelection.removeAll()
            } label: {
                Label("Delete \(multiSelection.count)", systemImage: "trash")
            }
        }
    }

    // MARK: Preset + devices

    @ViewBuilder private var presetInspector: some View {
        Text("PRESET").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
        labeled("Name") {
            TextField("Name", text: Binding(
                get: { model.document?.name ?? "" },
                set: { model.setPresetName($0) }
            ))
            .textFieldStyle(.roundedBorder)
        }
        if let page = (model.document?.pages.first { $0.id == model.currentPageId }) {
            labeled("Current page") {
                TextField("Page name", text: Binding(
                    get: { page.name },
                    set: { model.renamePage(page.id, $0) }
                ))
                .textFieldStyle(.roundedBorder)
            }
            Button { model.addPage() } label: {
                Label("Add Page", systemImage: "plus.rectangle")
            }
            .controlSize(.small)
        }
        if let lua = model.luaInfo {
            Label(lua, systemImage: "curlybraces.square")
                .font(.caption).foregroundStyle(.purple)
        }
        Divider()
        devicesSection
        Divider()
        Text("\(model.currentControls.count) control(s) on this page")
            .font(.caption).foregroundStyle(ElectraTheme.textSecondary)
        Text("Select a control to edit bindings (MIDI CC, Lua function, pot).")
            .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var devicesSection: some View {
        Text("DEVICES").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
        let devices = model.document?.devices ?? []
        if devices.isEmpty {
            Text("No devices in preset.")
                .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
        }
        ForEach(devices) { dev in
            VStack(alignment: .leading, spacing: 6) {
                Text("Device \(dev.id)")
                    .font(.caption2.bold()).foregroundStyle(ElectraTheme.textTertiary)
                labeled("Name") {
                    TextField("Name", text: Binding(
                        get: { dev.name },
                        set: { model.setDeviceName(dev.id, $0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
                HStack {
                    labeled("Port") {
                        Picker("", selection: Binding(
                            get: { dev.port },
                            set: { model.setDevicePort(dev.id, $0) }
                        )) {
                            Text("1 (MIDI IO 1)").tag(1)
                            Text("2 (MIDI IO 2)").tag(2)
                        }
                        .labelsHidden()
                    }
                    labeled("Ch") {
                        TextField("", value: Binding(
                            get: { dev.channel },
                            set: { model.setDeviceChannel(dev.id, $0) }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 56)
                    }
                }
                labeled("Rate ms") {
                    TextField("e.g. 10", value: Binding(
                        get: { dev.rate ?? 0 },
                        set: { model.setDeviceRate(dev.id, $0 > 0 ? $0 : nil) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                }
            }
            .padding(8)
            .background(ElectraTheme.surfaceSecondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        Text("Mini TRS jacks = Port 1 / MIDI IO. Port 2 is USB-only on Mini.")
            .font(.caption2).foregroundStyle(ElectraTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Control

    @ViewBuilder private func controlInspector(_ c: PresetDocument.Control) -> some View {
        HStack {
            Text("CONTROL").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
            Spacer()
            Button { model.duplicateControls([c.id]) } label: {
                Image(systemName: "plus.square.on.square")
            }.buttonStyle(.borderless)
            Button(role: .destructive) { model.deleteSelectedControl() } label: {
                Image(systemName: "trash")
            }.buttonStyle(.borderless)
        }
        labeled("Name") {
            TextField("Name", text: Binding(
                get: { c.name },
                set: { model.setControlName(c.id, $0) }
            ))
            .textFieldStyle(.roundedBorder)
        }
        labeled("Kind") {
            Picker("", selection: Binding(
                get: { c.kind },
                set: { model.setControlKind(c.id, $0) }
            )) {
                ForEach(PresetDocument.ControlKind.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }.labelsHidden()
        }
        labeled("Color") {
            HStack(spacing: 6) {
                ForEach(PresetDocument.palette, id: \.self) { hex in
                    Circle().fill(Color(electraHex: hex)).frame(width: 20, height: 20)
                        .overlay(Circle().stroke(
                            Color.primary.opacity(
                                c.colorHex.caseInsensitiveCompare(hex) == .orderedSame ? 0.9 : 0.15
                            ), lineWidth: 2))
                        .onTapGesture { model.setControlColor(c.id, hex: hex) }
                }
            }
        }
        if c.isCustom {
            customSection(c)
        }
        if c.isScript {
            scriptSection(c)
        }
        Divider()
        bindingSection(c)
        if (model.document?.controlValueDetails(id: c.id).count ?? 0) > 1 {
            Divider()
            multiValueSection(c)
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
        Divider()
        connectSection(c)
    }

    @ViewBuilder private func customSection(_ c: PresetDocument.Control) -> some View {
        Divider()
        Text("PAINT SCRIPT").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
        Text("Draws via `\(PresetDocument.paintFunctionName(forControlId: c.id))(display)` in Lua.")
            .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
        Button { model.editPaintScript(id: c.id) } label: {
            Label("Edit Paint Script…", systemImage: "paintbrush.pointed")
        }
        .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
    }

    @ViewBuilder private func scriptSection(_ c: PresetDocument.Control) -> some View {
        Divider()
        Text("SCRIPT ACTIONS").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
        Text("Runs `\(c.functionName ?? "")`. Use Binding below to reassign the function name.")
            .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
        HStack {
            Button { model.runScriptControl(id: c.id) } label: {
                Label("Run", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent).tint(ElectraTheme.accent)
            Button { model.editScriptControl(id: c.id) } label: {
                Label("Edit Script…", systemImage: "curlybraces")
            }
        }
        Menu {
            Button("From Lua Editor") { model.replaceScriptControl(id: c.id, from: .editor) }
            Button("Paste from Clipboard") { model.replaceScriptControl(id: c.id, from: .clipboard) }
            Button("Import File…") { model.replaceScriptControl(id: c.id, from: .file) }
        } label: {
            Label("Replace body…", systemImage: "arrow.triangle.2.circlepath")
        }
        .menuStyle(.borderlessButton)
    }

    /// Primary binding editor — always shown (MIDI + Lua + pot + mode).
    @ViewBuilder private func bindingSection(_ c: PresetDocument.Control) -> some View {
        Text("BINDING").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
        Text("Dummy CC + Lua is normal for action pads (e.g. onRecord). Soft keys use pot 9–12.")
            .font(.caption2).foregroundStyle(ElectraTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)

        labeled("Lua function") {
            TextField("e.g. onPlayStop (empty = none)", text: Binding(
                get: { c.functionName ?? "" },
                set: { model.setControlFunctionName(c.id, $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(ElectraTheme.monoFont)
        }
        if let fn = c.functionName, !fn.isEmpty {
            Button { model.editorMode = .script } label: {
                Label("Jump to Lua editor", systemImage: "arrow.right.square")
            }
            .controlSize(.small)
        }

        labeled("Pot id") {
            Picker("", selection: Binding(
                get: { c.potId ?? 0 },
                set: { model.setControlPotId(c.id, $0 == 0 ? nil : $0) }
            )) {
                Text("None (touch / soft-key alias)").tag(0)
                ForEach(1...12, id: \.self) { n in
                    Text(n <= 8 ? "Pot \(n)" : "Pot \(n) (Mini soft key)").tag(n)
                }
            }
            .labelsHidden()
        }

        labeled("Mode") {
            Picker("", selection: Binding(
                get: { c.mode ?? "" },
                set: { model.setControlMode(c.id, $0.isEmpty ? nil : $0) }
            )) {
                Text("—").tag("")
                Text("momentary").tag("momentary")
                Text("toggle").tag("toggle")
            }
            .labelsHidden()
        }

        labeled("Message") {
            Picker("", selection: Binding(
                get: { c.messageType ?? "cc7" },
                set: { model.setControlMessageType(c.id, $0) }
            )) {
                ForEach(Self.messageTypes, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
        }

        labeled("Parameter #") {
            TextField("", value: Binding(
                get: { c.parameterNumber ?? 0 },
                set: { model.setControlParameterNumber(c.id, $0) }
            ), format: .number)
            .textFieldStyle(.roundedBorder)
        }

        HStack {
            labeled("onValue") {
                TextField("—", value: Binding(
                    get: { c.onValue ?? -1 },
                    set: { model.setControlOnValue(c.id, $0 < 0 ? nil : $0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
            }
            labeled("offValue") {
                TextField("—", value: Binding(
                    get: { c.offValue ?? -1 },
                    set: { model.setControlOffValue(c.id, $0 < 0 ? nil : $0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
            }
        }
        Text("Use −1 or clear field intent: set −1 to remove on/off value keys.")
            .font(.caption2).foregroundStyle(ElectraTheme.textTertiary)

        HStack {
            labeled("Min") {
                TextField("", value: Binding(
                    get: { c.minValue ?? 0 },
                    set: { model.setControlMessageMinMax(c.id, min: $0, max: c.maxValue) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
            }
            labeled("Max") {
                TextField("", value: Binding(
                    get: { c.maxValue ?? 127 },
                    set: { model.setControlMessageMinMax(c.id, min: c.minValue, max: $0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
            }
        }

        if let devices = model.document?.devices, !devices.isEmpty {
            labeled("Device id") {
                Picker("", selection: Binding(
                    get: { c.deviceId ?? devices.first?.id ?? 1 },
                    set: { model.setControlMessageDeviceId(c.id, $0) }
                )) {
                    ForEach(devices) { d in
                        Text("\(d.id): \(d.name)").tag(d.id)
                    }
                }
                .labelsHidden()
            }
        }
    }

    @ViewBuilder private func multiValueSection(_ c: PresetDocument.Control) -> some View {
        Text("VALUES").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
        let rows = model.document?.controlValueDetails(id: c.id) ?? []
        ForEach(rows) { row in
            VStack(alignment: .leading, spacing: 4) {
                Text(row.valueId)
                    .font(.caption.bold()).foregroundStyle(ElectraTheme.accent)
                labeled("Message") {
                    Picker("", selection: Binding(
                        get: { row.messageType ?? "cc7" },
                        set: { model.setValueMessageType(c.id, valueId: row.valueId, $0) }
                    )) {
                        ForEach(Self.messageTypes, id: \.self) { Text($0).tag($0) }
                    }.labelsHidden()
                }
                labeled("Param #") {
                    TextField("", value: Binding(
                        get: { row.parameterNumber ?? 0 },
                        set: { model.setValueParameterNumber(c.id, valueId: row.valueId, $0) }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                }
                labeled("Function") {
                    TextField("", text: Binding(
                        get: { row.functionName ?? "" },
                        set: { model.setValueFunctionName(c.id, valueId: row.valueId, $0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(ElectraTheme.monoFont)
                }
                HStack {
                    labeled("Min") {
                        TextField("", value: Binding(
                            get: { row.minValue ?? 0 },
                            set: { model.setValueMinMax(c.id, valueId: row.valueId, min: $0, max: row.maxValue) }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                    }
                    labeled("Max") {
                        TextField("", value: Binding(
                            get: { row.maxValue ?? 127 },
                            set: { model.setValueMinMax(c.id, valueId: row.valueId, min: row.minValue, max: $0) }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding(8)
            .background(ElectraTheme.surfaceSecondary.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    @ViewBuilder private func connectSection(_ c: PresetDocument.Control) -> some View {
        Text("CONNECT").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
        Text("Drag from a dot on the control's edge to arrow another control.")
            .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
        let otherPages = (model.document?.pages ?? []).filter { $0.id != model.currentPageId }
        if !otherPages.isEmpty {
            Menu {
                ForEach(otherPages) { page in
                    Button(page.name) { model.addConnector(from: c.id, to: .page(page.id)) }
                }
            } label: {
                Label("Link to Page…", systemImage: "arrow.turn.up.right")
            }
            .menuStyle(.borderlessButton)
        }
        let related = model.currentConnectors.filter {
            $0.fromControlId == c.id || $0.target == .control(c.id)
        }
        ForEach(related) { k in
            Button {
                model.selectedControlId = nil
                model.selectedConnectorId = k.id
            } label: {
                Label(route(k), systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.caption).lineLimit(1)
            }
            .buttonStyle(.borderless)
        }
    }

    @ViewBuilder private func connectorInspector(_ k: PresetDocument.Connector) -> some View {
        HStack {
            Text("CONNECTOR").font(.caption.bold()).foregroundStyle(ElectraTheme.textSecondary)
            Spacer()
            Button(role: .destructive) { model.deleteConnector(k.id) } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        Label(route(k), systemImage: "arrow.right").font(.callout)
        labeled("Label") {
            TextField("Optional label", text: Binding(
                get: { k.label },
                set: { model.setConnectorLabel(k.id, $0) }
            ))
            .textFieldStyle(.roundedBorder)
        }
        labeled("Color") {
            HStack(spacing: 6) {
                ForEach(PresetDocument.palette, id: \.self) { hex in
                    Circle().fill(Color(electraHex: hex)).frame(width: 20, height: 20)
                        .overlay(Circle().stroke(
                            Color.primary.opacity(
                                k.colorHex.caseInsensitiveCompare(hex) == .orderedSame ? 0.9 : 0.15
                            ), lineWidth: 2))
                        .onTapGesture { model.setConnectorColor(k.id, hex: hex) }
                }
            }
        }
        switch k.target {
        case .control:
            Button { model.reverseConnector(k.id) } label: {
                Label("Reverse Direction", systemImage: "arrow.left.arrow.right")
            }
        case .page(let pid):
            Button { model.followConnector(k) } label: {
                Label("Go to \(pageName(pid))", systemImage: "arrow.right.square")
            }
        }
        Divider()
        Text("Connectors are board annotations — they save with the file but are never uploaded to the device.")
            .font(.caption).foregroundStyle(ElectraTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func controlName(_ id: Int) -> String {
        guard let c = model.document?.control(id: id) else { return "#\(id)" }
        return c.name.isEmpty ? c.type.uppercased() : c.name
    }

    private func pageName(_ id: Int) -> String {
        model.document?.pages.first { $0.id == id }?.name ?? "Page \(id)"
    }

    private func route(_ k: PresetDocument.Connector) -> String {
        switch k.target {
        case .control(let t): return "\(controlName(k.fromControlId)) → \(controlName(t))"
        case .page(let p):    return "\(controlName(k.fromControlId)) → \(pageName(p))"
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
            TextField("", value: Binding(
                get: { Int(value) },
                set: { set(Double($0)) }
            ), format: .number)
            .textFieldStyle(.roundedBorder)
        }
    }
}
