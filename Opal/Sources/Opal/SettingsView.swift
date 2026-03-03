import SwiftUI
import AppKit

private enum SettingsSection: String, CaseIterable, Identifiable {
    case background = "Background"
    case workspace = "Workspace"
    case session = "Session"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .background:
            return "wand.and.stars"
        case .workspace:
            return "folder"
        case .session:
            return "arrow.clockwise"
        case .about:
            return "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .background

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .frame(minWidth: 190)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedSection.rawValue)
                        .font(.title2.weight(.semibold))

                    sectionContent
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(20)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 540)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .background:
            BackgroundSettingsPanel()
        case .workspace:
            WorkspaceSettingsPanel()
        case .session:
            SessionSettingsPanel()
        case .about:
            AboutSettingsPanel()
        }
    }
}

private struct BackgroundSettingsPanel: View {
    @StateObject private var settings = BackgroundSettings.shared
    @State private var primaryColor = Color(hue: 210 / 360.0, saturation: 0.8, brightness: 0.9)
    @State private var secondaryColor = Color(hue: 260 / 360.0, saturation: 0.8, brightness: 0.9)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(
                title: "Renderer",
                subtitle: "Only options that currently affect the live background renderer are shown."
            ) {
                Toggle("Use Metal shader renderer", isOn: $settings.useMetalShader)

                Picker("Style", selection: $settings.shaderStyle) {
                    ForEach(BackgroundSettings.ShaderStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 340)
                .disabled(!settings.useMetalShader)

                SettingsMetricSlider(
                    title: "Transparency",
                    valueText: "\(Int(settings.shaderTransparency))%",
                    value: $settings.shaderTransparency,
                    range: 0...100,
                    step: 1
                )
                .disabled(!settings.useMetalShader)
            }

            SettingsCard(
                title: "Motion",
                subtitle: "Wave animation controls used by both Metal and fallback canvas rendering."
            ) {
                Toggle("Animate background", isOn: $settings.animationEnabled)

                SettingsMetricSlider(
                    title: "Primary speed",
                    valueText: String(format: "%.3f", settings.primaryWaveSpeed),
                    value: $settings.primaryWaveSpeed,
                    range: 0.001...0.12,
                    step: 0.001
                )
                .disabled(!settings.animationEnabled)

                SettingsMetricSlider(
                    title: "Secondary speed",
                    valueText: String(format: "%.3f", settings.secondaryWaveSpeed),
                    value: $settings.secondaryWaveSpeed,
                    range: 0.001...0.12,
                    step: 0.001
                )
                .disabled(!settings.animationEnabled)

                SettingsMetricSlider(
                    title: "Wave count",
                    valueText: "\(settings.waveCount)",
                    value: Binding(
                        get: { Double(settings.waveCount) },
                        set: { settings.waveCount = Int($0) }
                    ),
                    range: 1...8,
                    step: 1
                )
            }

            SettingsCard(
                title: "Palette",
                subtitle: "Primary/secondary hues and presets used by shader color generation."
            ) {
                HStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Primary")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $primaryColor)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Secondary")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $secondaryColor)
                            .labelsHidden()
                    }
                    Spacer()
                }

                SettingsMetricSlider(
                    title: "Primary hue",
                    valueText: "\(Int(settings.primaryHue))°",
                    value: $settings.primaryHue,
                    range: 0...360,
                    step: 1
                )

                SettingsMetricSlider(
                    title: "Secondary hue",
                    valueText: "\(Int(settings.secondaryHue))°",
                    value: $settings.secondaryHue,
                    range: 0...360,
                    step: 1
                )

                HStack(spacing: 8) {
                    SettingsPresetButton(title: "Ocean", colors: [Color.cyan, Color.blue]) {
                        applyPreset(primary: 200, secondary: 240)
                    }
                    SettingsPresetButton(title: "Sunset", colors: [Color.orange, Color.pink]) {
                        applyPreset(primary: 20, secondary: 340)
                    }
                    SettingsPresetButton(title: "Forest", colors: [Color.green, Color.teal]) {
                        applyPreset(primary: 120, secondary: 160)
                    }
                    SettingsPresetButton(title: "Purple", colors: [Color.purple, Color.indigo]) {
                        applyPreset(primary: 270, secondary: 300)
                    }
                }
            }

            SettingsCard(
                title: "Metal Effects",
                subtitle: "These controls are active only when Metal is enabled."
            ) {
                BackgroundEffectPreviewTile(settings: settings)

                SettingsEffectRow(
                    title: "Bloom",
                    description: "Glow around brighter highlights.",
                    isEnabled: $settings.bloomEnabled,
                    strength: $settings.bloomStrength,
                    range: 0.0...2.0,
                    step: 0.05,
                    valueText: { String(format: "%.2f", $0) }
                )
                .disabled(!settings.useMetalShader)

                SettingsEffectRow(
                    title: "Chromatic Aberration",
                    description: "Subtle RGB split near edges.",
                    isEnabled: $settings.chromaticAberrationEnabled,
                    strength: $settings.chromaticAberrationStrength,
                    range: 0.0...0.03,
                    step: 0.001,
                    valueText: { String(format: "%.3f", $0) }
                )
                .disabled(!settings.useMetalShader)

                SettingsEffectRow(
                    title: "Gaussian Blur",
                    description: "Soft blur for liquid glass diffusion.",
                    isEnabled: $settings.blurEnabled,
                    strength: $settings.blurRadius,
                    range: 0.0...0.03,
                    step: 0.001,
                    valueText: { String(format: "%.3f", $0) }
                )
                .disabled(!settings.useMetalShader)
            }
        }
        .onAppear(perform: syncColors)
        .onChange(of: settings.primaryHue) { _, _ in syncColors() }
        .onChange(of: settings.secondaryHue) { _, _ in syncColors() }
        .onChange(of: primaryColor) { _, color in
            settings.primaryHue = hue(from: color)
        }
        .onChange(of: secondaryColor) { _, color in
            settings.secondaryHue = hue(from: color)
        }
    }

    private func applyPreset(primary: Double, secondary: Double) {
        settings.primaryHue = primary
        settings.secondaryHue = secondary
        syncColors()
    }

    private func syncColors() {
        primaryColor = Color(hue: settings.primaryHue / 360.0, saturation: 0.8, brightness: 0.9)
        secondaryColor = Color(hue: settings.secondaryHue / 360.0, saturation: 0.8, brightness: 0.9)
    }

    private func hue(from color: Color) -> Double {
        let nsColor = NSColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Double(hue * 360.0)
    }
}

