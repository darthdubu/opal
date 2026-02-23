import SwiftUI
import OpalCore
import MetalKit

struct ContentView: View {
    @StateObject private var viewModel = TerminalViewModel()
    @State private var showSidebar = true
    @State private var showCommandPalette = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top toolbar with sidebar button and tabs
                HStack(spacing: 0) {
                    // Sidebar toggle button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSidebar.toggle()
                        }
                    }) {
                        Image(systemName: showSidebar ? "sidebar.left" : "sidebar.left")
                            .font(.system(size: 14))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                    
                    // Tab bar - fixed width for tabs
                    HStack(spacing: 4) {
                        Text("Terminal")
                            .font(.system(size: 12))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(6)
                            .fixedSize()
                        
                        Spacer()
                    }
                    .frame(height: 32)
                    .padding(.horizontal, 8)
                    
                    // New tab button
                    Button(action: { /* new tab - future implementation */ }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
                .frame(height: 38)
                .background(.ultraThinMaterial)
                
                // Main content area
                HStack(spacing: 0) {
                    // Sidebar - capped height, not under traffic lights
                    if showSidebar {
                        SidebarView(viewModel: viewModel)
                            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
                            .background(.ultraThinMaterial)
                            .transition(.move(edge: .leading))
                    }
                    
                    // Terminal area
                    TerminalContainerView(viewModel: viewModel)
                }
            }
        }
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
                showSidebar.toggle()
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
    @Published var refreshTrigger: Int = 0
    
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
            refreshTrigger += 1
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
            // Directory bar
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
                TerminalView(viewModel: viewModel, refreshTrigger: viewModel.refreshTrigger)
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
