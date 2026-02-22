import SwiftUI
import OpalCore

struct SettingsView: View {
    @StateObject private var backgroundSettings = BackgroundSettings.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // General Tab
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            // Appearance Tab
            AppearanceSettingsTab()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(1)
            
            // Background Effects Tab
            BackgroundEffectsTab()
                .tabItem {
                    Label("Background", systemImage: "wand.and.stars")
                }
                .tag(2)
            
            // Font Tab
            FontSettingsTab()
                .tabItem {
                    Label("Font", systemImage: "textformat")
                }
                .tag(3)
            
            // Cursor Tab
            CursorSettingsTab()
                .tabItem {
                    Label("Cursor", systemImage: "cursorarrow")
                }
                .tag(4)
            
            // AI Tab
            AISettingsTab()
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
                .tag(5)
            
            // Keybindings Tab
            KeybindingsSettingsTab()
                .tabItem {
                    Label("Keys", systemImage: "keyboard")
                }
                .tag(6)
            
            // Advanced Tab
            AdvancedSettingsTab()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
                .tag(7)
        }
        .frame(width: 700, height: 500)
        .padding()
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsTab: View {
    @State private var startupShell = "/bin/zsh"
    @State private var startupCommand = ""
    @State private var saveWindowSize = true
    @State private var confirmBeforeClosing = false
    @State private var scrollbackLines = 10000.0
    
    var body: some View {
        Form {
            Section("Startup") {
                Picker("Shell:", selection: $startupShell) {
                    Text("zsh").tag("/bin/zsh")
                    Text("bash").tag("/bin/bash")
                    Text("fish").tag("/usr/local/bin/fish")
                }
                .pickerStyle(.segmented)
                
                TextField("Startup command:", text: $startupCommand)
                    .textFieldStyle(.roundedBorder)
                
                Toggle("Save window size on exit", isOn: $saveWindowSize)
                Toggle("Confirm before closing", isOn: $confirmBeforeClosing)
            }
            
            Section("History & Scrollback") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scrollback lines: \(Int(scrollbackLines))")
                    Slider(value: $scrollbackLines, in: 1000...50000, step: 1000)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance Settings Tab

struct AppearanceSettingsTab: View {
    @State private var theme = "opal-dark"
    @State private var transparency = 0.9
    @State private var windowOpacity = 1.0
    @State private var blurRadius = 10.0
    
    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme:", selection: $theme) {
                    Text("Opal Dark").tag("opal-dark")
                    Text("Opal Light").tag("opal-light")
                    Text("Dracula").tag("dracula")
                    Text("Nord").tag("nord")
                    Text("Monokai").tag("monokai")
                    Text("Solarized Dark").tag("solarized-dark")
                    Text("Solarized Light").tag("solarized-light")
                }
                
                Button("Import Theme...") {}
                Button("Export Theme...") {}
            }
            
            Section("Window") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Window transparency: \(Int(transparency * 100))%")
                    Slider(value: $transparency, in: 0.5...1.0)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Background blur: \(Int(blurRadius))px")
                    Slider(value: $blurRadius, in: 0...30)
                }
                
                Toggle("Use system accent color", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Background Effects Tab

struct BackgroundEffectsTab: View {
    @StateObject private var settings = BackgroundSettings.shared
    
    var body: some View {
        ScrollView {
            Form {
                Section("Animation") {
                    Toggle("Enable wave animation", isOn: $settings.animationEnabled)
                    
                    if settings.animationEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary wave speed: \(String(format: "%.3f", settings.primaryWaveSpeed))")
                            Slider(value: $settings.primaryWaveSpeed, in: 0.001...0.1, step: 0.001)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Secondary wave speed: \(String(format: "%.3f", settings.secondaryWaveSpeed))")
                            Slider(value: $settings.secondaryWaveSpeed, in: 0.001...0.1, step: 0.001)
                        }
                    }
                }
                
                Section("Wave Colors") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary hue: \(Int(settings.primaryHue))°")
                        Slider(value: $settings.primaryHue, in: 0...360, step: 1)
                        ColorPreview(hue: settings.primaryHue)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Secondary hue: \(Int(settings.secondaryHue))°")
                        Slider(value: $settings.secondaryHue, in: 0...360, step: 1)
                        ColorPreview(hue: settings.secondaryHue)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wave count: \(settings.waveCount)")
                        Slider(value: .init(
                            get: { Double(settings.waveCount) },
                            set: { settings.waveCount = Int($0) }
                        ), in: 1...8, step: 1)
                    }
                }
                
                Section("Opacity") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary wave opacity: \(Int(settings.primaryWaveOpacity * 100))%")
                        Slider(value: $settings.primaryWaveOpacity, in: 0.01...0.3, step: 0.01)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Secondary wave opacity: \(Int(settings.secondaryWaveOpacity * 100))%")
                        Slider(value: $settings.secondaryWaveOpacity, in: 0.01...0.3, step: 0.01)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Background opacity: \(Int(settings.backgroundOpacity * 100))%")
                        Slider(value: $settings.backgroundOpacity, in: 0...0.5, step: 0.01)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Glass opacity: \(Int(settings.glassOpacity * 100))%")
                        Slider(value: $settings.glassOpacity, in: 0...0.5, step: 0.01)
                    }
                }
                
                Section("Effects") {
                    Toggle("Edge highlights", isOn: $settings.edgeHighlightsEnabled)
                    Toggle("Specular highlights", isOn: $settings.specularHighlightsEnabled)
                }
                
                Section("Presets") {
                    HStack {
                        Button("Ocean") { applyPreset(primaryHue: 200, secondaryHue: 240) }
                        Button("Sunset") { applyPreset(primaryHue: 20, secondaryHue: 340) }
                        Button("Forest") { applyPreset(primaryHue: 120, secondaryHue: 160) }
                        Button("Purple") { applyPreset(primaryHue: 270, secondaryHue: 300) }
                        Button("Mono") { applyPreset(primaryHue: 0, secondaryHue: 0) }
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
    
    private func applyPreset(primaryHue: Double, secondaryHue: Double) {
        settings.primaryHue = primaryHue
        settings.secondaryHue = secondaryHue
    }
}

struct ColorPreview: View {
    let hue: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(hue: hue / 360.0, saturation: 0.8, brightness: 0.9))
            .frame(height: 20)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Font Settings Tab

struct FontSettingsTab: View {
    @State private var fontFamily = "SF Mono"
    @State private var fontSize = 14.0
    @State private var lineHeight = 1.2
    @State private var letterSpacing = 0.0
    @State private var ligatures = true
    @State private var boldAsBright = true
    
    var body: some View {
        Form {
            Section("Font") {
                Picker("Font family:", selection: $fontFamily) {
                    Text("SF Mono").tag("SF Mono")
                    Text("Monaco").tag("Monaco")
                    Text("Menlo").tag("Menlo")
                    Text("JetBrains Mono").tag("JetBrains Mono")
                    Text("Fira Code").tag("Fira Code")
                    Text("Cascadia Code").tag("Cascadia Code")
                    Text("Source Code Pro").tag("Source Code Pro")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font size: \(Int(fontSize))pt")
                    Slider(value: $fontSize, in: 8...24, step: 1)
                }
                
                Toggle("Enable ligatures", isOn: $ligatures)
                Toggle("Render bold as bright", isOn: $boldAsBright)
            }
            
            Section("Spacing") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Line height: \(String(format: "%.1f", lineHeight))")
                    Slider(value: $lineHeight, in: 1.0...2.0, step: 0.1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Letter spacing: \(Int(letterSpacing))px")
                    Slider(value: $letterSpacing, in: -2...5, step: 1)
                }
            }
            
            Section("Preview") {
                FontPreviewView(
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                    lineHeight: lineHeight,
                    letterSpacing: letterSpacing,
                    ligatures: ligatures
                )
                .frame(height: 100)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .formStyle(.grouped)
    }
}

struct FontPreviewView: View {
    let fontFamily: String
    let fontSize: Double
    let lineHeight: Double
    let letterSpacing: Double
    let ligatures: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, World!")
            Text("!= <= >= =>")
            Text("0123456789")
        }
        .font(.custom(fontFamily, size: fontSize))
        .padding()
    }
}

