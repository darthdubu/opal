import SwiftUI
import OpalCore

struct SettingsView: View {
    @State private var selectedCategory: SettingsCategory = .general
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCategory) {
                Section {
                    SettingsCategoryButton(category: .general, icon: "gear", title: "General")
                    SettingsCategoryButton(category: .appearance, icon: "paintbrush", title: "Appearance")
                    SettingsCategoryButton(category: .background, icon: "wand.and.stars", title: "Background")
                    SettingsCategoryButton(category: .font, icon: "textformat", title: "Font")
                    SettingsCategoryButton(category: .cursor, icon: "cursorarrow", title: "Cursor")
                    SettingsCategoryButton(category: .ai, icon: "brain", title: "AI")
                    SettingsCategoryButton(category: .keys, icon: "keyboard", title: "Keys")
                    SettingsCategoryButton(category: .advanced, icon: "gearshape.2", title: "Advanced")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .frame(minWidth: 200)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(selectedCategory.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    Divider()
                    
                    settingsContent
                        .padding(20)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    @ViewBuilder
    var settingsContent: some View {
        switch selectedCategory {
        case .general:
            GeneralSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .background:
            BackgroundSettingsView()
        case .font:
            FontSettingsView()
        case .cursor:
            CursorSettingsView()
        case .ai:
            AISettingsView()
        case .keys:
            KeysSettingsView()
        case .advanced:
            AdvancedSettingsView()
        }
    }
}

enum SettingsCategory: String, CaseIterable, Identifiable, Hashable {
    case general, appearance, background, font, cursor, ai, keys, advanced
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general: return "General"
        case .appearance: return "Appearance"
        case .background: return "Background"
        case .font: return "Font"
        case .cursor: return "Cursor"
        case .ai: return "AI"
        case .keys: return "Keyboard"
        case .advanced: return "Advanced"
        }
    }
}

struct SettingsCategoryButton: View {
    let category: SettingsCategory
    let icon: String
    let title: String
    
    var body: some View {
        Label(title, systemImage: icon)
            .tag(category)
    }
}

struct GeneralSettingsView: View {
    @State private var shell = "/bin/zsh"
    @State private var startupCommand = ""
    @State private var saveWindowSize = true
    @State private var confirmBeforeClosing = false
    @State private var scrollbackLines = 10000.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Shell")
                    .font(.headline)
                
