import SwiftUI
import OpalCore

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            // General Tab
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            // Appearance Tab
            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            // Font Tab
            fontTab
                .tabItem {
                    Label("Font", systemImage: "textformat")
                }
            
            // AI Tab
            aiTab
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
            
            // Keybindings Tab
            keybindingsTab
                .tabItem {
                    Label("Keys", systemImage: "keyboard")
                }
        }
        .frame(width: 500, height: 400)
        .padding()
    }
    
    // MARK: - Tabs
    
    private var generalTab: some View {
        Form {
            Section("Terminal") {
                Picker("Cursor Style", selection: $viewModel.cursorStyle) {
                    Text("Block").tag(CursorStyleFfi.block)
                    Text("Underline").tag(CursorStyleFfi.underline)
                    Text("Line").tag(CursorStyleFfi.line)
                }
                .pickerStyle(.segmented)
                
                Toggle("Blinking Cursor", isOn: $viewModel.cursorBlinking)
                
                Stepper("Scrollback: \(viewModel.scrollback) lines", value: $viewModel.scrollback, in: 1000...50000, step: 1000)
            }
        }
    }
    
    private var appearanceTab: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $viewModel.theme) {
                    Text("Opal Dark").tag("opal-dark")
                    Text("Opal Light").tag("opal-light")
                    Text("Dracula").tag("dracula")
                    Text("Nord").tag("nord")
                }
            }
            
            Section("Window") {
                Slider(value: $viewModel.transparency, in: 0.5...1.0) {
                    Text("Transparency: \(Int(viewModel.transparency * 100))%")
                }
            }
        }
    }
    
    private var fontTab: some View {
        Form {
            Section("Font") {
                TextField("Font Family", text: $viewModel.fontFamily)
                
                Stepper("Size: \(Int(viewModel.fontSize))pt", value: $viewModel.fontSize, in: 8...72)
                
                Toggle("Enable Ligatures", isOn: $viewModel.fontLigatures)
            }
        }
    }
    
    private var aiTab: some View {
        Form {
            Section("AI Provider") {
                Toggle("Enable AI", isOn: $viewModel.aiEnabled)
                
                if viewModel.aiEnabled {
                    Picker("Provider", selection: $viewModel.aiProvider) {
                        Text("Ollama (Local)").tag("ollama")
                        Text("OpenRouter").tag("openrouter")
                        Text("OpenAI").tag("openai")
                        Text("Claude").tag("claude")
                    }
                    
                    TextField("Model", text: $viewModel.aiModel)
                    
                    if viewModel.aiProvider != "ollama" {
                        Text("Note: Set API key in environment variables")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var keybindingsTab: some View {
        Form {
            Section("General") {
                KeybindingRow(label: "New Tab", shortcut: viewModel.keybinding(for: "new_tab"))
                KeybindingRow(label: "Close Tab", shortcut: viewModel.keybinding(for: "close_tab"))
                KeybindingRow(label: "Next Tab", shortcut: viewModel.keybinding(for: "next_tab"))
                KeybindingRow(label: "Previous Tab", shortcut: viewModel.keybinding(for: "prev_tab"))
            }
            
            Section("Sidebar") {
                KeybindingRow(label: "AI Mode", shortcut: viewModel.keybinding(for: "ai_chat"))
                KeybindingRow(label: "Sessions Mode", shortcut: viewModel.keybinding(for: "sessions"))
                KeybindingRow(label: "Navigator Mode", shortcut: viewModel.keybinding(for: "navigator"))
                KeybindingRow(label: "History Mode", shortcut: viewModel.keybinding(for: "history"))
            }
        }
    }
}

// MARK: - Supporting Views

struct KeybindingRow: View {
    let label: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - View Model

class PreferencesViewModel: ObservableObject {
    private let configManager = ConfigManager()
    
    @Published var fontFamily: String = "SF Mono"
    @Published var fontSize: Float = 14.0
    @Published var fontLigatures: Bool = true
    @Published var theme: String = "opal-dark"
    @Published var transparency: Float = 0.85
    @Published var cursorStyle: CursorStyleFfi = .block
    @Published var cursorBlinking: Bool = true
    @Published var scrollback: UInt32 = 10000
    @Published var aiEnabled: Bool = true
    @Published var aiProvider: String = "ollama"
    @Published var aiModel: String = "codellama"
    
    private var keybindings: [String: String] = [:]
    
    init() {
        loadConfig()
    }
    
    func loadConfig() {
        let config = configManager.load()
        fontFamily = config.fontFamily
        fontSize = config.fontSize
        fontLigatures = config.fontLigatures
        theme = config.theme
        transparency = config.transparency
        cursorStyle = config.cursorStyle
        cursorBlinking = config.cursorBlinking
        scrollback = config.scrollback
        aiEnabled = config.aiEnabled
        aiProvider = config.aiProvider
        aiModel = config.aiModel
    }
    
    func saveConfig() {
        let config = ConfigFfi(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontLigatures: fontLigatures,
            theme: theme,
            transparency: transparency,
            cursorStyle: cursorStyle,
            cursorBlinking: cursorBlinking,
            scrollback: scrollback,
            aiEnabled: aiEnabled,
            aiProvider: aiProvider,
            aiModel: aiModel
        )
        let _ = configManager.save(config: config)
    }
    
    func keybinding(for action: String) -> String {
        return keybindings[action] ?? ""
    }
}
