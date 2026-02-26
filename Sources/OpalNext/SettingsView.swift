import AppKit
import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case background = "Background"
    case typography = "Typography"
    case cursor = "Cursor"
    case shell = "Shell"
    case session = "Session"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .background:
            return "wand.and.stars"
        case .typography:
            return "textformat"
        case .cursor:
            return "cursorarrow.rays"
        case .shell:
            return "terminal"
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
            .frame(minWidth: 180)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedSection.rawValue)
                        .font(.title2.weight(.semibold))

                    sectionView
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(20)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 540)
    }

    @ViewBuilder
    private var sectionView: some View {
        switch selectedSection {
        case .background:
            BackgroundSettingsSection()
        case .typography:
            TypographySettingsSection()
        case .cursor:
            CursorSettingsSection()
        case .shell:
            ShellSettingsSection()
        case .session:
            SessionSettingsSection()
        case .about:
            AboutSettingsSection()
        }
    }
}

private struct BackgroundSettingsSection: View {
    @ObservedObject private var profile = BackgroundProfile.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(
                title: "Renderer",
                subtitle: "All controls remain visible. Inactive ones disable when Metal is off."
            ) {
                Toggle("Use Metal shader renderer", isOn: $profile.useMetalShader)

                Picker("Shader style", selection: $profile.shaderStyle) {
                    ForEach(BackgroundProfile.ShaderStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
                .disabled(!profile.useMetalShader)

                MetricSlider(
                    title: "Transparency",
                    valueText: "\(Int(profile.shaderTransparency))%",
                    value: $profile.shaderTransparency,
                    range: 0...100,
                    step: 1
                )
                .disabled(!profile.useMetalShader)
            }

            SettingsCard(
                title: "Motion",
                subtitle: "Calm defaults; tune only if needed."
            ) {
                Toggle("Animate shader", isOn: $profile.animationEnabled)

                MetricSlider(
                    title: "Primary speed",
                    valueText: String(format: "%.3f", profile.primaryWaveSpeed),
                    value: $profile.primaryWaveSpeed,
                    range: 0.001...0.12,
                    step: 0.001
                )
                .disabled(!profile.animationEnabled)

                MetricSlider(
                    title: "Secondary speed",
                    valueText: String(format: "%.3f", profile.secondaryWaveSpeed),
                    value: $profile.secondaryWaveSpeed,
                    range: 0.001...0.12,
                    step: 0.001
                )
                .disabled(!profile.animationEnabled)

                MetricSlider(
                    title: "Wave count",
                    valueText: "\(profile.waveCount)",
                    value: Binding(
                        get: { Double(profile.waveCount) },
                        set: { profile.waveCount = Int($0) }
                    ),
                    range: 1...8,
                    step: 1
                )
            }

            SettingsCard(
                title: "Post Effects",
                subtitle: "Preview buttons temporarily boost intensity so regressions are obvious."
            ) {
                BackgroundEffectPreviewTile(profile: profile)

                EffectControlRow(
                    title: "Bloom",
                    isEnabled: $profile.bloomEnabled,
                    value: $profile.bloomStrength,
                    range: 0...2,
                    step: 0.05,
                    valueFormatter: { String(format: "%.2f", $0) }
                )
                .disabled(!profile.useMetalShader)

                EffectControlRow(
                    title: "Chromatic Aberration",
                    isEnabled: $profile.chromaticAberrationEnabled,
                    value: $profile.chromaticAberrationStrength,
                    range: 0...0.03,
                    step: 0.001,
                    valueFormatter: { String(format: "%.3f", $0) }
                )
                .disabled(!profile.useMetalShader)

                EffectControlRow(
                    title: "Gaussian Blur",
                    isEnabled: $profile.blurEnabled,
                    value: $profile.blurRadius,
                    range: 0...0.03,
                    step: 0.001,
                    valueFormatter: { String(format: "%.3f", $0) }
                )
                .disabled(!profile.useMetalShader)
            }
        }
    }
}

private struct TypographySettingsSection: View {
    @ObservedObject private var appearance = TerminalAppearanceSettings.shared

