import AppKit
import Combine
import Foundation

final class TerminalViewModel: ObservableObject {
    @Published var terminalHandle: TerminalHandleLite?
    @Published var ptySession: PtySessionLite?
    @Published var currentDirectory: String = FileManager.default.currentDirectoryPath
    @Published var refreshTrigger: Int = 0
    @Published var hasSavedSession: Bool = false
    @Published var sessionRestoreStatus: String = ""
    @Published var runtimeStatus: RuntimeStatusBadgeModel = RuntimeStatusStore.shared.status
    @Published var cursorBlinkVisible: Bool = true

    private var outputTimer: Timer?
    private var cursorBlinkTimer: Timer?
    private var started = false
    private var pendingCommandBuffer = ""
    private var sessionHistory: [String] = []
    private var lastRuntimeCheck = Date.distantPast
    private var cancellables = Set<AnyCancellable>()

    private static let sessionSnapshotKey = "opal.session.snapshot.v1"
    static let sessionAutoRestoreKey = "opal.session.autorestore"
    static let defaultShellPreferenceKey = "opal.shell.default"

    private struct SessionSnapshot: Codable {
        let currentDirectory: String
        let recentCommands: [String]
        let savedAt: TimeInterval
    }

    init() {
        hasSavedSession = Self.loadSessionSnapshot() != nil

        TerminalAppearanceSettings.shared.$cursorBlink
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                if !enabled {
                    self?.cursorBlinkVisible = true
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        outputTimer?.invalidate()
        cursorBlinkTimer?.invalidate()
    }

    var shellBadgeText: String {
        runtimeStatus.badgeText
    }

    var shellDiagnosticsText: String {
        runtimeStatus.diagnosticsText
    }

    var shellIsFallback: Bool {
        runtimeStatus.isFallback
    }

    func startSessionIfNeeded() {
        guard !started else { return }
        started = true
        startSession()
    }

    func startSession() {
        configureSeashellEnvironment()

        let autoRestore = Self.isSessionRestoreEnabled()
        if let snapshot = Self.loadSessionSnapshot() {
            hasSavedSession = true
            sessionHistory = snapshot.recentCommands
            if autoRestore && !snapshot.currentDirectory.isEmpty {
                currentDirectory = snapshot.currentDirectory
            }
        }

        let pty = PtySessionLite(cols: 80, rows: 24, preferredShell: Self.preferredShellValue())
        ptySession = pty
        terminalHandle = pty.terminal()

        refreshShellRuntime(force: true)
        startReadLoop()
        startCursorBlinkLoop()

        if autoRestore, hasSavedSession {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.restoreSession(manual: false)
            }
        }
    }

    func clearScreen() {
        sendInput("\u{001B}[2J\u{001B}[H")
    }

    func sendInput(_ value: String) {
        guard let data = value.data(using: .utf8), let ptySession else { return }
        ptySession.write(data)
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

    func restoreSession(manual: Bool) {
        guard let snapshot = Self.loadSessionSnapshot() else {
            hasSavedSession = false
            if manual {
                sessionRestoreStatus = "No saved session available."
            }
            return
        }

        hasSavedSession = true
        currentDirectory = snapshot.currentDirectory.isEmpty
            ? FileManager.default.currentDirectoryPath
            : snapshot.currentDirectory

        sendInput("cd \(Self.shellQuote(currentDirectory))\r")

        let merged = snapshot.recentCommands + sessionHistory
        var seen = Set<String>()
        sessionHistory = merged.filter { seen.insert($0).inserted }
        persistSessionSnapshot()

        if manual {
            let restoredAt = Date(timeIntervalSince1970: snapshot.savedAt)
            let stamp = DateFormatter.localizedString(from: restoredAt, dateStyle: .none, timeStyle: .short)
            sessionRestoreStatus = "Restored session saved at \(stamp)."
        }
    }

    func resizeTerminal(to size: CGSize) {
        let font = TerminalAppearanceSettings.shared.resolvedFont()
        let charWidth = max(6.0, font.maximumAdvancement.width)
        let lineHeight = max(10.0, font.ascender - font.descender + font.leading)

        let newCols = max(40, Int(size.width / charWidth))
        let newRows = max(14, Int(size.height / lineHeight))

        ptySession?.resize(cols: UInt32(newCols), rows: UInt32(newRows))
        terminalHandle?.resize(cols: UInt32(newCols), rows: UInt32(newRows))
    }

    private func startReadLoop() {
        outputTimer?.invalidate()
        outputTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.readOutput()
        }
    }