                Picker("Shell:", selection: $shell) {
                    Text("zsh").tag("/bin/zsh")
                    Text("bash").tag("/bin/bash")
                    Text("fish").tag("/usr/local/bin/fish")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Startup")
                    .font(.headline)
                
                HStack {
                    Text("Startup command:")
                        .frame(width: 140, alignment: .leading)
                    TextField("", text: $startupCommand)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                }
                
                Toggle("Save window size on exit", isOn: $saveWindowSize)
                Toggle("Confirm before closing", isOn: $confirmBeforeClosing)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("History & Scrollback")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scrollback lines: \(Int(scrollbackLines))")
                        .font(.subheadline)
                    Slider(value: $scrollbackLines, in: 1000...50000, step: 1000)
                        .frame(maxWidth: 400)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppearanceSettingsView: View {
    @State private var theme = "opal-dark"
    @StateObject private var windowSettings = WindowSettings.shared
    @State private var blurRadius = 10.0
    
    let themes = [
        ("Opal Dark", "opal-dark"),
        ("Opal Light", "opal-light"),
        ("Dracula", "dracula"),
        ("Nord", "nord"),
        ("Monokai", "monokai"),
        ("Solarized Dark", "solarized-dark"),
        ("Solarized Light", "solarized-light")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                    ForEach(themes, id: \.1) { name, id in
                        ThemeButton(name: name, isSelected: theme == id) {
                            theme = id
                        }
                    }
                }
                .frame(maxWidth: 400)
                
                HStack {
                    Button("Import Theme...") {}
                    Button("Export Theme...") {}
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Window")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Background Opacity")
                            .frame(width: 140, alignment: .leading)
                        Text("\(Int(windowSettings.backgroundOpacity * 100))%")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    Slider(value: $windowSettings.backgroundOpacity, in: 0.0...1.0)
                        .frame(maxWidth: 300)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Blur radius")
                            .frame(width: 100, alignment: .leading)
                        Text("\(Int(blurRadius))px")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    Slider(value: $blurRadius, in: 0...30)
                        .frame(maxWidth: 300)
                }
                
                Toggle("Use system accent color", isOn: .constant(true))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ThemeButton: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                
                Text(name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct BackgroundSettingsView: View {
    @StateObject private var settings = BackgroundSettings.shared
    @State private var primaryColor: Color = Color(hue: 210 / 360.0, saturation: 0.8, brightness: 0.9)
    @State private var secondaryColor: Color = Color(hue: 260 / 360.0, saturation: 0.8, brightness: 0.9)
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Animation")
                    .font(.headline)
                
                Toggle("Enable wave animation", isOn: $settings.animationEnabled)
                Toggle("Use Metal shaders (GPU accelerated)", isOn: $settings.useMetalShader)
                
                if settings.animationEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Primary speed")
                                .frame(width: 120, alignment: .leading)
                            Text(String(format: "%.3f", settings.primaryWaveSpeed))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Slider(value: $settings.primaryWaveSpeed, in: 0.001...0.1, step: 0.001)
                            .frame(maxWidth: 300)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Secondary speed")
                                .frame(width: 120, alignment: .leading)
                            Text(String(format: "%.3f", settings.secondaryWaveSpeed))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Slider(value: $settings.secondaryWaveSpeed, in: 0.001...0.1, step: 0.001)
                            .frame(maxWidth: 300)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Wave Colors")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Primary hue")
                            .frame(width: 100, alignment: .leading)
                        Text("\(Int(settings.primaryHue))°")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    HStack {
                        Slider(value: $settings.primaryHue, in: 0...360, step: 1)
                            .frame(width: 280)
                        ColorPreview(hue: settings.primaryHue)
                            .frame(width: 40, height: 24)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Secondary hue")
                            .frame(width: 100, alignment: .leading)
                        Text("\(Int(settings.secondaryHue))°")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    HStack {
                        Slider(value: $settings.secondaryHue, in: 0...360, step: 1)
                            .frame(width: 280)
                        ColorPreview(hue: settings.secondaryHue)
                            .frame(width: 40, height: 24)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Wave count")
                            .frame(width: 100, alignment: .leading)
                        Text("\(settings.waveCount)")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    Slider(value: .init(
                        get: { Double(settings.waveCount) },
                        set: { settings.waveCount = Int($0) }
                    ), in: 1...8, step: 1)
                    .frame(maxWidth: 300)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Custom Colors")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Color")
                                .font(.subheadline)
                            ColorPicker("", selection: $primaryColor)
                                .labelsHidden()
                                .frame(width: 60, height: 40)
                                .onChange(of: primaryColor) { _, newColor in
                                    settings.primaryHue = colorToHue(newColor)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Secondary Color")
                                .font(.subheadline)
                            ColorPicker("", selection: $secondaryColor)
                                .labelsHidden()
                                .frame(width: 60, height: 40)
                                .onChange(of: secondaryColor) { _, newColor in
                                    settings.secondaryHue = colorToHue(newColor)
                                }
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    Text("Quick Presets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                        PresetButton(name: "Ocean", colors: [Color.cyan, Color.blue]) {
                            applyPreset(primaryHue: 200, secondaryHue: 240)
                        }
                        PresetButton(name: "Sunset", colors: [Color.orange, Color.pink]) {
                            applyPreset(primaryHue: 20, secondaryHue: 340)
                        }
                        PresetButton(name: "Forest", colors: [Color.green, Color.teal]) {
                            applyPreset(primaryHue: 120, secondaryHue: 160)
                        }
                        PresetButton(name: "Purple", colors: [Color.purple, Color.indigo]) {
                            applyPreset(primaryHue: 270, secondaryHue: 300)
                        }
                    }
                }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Advanced Metal Effects")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Bloom (glow effect)", isOn: $settings.bloomEnabled)
                    
                    if settings.bloomEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Bloom strength")
                                    .frame(width: 120, alignment: .leading)
                                Text(String(format: "%.2f", settings.bloomStrength))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            Slider(value: $settings.bloomStrength, in: 0.1...1.0, step: 0.1)
                                .frame(maxWidth: 300)
                        }
                    }
                    
                    Toggle("Chromatic Aberration", isOn: $settings.chromaticAberrationEnabled)
                    
                    if settings.chromaticAberrationEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("CA strength")
                                    .frame(width: 120, alignment: .leading)
                                Text(String(format: "%.3f", settings.chromaticAberrationStrength))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            Slider(value: $settings.chromaticAberrationStrength, in: 0.001...0.01, step: 0.001)
                                .frame(maxWidth: 300)
                        }
                    }
                    
                    Toggle("Gaussian Blur", isOn: $settings.blurEnabled)
                    
                    if settings.blurEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Blur radius")
                                    .frame(width: 120, alignment: .leading)
                                Text(String(format: "%.3f", settings.blurRadius))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            Slider(value: $settings.blurRadius, in: 0.001...0.01, step: 0.001)
                                .frame(maxWidth: 300)
                        }
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func applyPreset(primaryHue: Double, secondaryHue: Double) {
        settings.primaryHue = primaryHue
        settings.secondaryHue = secondaryHue
        primaryColor = Color(hue: primaryHue / 360.0, saturation: 0.8, brightness: 0.9)
        secondaryColor = Color(hue: secondaryHue / 360.0, saturation: 0.8, brightness: 0.9)
    }
    
    private func colorToHue(_ color: Color) -> Double {
        let uiColor = NSColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Double(hue * 360.0)
}

struct ColorPreview: View {
    let hue: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(hue: hue / 360.0, saturation: 0.8, brightness: 0.9))
    }
}

struct PresetButton: View {
    let name: String
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: 60, height: 30)
                Text(name)
                    .font(.caption2)
            }
        }
        .buttonStyle(.plain)
    }
}

