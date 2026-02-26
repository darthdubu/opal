import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow

    @StateObject private var tabStore = TabStore()
    @State private var didRegisterObservers = false

    var body: some View {
        VStack(spacing: 0) {
            TopToolbar(
                activeViewModel: tabStore.selectedTab.terminalVM,
                onNewTab: addTab,
                onRestore: { tabStore.selectedTab.terminalVM.restoreSession(manual: true) },
                onOpenSettings: { openWindow(id: "settings") }
            )
            .frame(height: 44)
            .background(.ultraThinMaterial)

            if tabStore.tabs.count > 1 {
                TabStrip(
                    tabs: tabStore.tabs,
                    selectedTabID: $tabStore.selectedTabID,
                    onClose: { tabStore.close(tabID: $0) }
                )
                .frame(height: 34)
                .background(.ultraThinMaterial)
                .transition(.opacity)
            }

            TerminalSurface(viewModel: tabStore.selectedTab.terminalVM)
        }
        .background(Color.clear)
        .background(WindowAccessor { window in
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true

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
            if !didRegisterObservers {
                registerNotifications()
                didRegisterObservers = true
            }
            tabStore.selectedTab.terminalVM.startSessionIfNeeded()
        }
        .onChange(of: tabStore.selectedTabID) { _, _ in
            tabStore.selectedTab.terminalVM.startSessionIfNeeded()
        }
    }

    private func addTab() {
        let tab = tabStore.newTab()
        tab.terminalVM.startSessionIfNeeded()
    }

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            forName: .newTab,
            object: nil,
            queue: .main
        ) { _ in
            addTab()
        }

        NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { _ in
            tabStore.closeSelectedTab()
        }

        NotificationCenter.default.addObserver(
            forName: .restoreSession,
            object: nil,
            queue: .main
        ) { _ in
            tabStore.selectedTab.terminalVM.restoreSession(manual: true)
        }

        NotificationCenter.default.addObserver(
            forName: .clearScreen,
            object: nil,
            queue: .main
        ) { _ in
            tabStore.selectedTab.terminalVM.clearScreen()
        }
    }
}

private struct TopToolbar: View {
    @ObservedObject var activeViewModel: TerminalViewModel

    let onNewTab: () -> Void
    let onRestore: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onNewTab) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("New tab")

            Spacer(minLength: 8)

            Button(action: onRestore) {
                Label("Restore", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.17), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!activeViewModel.hasSavedSession)
            .opacity(activeViewModel.hasSavedSession ? 1.0 : 0.5)
            .help("Restore saved directory + command context")

            ShellBadge(status: activeViewModel.runtimeStatus)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .background(Color.gray.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 10)
    }
}

private struct ShellBadge: View {
    let status: RuntimeStatusBadgeModel

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.isFallback ? Color.orange.opacity(0.9) : Color.green.opacity(0.8))
                .frame(width: 7, height: 7)
            Text(status.badgeText)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.gray.opacity(0.18), in: Capsule())
        .help(status.diagnosticsText)
    }
}

private struct TabStrip: View {
    let tabs: [TabSession]
    @Binding var selectedTabID: UUID
    let onClose: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                    HStack(spacing: 6) {
                        Button {
                            selectedTabID = tab.id
                        } label: {
                            Text(tabTitle(for: tab, index: index))
                                .lineLimit(1)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(tab.id == selectedTabID ? Color.accentColor.opacity(0.28) : Color.gray.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            onClose(tab.id)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
    }

    private func tabTitle(for tab: TabSession, index: Int) -> String {
        let title = tab.title
        if title == "Terminal" {
            return "Tab \(index + 1)"
        }
        return title
    }
}

private struct TerminalSurface: View {
    @ObservedObject var viewModel: TerminalViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LiquidGlassBackground(profile: .shared)

                TerminalView(
                    viewModel: viewModel,
                    refreshTrigger: viewModel.refreshTrigger
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                viewModel.startSessionIfNeeded()
            }
            .onChange(of: geometry.size) { _, newSize in
                viewModel.resizeTerminal(to: newSize)
            }
        }
    }
}
