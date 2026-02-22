import SwiftUI
import OpalCore
import MetalKit

struct ContentView: View {
    @StateObject private var viewModel = TerminalViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showCommandPalette = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 400)
        } detail: {
            TerminalContainerView(viewModel: viewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView(viewModel: viewModel)
        }
        .background(TransparentWindow())
        .onAppear {
            viewModel.startSession()
            setupNotifications()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .toggleSidebar,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation {
                switch columnVisibility {
                case .all:
                    columnVisibility = .detailOnly
                case .detailOnly, .doubleColumn, .automatic:
                    columnVisibility = .all
                default:
                    columnVisibility = .all
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .showCommandPalette,
            object: nil,
            queue: .main
        ) { _ in
            showCommandPalette = true
        }
        
        NotificationCenter.default.addObserver(
            forName: .clearScreen,
            object: nil,
            queue: .main
        ) { _ in
            viewModel.clearScreen()
        }
    }
}

class TerminalViewModel: ObservableObject {
    @Published var terminalHandle: TerminalHandle?
    @Published var ptySession: PtySession?
    @Published var currentDirectory: String = "~"
    @Published var gitInfo: GitInfo?
    
    private var timer: Timer?
    private let gitManager = GitManager()
    
    func startSession() {
        do {
            let pty = try PtySession(cols: 80, rows: 24)
            self.ptySession = pty
            self.terminalHandle = pty.getTerminal()
            startReadingOutput()
        } catch {
            print("Failed to start session: \(error)")
        }
    }
    
    func clearScreen() {
        let clearCommand = "\u{001B}[2J\u{001B}[H"
        sendInput(clearCommand)
    }
    
    private func startReadingOutput() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.readOutput()
        }
    }
    
    private func readOutput() {
        guard let pty = ptySession else { return }
        let data = pty.read()
        if !data.isEmpty {
            terminalHandle?.processInput(data: data)
            objectWillChange.send()
        }
    }
    
    func sendInput(_ string: String) {
        guard let pty = ptySession else { return }
        if let data = string.data(using: .utf8) {
            pty.write(data: data)
        }
    }
    
    func updateGitInfo(for path: String) {
        gitInfo = gitManager.getInfo(path: path)
    }
}

struct TerminalContainerView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @FocusState private var isTerminalFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.currentDirectory)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            
            ZStack {
                LiquidGlassBackground()
                TerminalView(viewModel: viewModel)
                    .focused($isTerminalFocused)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTerminalFocused = true
            }
        }
    }
}

struct CommandPaletteView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @State private var searchQuery = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Search commands...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            List {
                Text("Recent Commands")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 600, height: 400)
    }
}
