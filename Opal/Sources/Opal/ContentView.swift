import SwiftUI
import OpalCore
import AppKit

private struct TerminalSessionTab: Identifiable {
    let id: UUID
    let viewModel: TerminalViewModel

    init(id: UUID = UUID(), viewModel: TerminalViewModel = TerminalViewModel()) {
        self.id = id
        self.viewModel = viewModel
    }
}

struct ContentView: View {
    @State private var tabs: [TerminalSessionTab] = [TerminalSessionTab()]
    @State private var selectedTabID: UUID?
    @State private var startedTabIDs: Set<UUID> = []
    @AppStorage("opal.sidebar.visible") private var showSidebar = true
    @State private var sidebarWidth: CGFloat = 340
    @State private var showCommandPalette = false
    @State private var didSetupNotifications = false

    private var selectedTab: TerminalSessionTab {
        if let selectedTabID,
           let tab = tabs.first(where: { $0.id == selectedTabID }) {
            return tab
        }
        return tabs[0]
    }

    private var activeViewModel: TerminalViewModel {
        selectedTab.viewModel
    }

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSidebar.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)

                    Spacer(minLength: 8)

                    ToolbarSessionRestoreButton(viewModel: activeViewModel)

                    ToolbarShellBadge(viewModel: activeViewModel) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSidebar = true
                        }
                        NotificationCenter.default.post(name: .showShellDiagnostics, object: nil)
                    }
                    .padding(.trailing, 10)
                }
                .frame(height: 40)
                .background(.ultraThinMaterial)

                if tabs.count > 1 {
                    TabStripView(
                        tabs: tabs,
                        selectedTabID: $selectedTabID,
                        onCloseTab: closeTab
                    )
                    .frame(height: 34)
                    .background(.ultraThinMaterial)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HStack(spacing: 0) {
                    SidebarView(viewModel: activeViewModel)
                        .frame(width: sidebarWidth)
                        .background(.ultraThinMaterial)
                        .opacity(showSidebar ? 1 : 0)
                        .frame(maxWidth: showSidebar ? sidebarWidth : 0, alignment: .leading)
                        .clipped()
                        .animation(.easeInOut(duration: 0.2), value: showSidebar)

                    TerminalContainerView(viewModel: activeViewModel)
                }
            }
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView(viewModel: activeViewModel)
        }
        .background(Color.clear)
        .background(WindowAccessor { window in
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.hasShadow = true

            if let contentView = window.contentView {
                contentView.wantsLayer = true
                contentView.layer?.isOpaque = false
                contentView.layer?.backgroundColor = NSColor.clear.cgColor
            }

            if let frameView = window.contentView?.superview {
                frameView.wantsLayer = true
                frameView.layer?.backgroundColor = NSColor.clear.cgColor
            }
        })
        .onAppear {
            if !didSetupNotifications {
                setupNotifications()
                didSetupNotifications = true
            }
            selectedTabID = tabs.first?.id
            startSessionIfNeeded(for: selectedTab)
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .toggleSidebar,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
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
            activeViewModel.clearScreen()
        }

        NotificationCenter.default.addObserver(
            forName: .restoreSession,
            object: nil,
            queue: .main
        ) { _ in
            activeViewModel.restoreSession(manual: true)
        }

        NotificationCenter.default.addObserver(
            forName: .newTab,
            object: nil,
            queue: .main
        ) { _ in
            addNewTab()
        }

        NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { _ in
            closeActiveTab()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            for tab in tabs {
                tab.viewModel.syncPreferencesFromDefaults()
                tab.viewModel.refreshShellRuntime(force: true)
                tab.viewModel.syncShellHistory(force: true)
                tab.viewModel.updateGitInfo(for: tab.viewModel.currentDirectory)
            }
        }
    }

    private func startSessionIfNeeded(for tab: TerminalSessionTab) {
        if startedTabIDs.contains(tab.id) {
            return
        }
        tab.viewModel.startSession()
        startedTabIDs.insert(tab.id)
    }

    private func addNewTab() {
        let tab = TerminalSessionTab()
        tabs.append(tab)
        selectedTabID = tab.id
        startSessionIfNeeded(for: tab)
    }

    private func closeActiveTab() {
        guard tabs.count > 1 else {
            return
        }

        guard let selectedTabID else {
            tabs.removeLast()
            self.selectedTabID = tabs.last?.id
            return
        }

        guard let currentIndex = tabs.firstIndex(where: { $0.id == selectedTabID }) else {
            tabs.removeLast()
            self.selectedTabID = tabs.last?.id
            return
        }

        tabs.remove(at: currentIndex)
        startedTabIDs.remove(selectedTabID)

        let nextIndex = min(currentIndex, tabs.count - 1)
        self.selectedTabID = tabs[nextIndex].id
    }

    private func closeTab(id: UUID) {
        guard tabs.count > 1 else {
            return
        }
        guard let index = tabs.firstIndex(where: { $0.id == id }) else {
            return
        }

        let wasSelected = id == selectedTabID
        tabs.remove(at: index)
        startedTabIDs.remove(id)

        if wasSelected {
            let nextIndex = min(index, tabs.count - 1)
            selectedTabID = tabs[nextIndex].id
        }
    }
}