    var body: some View {
        SettingsCard(
            title: "Font",
            subtitle: "Keep this simple for predictable terminal layout."
        ) {
            Picker("Family", selection: $appearance.fontFamily) {
                ForEach(TerminalAppearanceSettings.commonMonospaceFamilies, id: \.self) { family in
                    Text(family).tag(family)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 260)

            MetricSlider(
                title: "Size",
                valueText: String(format: "%.0f pt", appearance.fontSize),
                value: $appearance.fontSize,
                range: 10...32,
                step: 1
            )

            Text("Preview: The quick brown fox jumps over 123")
                .font(Font(appearance.resolvedFont()))
                .padding(.top, 4)
        }
    }
}

private struct CursorSettingsSection: View {
    @ObservedObject private var appearance = TerminalAppearanceSettings.shared

    var body: some View {
        SettingsCard(
            title: "Cursor",
            subtitle: "Only styles that are currently rendered by the terminal view are shown."
        ) {
            Picker("Style", selection: $appearance.cursorStyle) {
                ForEach(CursorStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            Toggle("Blink cursor", isOn: $appearance.cursorBlink)
        }
    }
}

private struct ShellSettingsSection: View {
    @ObservedObject private var runtimeStore = RuntimeStatusStore.shared

    var body: some View {
        SettingsCard(
            title: "Shell Runtime",
            subtitle: "Seashell is preferred; fallback reason is shown when zsh is used instead."
        ) {
            runtimeRow("Active shell", runtimeStore.status.activeShell)
            runtimeRow("Active path", runtimeStore.status.activeShellPath)
            runtimeRow("Attempted path", runtimeStore.status.attemptedShellPath.isEmpty ? "n/a" : runtimeStore.status.attemptedShellPath)
            runtimeRow("Fallback reason", runtimeStore.status.fallbackReason.isEmpty ? "none" : runtimeStore.status.fallbackReason)
            runtimeRow("Seashell version", runtimeStore.status.seashellVersion)
            runtimeRow(
                "Last check",
                runtimeStore.status.checkedAt == .distantPast
                    ? "never"
                    : DateFormatter.localizedString(from: runtimeStore.status.checkedAt, dateStyle: .none, timeStyle: .medium)
            )
        }
    }

    private func runtimeRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct SessionSettingsSection: View {
    @AppStorage(TerminalViewModel.sessionAutoRestoreKey) private var autoRestoreEnabled = true

    private static let snapshotKey = "opal.session.snapshot.v1"

    var body: some View {
        SettingsCard(
            title: "Session Restore",
            subtitle: "Restore previous working directory and recent command context on launch."
        ) {
            Toggle("Restore previous session on startup", isOn: $autoRestoreEnabled)

            Button("Clear saved session snapshot") {
                UserDefaults.standard.removeObject(forKey: Self.snapshotKey)
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct AboutSettingsSection: View {
    var body: some View {
        SettingsCard(
            title: "About",
            subtitle: "Build information for support and debugging."
        ) {
            HStack {
                Text("Opal")
                Spacer()
                Text(opalVersion)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Shell Build")
                Spacer()
                Text("Seashell \(readBundledSeashellBuildVersion())")
                    .foregroundStyle(.secondary)
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
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MetricSlider: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

private struct EffectControlRow: View {
    let title: String
    @Binding var isEnabled: Bool
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueFormatter: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(title, isOn: $isEnabled)
            if isEnabled {
                MetricSlider(
                    title: "Intensity",
                    valueText: valueFormatter(value),
                    value: $value,
                    range: range,
                    step: step
                )
            }
        }
    }
}

private struct BackgroundEffectPreviewTile: View {
    @ObservedObject var profile: BackgroundProfile
    @State private var previewFocus: MetalLiquidGlassBackground.PreviewFocus = .none

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.2))

                LiquidGlassBackground(profile: profile, previewFocus: previewFocus)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.35), in: Capsule())
                    .padding(8)
            }
            .frame(height: 108)

            HStack(spacing: 8) {
                PreviewButton("Bloom") { runPreview(.bloom) }
                PreviewButton("Chromatic") { runPreview(.chromatic) }
                PreviewButton("Blur") { runPreview(.blur) }
                PreviewButton("All") { runPreview(.all) }
            }
            .disabled(!profile.useMetalShader)
        }
    }

    private var label: String {
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

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
    }
}