struct FontSettingsView: View {
    @State private var fontFamily = "SF Mono"
    @State private var fontSize = 14.0
    @State private var lineHeight = 1.2
    @State private var letterSpacing = 0.0
    @State private var ligatures = true
    @State private var boldAsBright = true
    
    let fonts = ["SF Mono", "Monaco", "Menlo", "JetBrains Mono", "Fira Code", "Cascadia Code"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Font Family")
                    .font(.headline)
                
                Picker("", selection: $fontFamily) {
                    ForEach(fonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Size")
                            .frame(width: 60, alignment: .leading)
                        Text("\(Int(fontSize))pt")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    Slider(value: $fontSize, in: 8...24, step: 1)
                        .frame(maxWidth: 200)
                }
                
                Toggle("Enable ligatures", isOn: $ligatures)
                Toggle("Render bold as bright", isOn: $boldAsBright)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Spacing")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Line height")
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "%.1f", lineHeight))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    Slider(value: $lineHeight, in: 1.0...2.0, step: 0.1)
                        .frame(maxWidth: 200)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Letter spacing")
                            .frame(width: 100, alignment: .leading)
                        Text("\(Int(letterSpacing))px")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    Slider(value: $letterSpacing, in: -2...5, step: 1)
                        .frame(maxWidth: 200)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Preview")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, World!")
                    Text("!= <= >= =>")
                    Text("0123456789")
                }
                .font(.custom(fontFamily, size: fontSize))
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: 400)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CursorSettingsView: View {
    @State private var cursorStyle = 0
    @State private var cursorBlinking = true
    @State private var cursorBlinkInterval = 0.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cursor Style")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    CursorStyleButton(
                        title: "Block",
                        isSelected: cursorStyle == 0
                    ) { cursorStyle = 0 }
                    
                    CursorStyleButton(
                        title: "Underline", 
                        isSelected: cursorStyle == 1
                    ) { cursorStyle = 1 }
                    
                    CursorStyleButton(
                        title: "Line",
                        isSelected: cursorStyle == 2
                    ) { cursorStyle = 2 }
                }
                
                Toggle("Blinking cursor", isOn: $cursorBlinking)
                
                if cursorBlinking {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Blink interval")
                                .frame(width: 100, alignment: .leading)
                            Text("\(String(format: "%.1f", cursorBlinkInterval))s")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Slider(value: $cursorBlinkInterval, in: 0.1...1.0, step: 0.1)
                            .frame(maxWidth: 200)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CursorStyleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.accentColor : Color.gray, lineWidth: isSelected ? 0 : 1)
                    )
                Text(title)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }
}

struct AISettingsView: View {
    @State private var aiEnabled = true
    @State private var provider = "ollama"
    @State private var model = "codellama"
    @State private var apiKey = ""
    @State private var temperature = 0.7
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Provider")
                    .font(.headline)
                
                Toggle("Enable AI features", isOn: $aiEnabled)
                
                if aiEnabled {
                    Picker("Provider:", selection: $provider) {
                        Text("Ollama (Local)").tag("ollama")
                        Text("OpenRouter").tag("openrouter")
                        Text("OpenAI").tag("openai")
                        Text("Claude").tag("claude")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                    
                    HStack {
                        Text("Model:")
                            .frame(width: 80, alignment: .leading)
                        TextField("", text: $model)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                    }
                    
                    if provider != "ollama" {
                        HStack {
                            Text("API Key:")
                                .frame(width: 80, alignment: .leading)
                            SecureField("", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 300)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                                .frame(width: 100, alignment: .leading)
                            Text("\(String(format: "%.1f", temperature))")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Slider(value: $temperature, in: 0...1, step: 0.1)
                            .frame(maxWidth: 200)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct KeysSettingsView: View {
    let shortcuts = [
        ("New Tab", "Cmd+T"),
        ("Close Tab", "Cmd+W"),
        ("Next Tab", "Cmd+Shift+]"),
        ("Previous Tab", "Cmd+Shift+["),
        ("Command Palette", "Cmd+Shift+P"),
        ("AI Chat", "Cmd+1"),
        ("Settings", "Cmd+,"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Keyboard Shortcuts")
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(shortcuts, id: \.0) { name, shortcut in
                    HStack {
                        Text(name)
                        Spacer()
                        Text(shortcut)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    if name != shortcuts.last?.0 {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Button("Reset to Defaults") {}
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AdvancedSettingsView: View {
    @State private var gpuAcceleration = true
    @State private var debugMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance")
                    .font(.headline)
                
                Toggle("GPU acceleration", isOn: $gpuAcceleration)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Developer")
                    .font(.headline)
                
                Toggle("Debug mode", isOn: $debugMode)
                
                Button("Open Log Directory...") {}
                
                Button("Reset All Settings") {}
                    .foregroundStyle(.red)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("About")
                    .font(.headline)
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.5")
                        .foregroundStyle(.secondary)
                }
                
                Link("Website", destination: URL(string: "https://opal.sh")!)
                Link("GitHub", destination: URL(string: "https://github.com/opal-terminal/opal")!)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SettingsView()
}