private struct WorkspaceSettingsPanel: View {
    @AppStorage("opal.default.editor") private var preferredEditor = "micro"
    @AppStorage("opal.sidebar.visible") private var sidebarVisible = true
    @State private var editorStatus = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(
                title: "Default Editor",
                subtitle: "Used by sidebar file opening actions."
            ) {
                TextField("micro", text: $preferredEditor)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        normalizeEditor()
                    }

                HStack(spacing: 8) {
                    Button("micro") { preferredEditor = "micro"; refreshEditorStatus() }
                        .buttonStyle(.bordered)
                    Button("nvim") { preferredEditor = "nvim"; refreshEditorStatus() }
                        .buttonStyle(.bordered)
                    Button("code") { preferredEditor = "code"; refreshEditorStatus() }
                        .buttonStyle(.bordered)
                }

                if !editorStatus.isEmpty {
                    Text(editorStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsCard(
                title: "Layout",
                subtitle: "Workspace layout settings that are currently implemented."
            ) {
                Toggle("Show sidebar by default", isOn: $sidebarVisible)
            }
        }
        .onAppear(perform: refreshEditorStatus)
        .onChange(of: preferredEditor) { _, _ in
            refreshEditorStatus()
        }
    }

    private func normalizeEditor() {
        preferredEditor = preferredEditor.trimmingCharacters(in: .whitespacesAndNewlines)
        if preferredEditor.isEmpty {
            preferredEditor = "micro"
        }
        refreshEditorStatus()
    }

    private func refreshEditorStatus() {
        let editor = preferredEditor.trimmingCharacters(in: .whitespacesAndNewlines)
        if editor.isEmpty {
            editorStatus = "Enter an editor command, for example: micro"
            return
        }

        if isEditorAvailable(editor) {
            editorStatus = "Available: \(editor)"
        } else if editor == "micro" {
            editorStatus = "micro is not installed. Install with: brew install micro"
        } else {
            editorStatus = "\(editor) not found in PATH. Install it or choose another command."
        }
    }