// MARK: - Cursor Settings Tab

struct CursorSettingsTab: View {
    @State private var cursorStyle = 0
    @State private var cursorBlinking = true
    @State private var cursorBlinkInterval = 0.5
    @State private var cursorColor = Color.white
    @State private var useCustomCursorColor = false
    
    var body: some View {
        Form {
            Section("Cursor Style") {
                Picker("Style:", selection: $cursorStyle) {
                    Text("Block").tag(0)
                    Text("Underline").tag(1)
                    Text("Line").tag(2)
                }
                .pickerStyle(.segmented)
                
                Toggle("Blinking cursor", isOn: $cursorBlinking)
                
                if cursorBlinking {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blink interval: \(String(format: "%.1f", cursorBlinkInterval))s")
                        Slider(value: $cursorBlinkInterval, in: 0.1...1.0, step: 0.1)
                    }
                }
            }
            
            Section("Cursor Color") {
                Toggle("Use custom cursor color", isOn: $useCustomCursorColor)
                
                if useCustomCursorColor {
                    ColorPicker("Cursor color:", selection: $cursorColor)
                }
            }
            
            Section("Preview") {
                CursorPreview(style: cursorStyle, blinking: cursorBlinking, color: cursorColor)
                    .frame(height: 60)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .formStyle(.grouped)
    }
}

struct CursorPreview: View {
    let style: Int
    let blinking: Bool
    let color: Color
    