private struct TabStripView: View {
    let tabs: [TerminalSessionTab]
    @Binding var selectedTabID: UUID?
    let onCloseTab: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                    tabButton(for: tab, index: index)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
    }

    private func tabButton(for tab: TerminalSessionTab, index: Int) -> some View {
        let selected = tab.id == selectedTabID
        let title = tabTitle(for: tab, index: index)

        return HStack(spacing: 6) {
            Button(action: {
                selectedTabID = tab.id
            }) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(selected ? Color.accentColor.opacity(0.26) : Color.gray.opacity(0.14))
                    )
            }
            .buttonStyle(.plain)

            Button(action: {
                onCloseTab(tab.id)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
        }
    }

    private func tabTitle(for tab: TerminalSessionTab, index: Int) -> String {
        let directoryName = URL(fileURLWithPath: tab.viewModel.currentDirectory).lastPathComponent
        if directoryName.isEmpty {
            return "Tab \(index + 1)"
        }
        return directoryName
    }
}

private struct ToolbarSessionRestoreButton: View {
    @ObservedObject var viewModel: TerminalViewModel

    var body: some View {
        Button(action: {
            viewModel.restoreSession(manual: true)
        }) {
            Label("Restore", systemImage: "arrow.clockwise")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.hasSavedSession)
        .opacity(viewModel.hasSavedSession ? 1.0 : 0.45)
        .help("Restore previous directory and recent command context")
    }
}

struct ToolbarShellBadge: View {
    @ObservedObject var viewModel: TerminalViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.shellBadgeColor)
                    .frame(width: 7, height: 7)
                Text(viewModel.shellBadgeText)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.gray.opacity(0.18), in: Capsule())
        }
        .buttonStyle(.plain)
        .help(viewModel.shellDiagnosticsText)
    }
}

final class TerminalViewModel: ObservableObject {
    @Published var terminalHandle: TerminalHandle?
    @Published var ptySession: PtySession?
    @Published var currentDirectory: String = FileManager.default.currentDirectoryPath
    @Published var gitInfo: GitInfo?
    @Published var gitChangedFiles: [GitChangedFile] = []
    @Published var refreshTrigger: Int = 0
    @Published var sessionHistory: [String] = []
    @Published var shellHistory: [String] = []

    @Published var activeShell: String = "zsh"
    @Published var activeShellPath: String = "/bin/zsh"
    @Published var attemptedShellPath: String = ""
    @Published var shellFallbackReason: String = ""
    @Published var seashellVersion: String = ""
    @Published var shellStatusCheckedAt: Date = .distantPast
    @Published var shellBuildVersion: String = TerminalViewModel.readBundledSeashellVersion()

    @Published var preferredEditor: String = "micro"
    @Published var preferredEditorAvailable: Bool = true
    @Published var editorStatusMessage: String = ""

    @Published var hasSavedSession = false
    @Published var sessionRestoreStatus: String = ""

    private var timer: Timer?
    private let gitManager = GitManager()
    private var pendingCommandBuffer = ""
    private var lastShellStatusRefresh = Date.distantPast
    private var lastHistorySync = Date.distantPast
    private var historySyncInFlight = false

    private static let sessionSnapshotKey = "opal.session.snapshot.v1"
    private static let defaultEditorKey = "opal.default.editor"
    private static let sessionAutoRestoreKey = "opal.session.autorestore"

    private struct SessionSnapshot: Codable {
        let currentDirectory: String
        let recentCommands: [String]
        let preferredEditor: String
        let savedAt: TimeInterval
    }

