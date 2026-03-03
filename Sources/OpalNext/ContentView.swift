import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var terminalVM = TerminalViewModel()
    @State private var didRegisterObservers = false
    @State private var currentWindow: NSWindow?
    private let titlebarMaterialViewIdentifier = NSUserInterfaceItemIdentifier("OpalTitlebarMaterialView")

    var body: some View {
        TerminalSurface(viewModel: terminalVM)
        .background(Color.clear)
        .background(WindowAccessor { window in
            currentWindow = window
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.tabbingMode = .preferred
            installTitlebarMaterialIfNeeded(for: window)
            updateNativeTabBarVisibility(for: window)
            scheduleTabBarRefresh(for: window)

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
            terminalVM.startSessionIfNeeded()
            if let window = currentWindow {
                installTitlebarMaterialIfNeeded(for: window)
                updateNativeTabBarVisibility(for: window)
                scheduleTabBarRefresh(for: window)
            }
        }
    }

    private func openNativeTab() {
        NSApp.sendAction(Selector(("newTab:")), to: nil, from: nil)
    }

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            forName: .newTab,
            object: nil,
            queue: .main
        ) { _ in
            openNativeTab()
            if let window = currentWindow {
                scheduleTabBarRefresh(for: window)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { _ in
            NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: nil)
            if let window = currentWindow {
                scheduleTabBarRefresh(for: window)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .restoreSession,
            object: nil,
            queue: .main
        ) { _ in
            terminalVM.restoreSession(manual: true)
        }

        NotificationCenter.default.addObserver(
            forName: .clearScreen,
            object: nil,
            queue: .main
        ) { _ in
            terminalVM.clearScreen()
        }
    }

    private func updateNativeTabBarVisibility(for window: NSWindow) {
        let tabCount = window.tabbedWindows?.count ?? 1
        let shouldShowTabBar = tabCount > 1
        let setSelector = Selector(("setTabBarVisible:"))
        if window.responds(to: setSelector) {
            _ = window.perform(setSelector, with: NSNumber(value: shouldShowTabBar))
            return
        }

        let isVisibleSelector = Selector(("isTabBarVisible"))
        let toggleSelector = Selector(("toggleTabBar:"))
        if window.responds(to: isVisibleSelector),
           let result = window.perform(isVisibleSelector)?.takeUnretainedValue() as? NSNumber {
            let isTabBarVisible = result.boolValue
            if isTabBarVisible != shouldShowTabBar, window.responds(to: toggleSelector) {
                _ = window.perform(toggleSelector, with: nil)
            }
        }
    }

    private func scheduleTabBarRefresh(for window: NSWindow) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            installTitlebarMaterialIfNeeded(for: window)
            updateNativeTabBarVisibility(for: window)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            installTitlebarMaterialIfNeeded(for: window)
            updateNativeTabBarVisibility(for: window)
        }
    }

    private func installTitlebarMaterialIfNeeded(for window: NSWindow) {
        guard let frameView = window.contentView?.superview else {
            return
        }

        let titlebarHeight = max(38, window.frame.height - window.contentLayoutRect.height)
        let materialFrame = NSRect(
            x: 0,
            y: frameView.bounds.height - titlebarHeight,
            width: frameView.bounds.width,
            height: titlebarHeight
        )

        if let existing = frameView.subviews.first(where: { $0.identifier == titlebarMaterialViewIdentifier }) as? NSVisualEffectView {
            existing.frame = materialFrame
            return
        }

        let materialView = NSVisualEffectView(frame: materialFrame)
        materialView.identifier = titlebarMaterialViewIdentifier
        materialView.material = .titlebar
        materialView.blendingMode = .withinWindow
        materialView.state = .active
        materialView.isEmphasized = false
        materialView.autoresizingMask = [.width, .minYMargin]
        materialView.wantsLayer = true
        materialView.layer?.backgroundColor = NSColor.clear.cgColor

        frameView.addSubview(materialView, positioned: .above, relativeTo: window.contentView)
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