    @State private var visible = true
    
    var body: some View {
        HStack {
            Text("user@host:~$")
                .font(.system(.body, design: .monospaced))
            
            cursorView
                .onAppear {
                    if blinking {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                            visible.toggle()
                        }
                    }
                }
        }
        .padding()
    }
    
    @ViewBuilder
    var cursorView: some View {
        switch style {
        case 0:
            Rectangle()
                .fill(color)
                .frame(width: 8, height: 16)
                .opacity(visible ? 1 : 0)
        case 1:
            Rectangle()
                .fill(color)
                .frame(width: 8, height: 2)
                .opacity(visible ? 1 : 0)
        default:
            Rectangle()
                .fill(color)
                .frame(width: 2, height: 16)
                .opacity(visible ? 1 : 0)
        }
    }
}

// MARK: - AI Settings Tab

struct AISettingsTab: View {
    @State private var aiEnabled = true
    @State private var provider = "ollama"
    @State private var model = "codellama"
    @State private var apiKey = ""
    @State private var maxContextLines = 50.0
    @State private var temperature = 0.7
    
    var body: some View {
        Form {
            Section("AI Provider") {
                Toggle("Enable AI features", isOn: $aiEnabled)
                
                if aiEnabled {
                    Picker("Provider:", selection: $provider) {
                        Text("Ollama (Local)").tag("ollama")
                        Text("OpenRouter").tag("openrouter")
                        Text("OpenAI").tag("openai")
                        Text("Claude").tag("claude")
                        Text("Codex").tag("codex")
                    }
                    
                    TextField("Model:", text: $model)
                    
                    if provider != "ollama" {
                        SecureField("API Key:", text: $apiKey)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Temperature: \(String(format: "%.1f", temperature))")
                        Slider(value: $temperature, in: 0...1, step: 0.1)
                    }
                }
            }
            
            Section("Context") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Max context lines: \(Int(maxContextLines))")
                    Slider(value: $maxContextLines, in: 10...200, step: 10)
                }
                
                Toggle("Include git status", isOn: .constant(true))
                Toggle("Include current directory", isOn: .constant(true))
                Toggle("Include recent commands", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Keybindings Settings Tab

struct KeybindingsSettingsTab: View {
    @State private var keybindings: [(String, String)] = [
        ("New Tab", "Cmd+T"),
        ("Close Tab", "Cmd+W"),
        ("Next Tab", "Cmd+Shift+]"),
        ("Previous Tab", "Cmd+Shift+["),
        ("Command Palette", "Cmd+Shift+P"),
        ("AI Chat", "Cmd+1"),
        ("Sessions", "Cmd+2"),
        ("Navigator", "Cmd+3"),
        ("History", "Cmd+4"),
        ("Settings", "Cmd+,"),
    ]
    
    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                ForEach(keybindings.indices, id: \.self) { index in
                    HStack {
                        Text(keybindings[index].0)
                        Spacer()
                        Text(keybindings[index].1)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Button("Reset to Defaults") {}
                Button("Import Keybindings...") {}
                Button("Export Keybindings...") {}
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Advanced Settings Tab

struct AdvancedSettingsTab: View {
    @State private var gpuAcceleration = true
    @State private var vsync = true
    @State private var frameRate = 60.0
    @State private var debugMode = false
    @State private var logLevel = 0
    
    var body: some View {
        Form {
            Section("Performance") {
                Toggle("GPU acceleration", isOn: $gpuAcceleration)
                Toggle("VSync", isOn: $vsync)
                
                if !vsync {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target frame rate: \(Int(frameRate)) FPS")
                        Slider(value: $frameRate, in: 30...144, step: 1)
                    }
                }
            }
            
            Section("Developer") {
                Toggle("Debug mode", isOn: $debugMode)
                
                Picker("Log level:", selection: $logLevel) {
                    Text("Error").tag(0)
                    Text("Warning").tag(1)
                    Text("Info").tag(2)
                    Text("Debug").tag(3)
                    Text("Trace").tag(4)
                }
                
                Button("Open Log Directory...") {}
                Button("Reset All Settings") {}
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.1")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2025.02.22")
                        .foregroundStyle(.secondary)
                }
                
                Link("Website", destination: URL(string: "https://opal.sh")!)
                Link("GitHub", destination: URL(string: "https://github.com/opal-terminal/opal")!)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