    init() {
        syncPreferencesFromDefaults()
        hasSavedSession = Self.loadSessionSnapshot() != nil
    }

    deinit {
        timer?.invalidate()
    }

    var shellBadgeText: String {
        activeShell.lowercased().contains("sea") ? "Sea" : "zsh"
    }

    var shellBadgeColor: Color {
        shellFallbackReason.isEmpty ? Color.green.opacity(0.82) : Color.orange.opacity(0.9)
    }

    var shellDiagnosticsText: String {
        let checked = shellStatusCheckedAt == .distantPast
            ? "never"
            : DateFormatter.localizedString(from: shellStatusCheckedAt, dateStyle: .none, timeStyle: .medium)
        let reason = shellFallbackReason.isEmpty ? "none" : shellFallbackReason
        let version = seashellVersion.isEmpty ? shellBuildVersion : seashellVersion
        return "Shell: \(activeShell)\nReason: \(reason)\nAttempted path: \(attemptedShellPath.isEmpty ? "n/a" : attemptedShellPath)\nSeashell version: \(version.isEmpty ? "unavailable" : version)\nLast check: \(checked)"
    }

    func startSession() {
        syncPreferencesFromDefaults()

        if let bundledShellPath = Bundle.main.resourceURL?
            .appendingPathComponent("seashell/sea")
            .path,
           FileManager.default.isExecutableFile(atPath: bundledShellPath) {
            setenv("OPAL_BUNDLED_SEASHELL", bundledShellPath, 1)
        }

        if let bundledLibPath = Bundle.main.resourceURL?
            .appendingPathComponent("seashell/lib")
            .path,
           FileManager.default.fileExists(atPath: bundledLibPath) {
            setenv("OPAL_BUNDLED_SEASHELL_LIB", bundledLibPath, 1)
        }

        let autoRestoreEnabled = Self.isAutoRestoreEnabled()
        if let snapshot = Self.loadSessionSnapshot() {
            hasSavedSession = true
            if autoRestoreEnabled {
                currentDirectory = snapshot.currentDirectory
                preferredEditor = snapshot.preferredEditor.isEmpty ? preferredEditor : snapshot.preferredEditor
                sessionHistory = snapshot.recentCommands
                validatePreferredEditorAvailability()
            }
        }

        let pty = PtySession(cols: 80, rows: 24)
        ptySession = pty
        terminalHandle = pty.getTerminal()

        updateGitInfo(for: currentDirectory)
        refreshShellRuntime(force: true)
        syncShellHistory(force: true)
        startReadingOutput()

        if hasSavedSession && autoRestoreEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                self?.restoreSession(manual: false)
            }
        }
    }

    func clearScreen() {
        sendInput("\u{001B}[2J\u{001B}[H")
    }

    func restoreSession(manual: Bool) {
        guard let snapshot = Self.loadSessionSnapshot() else {
            hasSavedSession = false
            if manual {
                sessionRestoreStatus = "No saved session found."
            }
            return
        }

        hasSavedSession = true
        if !snapshot.preferredEditor.isEmpty && snapshot.preferredEditor != preferredEditor {
            preferredEditor = snapshot.preferredEditor
            validatePreferredEditorAvailability()
        }

        var merged = [String]()
        merged.reserveCapacity(snapshot.recentCommands.count + sessionHistory.count)
        merged.append(contentsOf: snapshot.recentCommands)
        merged.append(contentsOf: sessionHistory)

        var seen = Set<String>()
        var deduped = [String]()
        for command in merged where seen.insert(command).inserted {
            deduped.append(command)
        }
        sessionHistory = Array(deduped.prefix(200))

        if !snapshot.currentDirectory.isEmpty,
           FileManager.default.fileExists(atPath: snapshot.currentDirectory) {
            currentDirectory = snapshot.currentDirectory
            sendInput("cd \(Self.shellQuote(snapshot.currentDirectory))\r")
            updateGitInfo(for: snapshot.currentDirectory)
        }

        if manual {
            let restoredAt = Date(timeIntervalSince1970: snapshot.savedAt)
            let stamp = DateFormatter.localizedString(from: restoredAt, dateStyle: .none, timeStyle: .short)
            sessionRestoreStatus = "Restored session saved at \(stamp)."
        }
    }

    func setPreferredEditor(_ editor: String) {
        let trimmed = editor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        preferredEditor = trimmed
        UserDefaults.standard.set(trimmed, forKey: Self.defaultEditorKey)
        validatePreferredEditorAvailability()
        persistSessionSnapshot()
    }

    func syncPreferencesFromDefaults() {
        let editor = UserDefaults.standard.string(forKey: Self.defaultEditorKey) ?? "micro"
        if editor != preferredEditor {
            preferredEditor = editor
        }
        validatePreferredEditorAvailability()
    }

    func openFileInPreferredEditor(_ path: String) {
        let editor = preferredEditor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !editor.isEmpty else {
            editorStatusMessage = "Set a default editor first."
            return
        }

        guard FileManager.default.fileExists(atPath: path) else {
            editorStatusMessage = "File no longer exists: \(path)"
            return
        }

        if Self.isEditorAvailable(editor) {
            let command = "\(editor) \(Self.shellQuote(path))"
            sendInput(command + "\r")
            addSessionHistory(command)
            editorStatusMessage = ""
        } else {
            editorStatusMessage = Self.installHint(for: editor)
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }

    func openDirectoryInFinder(_ path: String) {
        guard FileManager.default.fileExists(atPath: path) else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    private func startReadingOutput() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.readOutput()
        }
    }

    private func readOutput() {
        guard let pty = ptySession, let terminalHandle = terminalHandle else { return }

        let data = pty.read()
        if !data.isEmpty {
            let responses = terminalHandle.processInputWithResponses(data: data)
            if !responses.isEmpty {
                pty.write(data: responses)
            }

            let reportedDirectory = terminalHandle.currentDirectory()
            if !reportedDirectory.isEmpty && reportedDirectory != currentDirectory {
                currentDirectory = reportedDirectory
                updateGitInfo(for: reportedDirectory)
                persistSessionSnapshot()
            }

            refreshTrigger += 1
        }

        refreshShellRuntime(force: false)
        syncShellHistory(force: false)
    }

    func sendInput(_ string: String) {
        guard let pty = ptySession,
              let data = string.data(using: .utf8) else { return }
        pty.write(data: data)
    }

    func refreshShellRuntime(force: Bool) {
        guard let pty = ptySession else { return }
        let now = Date()
        if !force && now.timeIntervalSince(lastShellStatusRefresh) < 10 {
            return
        }
        lastShellStatusRefresh = now

        activeShell = pty.activeShell()
        activeShellPath = pty.activeShellPath()
        attemptedShellPath = pty.attemptedShellPath()
        shellFallbackReason = pty.fallbackReason()
        seashellVersion = pty.seashellVersion()
        shellStatusCheckedAt = now
    }

    func updateGitInfo(for path: String) {
        gitInfo = gitManager.getInfo(path: path)
        gitChangedFiles = gitManager.changedFiles(path: path, limit: 200)
    }

    func runGitCommand(_ command: String) {
        addSessionHistory(command)
        sendInput(command + "\r")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.updateGitInfo(for: self.currentDirectory)
            self.syncShellHistory(force: true)
        }
    }

    func recordPrintableInput(_ text: String) {
        pendingCommandBuffer += text
    }

    func recordBackspace() {
        guard !pendingCommandBuffer.isEmpty else { return }
        pendingCommandBuffer.removeLast()
    }

    func recordSubmit() {
        let command = pendingCommandBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !command.isEmpty {
            addSessionHistory(command)
        }
        pendingCommandBuffer = ""
    }

    func insertHistoryCommand(_ command: String, execute: Bool) {
        guard !command.isEmpty else { return }
        if execute {
            sendInput(command + "\r")
            addSessionHistory(command)
            pendingCommandBuffer = ""
        } else {
            sendInput(command)
            pendingCommandBuffer = command
        }
    }

    func mergedHistory(query: String, limit: Int = 200) -> [String] {
        var merged = [String]()
        merged.reserveCapacity(sessionHistory.count + shellHistory.count)
        merged.append(contentsOf: sessionHistory)
        merged.append(contentsOf: shellHistory)

        var seen = Set<String>()
        let deduped = merged.filter { seen.insert($0).inserted }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered: [String]
        if trimmedQuery.isEmpty {
            filtered = deduped
        } else {
            filtered = deduped.filter { $0.lowercased().contains(trimmedQuery) }
        }

        return Array(filtered.prefix(limit))
    }

    func syncShellHistory(force: Bool) {
        let now = Date()
        if !force && now.timeIntervalSince(lastHistorySync) < 5 {
            return
        }
        if historySyncInFlight {
            return
        }
        historySyncInFlight = true
        lastHistorySync = now

        DispatchQueue.global(qos: .utility).async {
            let loaded = Self.loadShellHistoryFiles()
            DispatchQueue.main.async {
                self.shellHistory = loaded
                self.historySyncInFlight = false
            }
        }
    }

    func resizeTerminal(to size: CGSize) {
        let font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let charWidth = font.maximumAdvancement.width
        let lineHeight = font.ascender - font.descender + font.leading

        let newCols = max(80, Int(size.width / charWidth))
        let newRows = max(24, Int(size.height / lineHeight))

        if let pty = ptySession {
            pty.resize(cols: UInt32(newCols), rows: UInt32(newRows))
        }

        terminalHandle?.resize(cols: UInt32(newCols), rows: UInt32(newRows))
    }

    private func addSessionHistory(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if sessionHistory.first != trimmed {
            sessionHistory.insert(trimmed, at: 0)
            if sessionHistory.count > 200 {
                sessionHistory.removeLast(sessionHistory.count - 200)
            }
            persistSessionSnapshot()
        }
    }

    private func persistSessionSnapshot() {
        let snapshot = SessionSnapshot(
            currentDirectory: currentDirectory,
            recentCommands: Array(sessionHistory.prefix(150)),
            preferredEditor: preferredEditor,
            savedAt: Date().timeIntervalSince1970
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.sessionSnapshotKey)
        hasSavedSession = true
    }

    private func validatePreferredEditorAvailability() {
        preferredEditorAvailable = Self.isEditorAvailable(preferredEditor)
        if preferredEditorAvailable {
            editorStatusMessage = ""
        } else {
            editorStatusMessage = Self.installHint(for: preferredEditor)
        }
    }

    private static func loadSessionSnapshot() -> SessionSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: sessionSnapshotKey),
              let snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }

    private static func isAutoRestoreEnabled() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: sessionAutoRestoreKey) == nil {
            return true
        }
        return defaults.bool(forKey: sessionAutoRestoreKey)
    }

    private static func installHint(for editor: String) -> String {
        if editor == "micro" {
            return "Editor 'micro' is not installed. Install with: brew install micro, or choose another editor."
        }
        return "Editor '\(editor)' was not found. Install it or choose another editor."
    }

    private static func isEditorAvailable(_ editor: String) -> Bool {
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

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func loadShellHistoryFiles() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let paths = ["\(home)/.zsh_history", "\(home)/.bash_history", "\(home)/.local/share/fish/fish_history"]

        var all = [String]()
        all.reserveCapacity(1200)

        for path in paths {
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
                continue
            }

            for line in content.split(separator: "\n") {
                let raw = String(line)
                let command: String

                if raw.hasPrefix(":") {
                    command = raw.split(separator: ";", maxSplits: 1).dropFirst().first.map(String.init) ?? ""
                } else if raw.hasPrefix("- cmd:") {
                    command = raw.replacingOccurrences(of: "- cmd:", with: "").trimmingCharacters(in: .whitespaces)
                } else {
                    command = raw
                }

                let normalized = command
                    .replacingOccurrences(of: "\\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalized.isEmpty {
                    all.append(normalized)
                }
            }
        }

        all.reverse()
        return all
    }

    private static func readBundledSeashellVersion() -> String {
        guard let resourceURL = Bundle.main.resourceURL else {
            return "unavailable"
        }
        let buildFile = resourceURL.appendingPathComponent("SeashellBuild.txt")
        guard let text = try? String(contentsOf: buildFile, encoding: .utf8) else {
            return "unavailable"
        }
        for line in text.split(separator: "\n") {
            if let value = line.split(separator: "=", maxSplits: 1).dropFirst().first {
                return String(value)
            }
        }
        return "unavailable"
    }
}

struct TerminalContainerView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @FocusState private var isTerminalFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LiquidGlassBackground()
                TerminalView(
                    viewModel: viewModel,
                    refreshTrigger: viewModel.refreshTrigger,
                    size: geometry.size
                )
                .focused($isTerminalFocused)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTerminalFocused = true
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                viewModel.resizeTerminal(to: newSize)
            }
        }
    }
}

struct CommandPaletteView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @State private var searchQuery = ""

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search commands...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding()

            List(viewModel.mergedHistory(query: searchQuery, limit: 200), id: \.self) { command in
                Text(command)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
            }
        }
        .frame(width: 600, height: 420)
    }
}