    private func isEditorAvailable(_ editor: String) -> Bool {
        if editor.contains("/") {
            return FileManager.default.isExecutableFile(atPath: editor)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [editor]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

private struct SessionSettingsPanel: View {
    @AppStorage("opal.session.autorestore") private var autoRestore = true
    @State private var snapshot: SessionSnapshot?

    private static let snapshotKey = "opal.session.snapshot.v1"

    struct SessionSnapshot: Decodable {
        let currentDirectory: String
        let recentCommands: [String]
        let preferredEditor: String
        let savedAt: TimeInterval
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(
                title: "Restore",
                subtitle: "Session restore currently includes working directory and recent command history."
            ) {
                Toggle("Restore previous session on launch", isOn: $autoRestore)

                if let snapshot {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saved directory")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(snapshot.currentDirectory)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(2)
                            .textSelection(.enabled)

                        Text("Commands saved: \(snapshot.recentCommands.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Saved at: \(formattedDate(snapshot.savedAt))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No saved session snapshot found.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Button("Refresh") {
                        loadSnapshot()
                    }
                    .buttonStyle(.bordered)

                    Button("Delete Saved Snapshot") {
                        UserDefaults.standard.removeObject(forKey: Self.snapshotKey)
                        loadSnapshot()
                    }
                    .buttonStyle(.bordered)
                    .disabled(snapshot == nil)
                }
            }
        }
        .onAppear(perform: loadSnapshot)
    }

    private func loadSnapshot() {
        guard let data = UserDefaults.standard.data(forKey: Self.snapshotKey),
              let decoded = try? JSONDecoder().decode(SessionSnapshot.self, from: data) else {
            snapshot = nil
            return
        }
        snapshot = decoded
    }

    private func formattedDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
}

private struct AboutSettingsPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(
                title: "Version",
                subtitle: "Build and runtime information exposed by the app."
            ) {
                HStack {
                    Text("Opal")
                    Spacer()
                    Text("1.3.6")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Shell Build")
                    Spacer()
                    Text("Seashell \(readBundledSeashellBuildVersion())")
                        .foregroundStyle(.secondary)
                }
            }

            SettingsCard(
                title: "Links",
                subtitle: "Project resources."
            ) {
                Link("GitHub", destination: URL(string: "https://github.com/opal-terminal/opal")!)
                Link("Releases", destination: URL(string: "https://github.com/opal-terminal/opal/releases")!)
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content
        }
        .padding(14)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
    }
}

private struct SettingsMetricSlider: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .frame(width: 155, alignment: .leading)
                Text(valueText)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Slider(value: $value, in: range, step: step)
                .frame(maxWidth: 340)
        }
    }
}

private struct SettingsPresetButton: View {
    let title: String
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: 64, height: 30)
                Text(title)
                    .font(.caption2)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsEffectRow: View {
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    @Binding var strength: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueText: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(title, isOn: $isEnabled)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            if isEnabled {
                SettingsMetricSlider(
                    title: "Intensity",
                    valueText: valueText(strength),
                    value: $strength,
                    range: range,
                    step: step
                )
            }
        }
    }
}

struct BackgroundEffectPreviewTile: View {
    @ObservedObject var settings: BackgroundSettings
    @State private var previewFocus: MetalLiquidGlassBackground.PreviewFocus = .none

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Effect Preview")
                .font(.subheadline.weight(.semibold))

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.2))

                if settings.useMetalShader {
                    MetalLiquidGlassBackground(settings: settings, previewFocus: previewFocus)
                        .allowsHitTesting(false)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    CanvasLiquidGlassBackground()
                        .allowsHitTesting(false)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Text(previewLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.35), in: Capsule())
                    .padding(8)
            }
            .frame(height: 112)

            HStack(spacing: 8) {
                PreviewButton(title: "Bloom") { runPreview(.bloom) }
                PreviewButton(title: "Chromatic") { runPreview(.chromatic) }
                PreviewButton(title: "Blur") { runPreview(.blur) }
                PreviewButton(title: "All") { runPreview(.all) }
            }
            .disabled(!settings.useMetalShader)

            Text("Buttons temporarily boost each effect without changing your saved values.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var previewLabel: String {
        switch previewFocus {
        case .none:
            return "Live"
        case .bloom:
            return "Bloom Boost"
        case .chromatic:
            return "Chromatic Boost"
        case .blur:
            return "Blur Boost"
        case .all:
            return "All Effects Boost"
        }
    }

    private func runPreview(_ focus: MetalLiquidGlassBackground.PreviewFocus) {
        previewFocus = focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if previewFocus == focus {
                previewFocus = .none
            }
        }
    }
}

private struct PreviewButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
    }
}

#Preview {
    SettingsView()
}
