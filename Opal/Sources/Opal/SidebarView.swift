import SwiftUI
import OpalCore
import AppKit
import Combine

private enum SidebarMode: String, CaseIterable, Identifiable {
    case workspace = "Workspace"
    case files = "Files"
    case history = "History"
    case shell = "Shell"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .workspace:
            return "square.grid.2x2"
        case .files:
            return "folder"
        case .history:
            return "clock.arrow.circlepath"
        case .shell:
            return "terminal"
        }
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @State private var selectedMode: SidebarMode = .workspace

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(SidebarMode.allCases) { mode in
                    SidebarModeButton(mode: mode, selectedMode: $selectedMode)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            Divider()

            Group {
                switch selectedMode {
                case .workspace:
                    WorkspaceDashboardView(viewModel: viewModel)
                case .files:
                    FileExplorerSidebarView(viewModel: viewModel)
                case .history:
                    HistorySidebarView(viewModel: viewModel)
                case .shell:
                    ShellDiagnosticsSidebarView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(.ultraThinMaterial)
        .onReceive(NotificationCenter.default.publisher(for: .showShellDiagnostics)) { _ in
            selectedMode = .shell
        }
    }
}

private struct SidebarModeButton: View {
    let mode: SidebarMode
    @Binding var selectedMode: SidebarMode

    private var isSelected: Bool {
        selectedMode == mode
    }

    var body: some View {
        Button(action: {
            selectedMode = mode
        }) {
            VStack(spacing: 2) {
                Image(systemName: mode.icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(mode.rawValue)
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
}

private struct WorkspaceDashboardView: View {
    @ObservedObject var viewModel: TerminalViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SidebarCard(title: "Current Directory") {
                    Text(viewModel.currentDirectory)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(3)

                    HStack(spacing: 8) {
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(viewModel.currentDirectory, forType: .string)
                        }
                        .buttonStyle(.bordered)

                        Button("Finder") {
                            viewModel.openDirectoryInFinder(viewModel.currentDirectory)
                        }
                        .buttonStyle(.bordered)

                        Button("Up") {
                            let parent = URL(fileURLWithPath: viewModel.currentDirectory)
                                .deletingLastPathComponent()
                                .path
                            viewModel.sendInput("cd \(shellQuote(parent))\r")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                SidebarCard(title: "Git") {
                    if let git = viewModel.gitInfo, git.isRepo {
                        HStack {
                            Label(git.branch ?? "detached", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            GitMetric(title: "A", value: Int(git.ahead), color: .green)
                            GitMetric(title: "B", value: Int(git.behind), color: .orange)
                            GitMetric(title: "M", value: Int(git.modified), color: .yellow)
                            GitMetric(title: "S", value: Int(git.staged), color: .blue)
                            GitMetric(title: "U", value: Int(git.untracked), color: .pink)
                        }

                        HStack(spacing: 8) {
                            Button("Status") { viewModel.runGitCommand("git status --short") }
                            Button("Pull") { viewModel.runGitCommand("git pull --rebase") }
                            Button("Push") { viewModel.runGitCommand("git push") }
                        }
                        .buttonStyle(.bordered)

                        if !viewModel.gitChangedFiles.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(viewModel.gitChangedFiles.prefix(16).enumerated()), id: \.offset) { _, file in
                                    HStack(spacing: 6) {
                                        Text(file.staged ? "●" : "○")
                                            .foregroundStyle(file.staged ? Color.blue : Color.secondary)
                                        Text(file.status)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 58, alignment: .leading)
                                        Button(file.path) {
                                            let fullPath = URL(fileURLWithPath: viewModel.currentDirectory)
                                                .appendingPathComponent(file.path)
                                                .path
                                            viewModel.openFileInPreferredEditor(fullPath)
                                        }
                                        .buttonStyle(.plain)
                                        .font(.system(.caption, design: .monospaced))
                                        .lineLimit(1)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("No git repository detected for this directory.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                SidebarCard(title: "Session") {
                    HStack(spacing: 8) {
                        Button("Restore") {
                            viewModel.restoreSession(manual: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.hasSavedSession)

                        Button("Clear") {
                            viewModel.clearScreen()
                        }
                        .buttonStyle(.bordered)
                    }

                    if !viewModel.sessionRestoreStatus.isEmpty {
                        Text(viewModel.sessionRestoreStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
        }
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

private struct GitMetric: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(width: 22)
    }
}

private struct FileExplorerSidebarView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @State private var rootPath = ""
    @State private var editorDraft = ""
    @State private var pinRootToCwd = true
    @State private var showHiddenFiles = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SidebarCard(title: "Editor") {
                    HStack(spacing: 8) {
                        TextField("micro", text: $editorDraft)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))

                        Button("Set") {
                            viewModel.setPreferredEditor(editorDraft)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    HStack(spacing: 6) {
                        QuickEditorButton(name: "micro") {
                            editorDraft = "micro"
                            viewModel.setPreferredEditor("micro")
                        }
                        QuickEditorButton(name: "code") {
                            editorDraft = "code"
                            viewModel.setPreferredEditor("code")
                        }
                        QuickEditorButton(name: "nvim") {
                            editorDraft = "nvim"
                            viewModel.setPreferredEditor("nvim")
                        }
                    }

                    if !viewModel.preferredEditorAvailable {
                        Text(viewModel.editorStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                SidebarCard(title: "Explorer Root") {
                    Text(rootPath)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .textSelection(.enabled)

                    HStack(spacing: 8) {
                        Button("Use CWD") {
                            rootPath = viewModel.currentDirectory
                        }
                        .buttonStyle(.bordered)

                        Button("Parent") {
                            rootPath = URL(fileURLWithPath: rootPath).deletingLastPathComponent().path
                        }
                        .buttonStyle(.bordered)

                        Button(pinRootToCwd ? "Pinned" : "Pin to CWD") {
                            pinRootToCwd.toggle()
                        }
                        .buttonStyle(.bordered)
                    }

                    Toggle("Show hidden files", isOn: $showHiddenFiles)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                }

                SidebarCard(title: "Files") {
                    DirectoryTreeView(
                        rootPath: rootPath,
                        showHiddenFiles: showHiddenFiles,
                        viewModel: viewModel
                    )
                    .frame(minHeight: 180)
                }
            }
            .padding(12)
        }
        .onAppear {
            rootPath = viewModel.currentDirectory
            editorDraft = viewModel.preferredEditor
        }
        .onChange(of: viewModel.currentDirectory) { _, newPath in
            if pinRootToCwd || rootPath.isEmpty {
                rootPath = newPath
            }
        }
        .onChange(of: viewModel.preferredEditor) { _, newEditor in
            if editorDraft != newEditor {
                editorDraft = newEditor
            }
        }
    }
}

private struct QuickEditorButton: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button(name, action: action)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .font(.caption)
    }
}

private struct DirectoryTreeView: View {
    let rootPath: String
    let showHiddenFiles: Bool
    @ObservedObject var viewModel: TerminalViewModel

    @State private var rootChildren: [URL] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if rootChildren.isEmpty {
                Text("No files to display.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rootChildren, id: \.path) { child in
                    DirectoryNodeView(
                        url: child,
                        depth: 0,
                        showHiddenFiles: showHiddenFiles,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear(perform: loadRootChildren)
        .onChange(of: rootPath) { _, _ in
            loadRootChildren()
        }
        .onChange(of: showHiddenFiles) { _, _ in
            loadRootChildren()
        }
    }

    private func loadRootChildren() {
        rootChildren = DirectoryNodeView.children(for: URL(fileURLWithPath: rootPath), showHiddenFiles: showHiddenFiles)
    }
}

private struct DirectoryNodeView: View {
    let url: URL
    let depth: Int
    let showHiddenFiles: Bool
    @ObservedObject var viewModel: TerminalViewModel

    @State private var isExpanded = false
    @State private var children: [URL] = []

    private var isDirectory: Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isDirectory {
                DisclosureGroup(isExpanded: $isExpanded) {
                    VStack(alignment: .leading, spacing: 2) {
                        if children.isEmpty {
                            Text("Empty")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.leading, CGFloat((depth + 1) * 12))
                        } else {
                            ForEach(children, id: \.path) { child in
                                DirectoryNodeView(
                                    url: child,
                                    depth: depth + 1,
                                    showHiddenFiles: showHiddenFiles,
                                    viewModel: viewModel
                                )
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .foregroundStyle(.yellow)
                        Text(url.lastPathComponent)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                    }
                }
                .padding(.leading, CGFloat(depth * 12))
                .onChange(of: isExpanded) { _, expanded in
                    if expanded {
                        loadChildren()
                    }
                }
                .onChange(of: showHiddenFiles) { _, _ in
                    if isExpanded {
                        loadChildren()
                    }
                }
            } else {
                Button(action: {
                    viewModel.openFileInPreferredEditor(url.path)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: fileIcon(for: url))
                            .foregroundStyle(.secondary)
                        Text(url.lastPathComponent)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.leading, CGFloat(depth * 12 + 22))
            }
        }
    }

    private func loadChildren() {
        children = Self.children(for: url, showHiddenFiles: showHiddenFiles)
    }

    private func fileIcon(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "swift", "rs", "js", "ts", "py", "md", "toml", "json", "yaml", "yml":
            return "doc.plaintext"
        default:
            return "doc"
        }
    }

    static func children(for url: URL, showHiddenFiles: Bool) -> [URL] {
        let fileManager = FileManager.default
        var options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
        if !showHiddenFiles {
            options.insert(.skipsHiddenFiles)
        }

        guard let entries = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
            options: options
        ) else {
            return []
        }

        return entries.sorted { lhs, rhs in
            let lhsDir = (try? lhs.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let rhsDir = (try? rhs.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if lhsDir != rhsDir {
                return lhsDir && !rhsDir
            }
            return lhs.lastPathComponent.localizedCaseInsensitiveCompare(rhs.lastPathComponent) == .orderedAscending
        }
    }
}

private struct HistorySidebarView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("Filter command history", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))

                Button("Sync") {
                    viewModel.syncShellHistory(force: true)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.mergedHistory(query: query, limit: 200), id: \.self) { command in
                        HStack(spacing: 6) {
                            Text(command)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: {
                                viewModel.insertHistoryCommand(command, execute: false)
                            }) {
                                Image(systemName: "text.insert")
                            }
                            .buttonStyle(.plain)
                            .help("Insert")

                            Button(action: {
                                viewModel.insertHistoryCommand(command, execute: true)
                            }) {
                                Image(systemName: "play.fill")
                            }
                            .buttonStyle(.plain)
                            .help("Run")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 7))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }
}

private struct ShellDiagnosticsSidebarView: View {
    @ObservedObject var viewModel: TerminalViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SidebarCard(title: "Runtime") {
                    ShellRow(label: "Active", value: viewModel.activeShell)
                    ShellRow(label: "Path", value: viewModel.activeShellPath)
                    ShellRow(label: "Attempted", value: viewModel.attemptedShellPath.isEmpty ? "n/a" : viewModel.attemptedShellPath)
                    ShellRow(label: "Fallback", value: viewModel.shellFallbackReason.isEmpty ? "none" : viewModel.shellFallbackReason)
                    ShellRow(label: "Seashell", value: viewModel.seashellVersion.isEmpty ? viewModel.shellBuildVersion : viewModel.seashellVersion)

                    HStack(spacing: 8) {
                        Button("Refresh") {
                            viewModel.refreshShellRuntime(force: true)
                        }
                        .buttonStyle(.bordered)

                        Button("Restore Session") {
                            viewModel.restoreSession(manual: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.hasSavedSession)
                    }

                    if !viewModel.sessionRestoreStatus.isEmpty {
                        Text(viewModel.sessionRestoreStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                SidebarCard(title: "Diagnostics") {
                    Text(viewModel.shellDiagnosticsText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .padding(12)
        }
    }
}

private struct ShellRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SidebarCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            content
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