    private func startCursorBlinkLoop() {
        cursorBlinkTimer?.invalidate()
        cursorBlinkTimer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in
            guard let self else { return }
            if TerminalAppearanceSettings.shared.cursorBlink {
                self.cursorBlinkVisible.toggle()
                self.refreshTrigger += 1
            } else if !self.cursorBlinkVisible {
                self.cursorBlinkVisible = true
                self.refreshTrigger += 1
            }
        }
    }

    private func readOutput() {
        guard let ptySession, let terminalHandle else { return }

        if !ptySession.isAlive() {
            outputTimer?.invalidate()
            outputTimer = nil
            return
        }

        let data = ptySession.read()
        if !data.isEmpty {
            let responses = terminalHandle.processInputWithResponses(data: data)
            if !responses.isEmpty {
                ptySession.write(responses)
            }

            let reportedDirectory = terminalHandle.currentDirectory()
            if !reportedDirectory.isEmpty, reportedDirectory != currentDirectory {
                currentDirectory = reportedDirectory
                persistSessionSnapshot()
            }

            refreshTrigger += 1
        }

        refreshShellRuntime(force: false)
    }

    private func refreshShellRuntime(force: Bool) {
        guard let ptySession else { return }
        let now = Date()

        if !force, now.timeIntervalSince(lastRuntimeCheck) < 5 {
            return
        }
        lastRuntimeCheck = now

        let status = ptySession.shellRuntimeStatus()
        let version = status.seashellVersion.isEmpty ? Self.readBundledSeashellVersion() : status.seashellVersion

        let model = RuntimeStatusBadgeModel(
            activeShell: status.activeShell,
            activeShellPath: status.activeShellPath,
            attemptedShellPath: status.attemptedShellPath,
            fallbackReason: status.fallbackReason,
            seashellVersion: version,
            checkedAt: now
        )

        runtimeStatus = model
        RuntimeStatusStore.shared.update(model)
    }

    private func addSessionHistory(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if sessionHistory.first != trimmed {
            sessionHistory.insert(trimmed, at: 0)
            if sessionHistory.count > 150 {
                sessionHistory.removeLast(sessionHistory.count - 150)
            }
            persistSessionSnapshot()
        }
    }

    private func persistSessionSnapshot() {
        let snapshot = SessionSnapshot(
            currentDirectory: currentDirectory,
            recentCommands: Array(sessionHistory.prefix(120)),
            savedAt: Date().timeIntervalSince1970
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.sessionSnapshotKey)
        hasSavedSession = true
    }

    private func configureSeashellEnvironment() {
        if let shellPath = Self.resolveSeashellExecutablePath() {
            setenv("OPAL_BUNDLED_SEASHELL", shellPath, 1)
            setenv("OPAL_SEASHELL_OVERRIDE", shellPath, 1)
            setenv("OPAL_SEASHELL_PATH", shellPath, 1)
        }

        if let bundledLibPath = Bundle.main.resourceURL?
            .appendingPathComponent("seashell/lib")
            .path,
           FileManager.default.fileExists(atPath: bundledLibPath) {
            setenv("OPAL_BUNDLED_SEASHELL_LIB", bundledLibPath, 1)
        }
    }

    private static func resolveSeashellExecutablePath() -> String? {
        let fileManager = FileManager.default

        if let envShell = ProcessInfo.processInfo.environment["OPAL_SEASHELL_PATH"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !envShell.isEmpty,
           fileManager.isExecutableFile(atPath: envShell) {
            return envShell
        }

        if let envOverride = ProcessInfo.processInfo.environment["OPAL_SEASHELL_OVERRIDE"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !envOverride.isEmpty,
           fileManager.isExecutableFile(atPath: envOverride) {
            return envOverride
        }

        if let bundledShellPath = Bundle.main.resourceURL?
            .appendingPathComponent("seashell/sea")
            .path,
           fileManager.isExecutableFile(atPath: bundledShellPath) {
            return bundledShellPath
        }

        let localRewrite = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent("../seashell/sea")
            .standardizedFileURL
            .path
        if fileManager.isExecutableFile(atPath: localRewrite) {
            return localRewrite
        }

        return nil
    }

    private static func loadSessionSnapshot() -> SessionSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: sessionSnapshotKey),
              let snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }

    static func isSessionRestoreEnabled() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: sessionAutoRestoreKey) == nil {
            return true
        }
        return defaults.bool(forKey: sessionAutoRestoreKey)
    }

    private static func preferredShellValue() -> String {
        let defaults = UserDefaults.standard
        let configured = defaults.string(forKey: defaultShellPreferenceKey) ?? "sea"
        return configured == "zsh" ? "zsh" : "sea"
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func readBundledSeashellVersion() -> String {
        let fileManager = FileManager.default
        let localVersionPath = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent("../seashell/VERSION")
            .standardizedFileURL
            .path
        if let version = try? String(contentsOfFile: localVersionPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !version.isEmpty {
            return version
        }

        guard let resourceURL = Bundle.main.resourceURL else {
            return "unavailable"
        }

        let buildFile = resourceURL.appendingPathComponent("SeashellBuild.txt")
        guard let text = try? String(contentsOf: buildFile, encoding: .utf8) else {
            return "unavailable"
        }

        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                return String(parts[1])
            }
        }

        return "unavailable"
    }
}
