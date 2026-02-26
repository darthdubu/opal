import AppKit
import SwiftUI

@main
struct OpalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            OpalCommands()
        }

        Window("Settings", id: "settings") {
            SettingsView()
                .frame(minWidth: 760, minHeight: 540)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 820, height: 620)
        .commandsRemoved()
    }
}

private struct OpalCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings...") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        CommandMenu("Terminal") {
            Button("New Tab") {
                NotificationCenter.default.post(name: .newTab, object: nil)
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("Close Tab") {
                NotificationCenter.default.post(name: .closeTab, object: nil)
            }
            .keyboardShortcut("w", modifiers: .command)

            Divider()

            Button("Restore Session") {
                NotificationCenter.default.post(name: .restoreSession, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Button("Clear Screen") {
                NotificationCenter.default.post(name: .clearScreen, object: nil)
            }
            .keyboardShortcut("k", modifiers: .command)
        }

        CommandGroup(replacing: .help) {
            Button("About Opal") {
                let shellBuild = readBundledSeashellBuildVersion()
                let credits = """
A calm, premium terminal rewrite path.
Shell Build: Seashell \(shellBuild)
"""

                NSApp.orderFrontStandardAboutPanel(options: [
                    .applicationName: "Opal",
                    .applicationVersion: opalVersion,
                    .credits: NSAttributedString(string: credits),
                ])
            }
        }
    }
}

extension Notification.Name {
    static let newTab = Notification.Name("Opal.newTab")
    static let closeTab = Notification.Name("Opal.closeTab")
    static let restoreSession = Notification.Name("Opal.restoreSession")
    static let clearScreen = Notification.Name("Opal.clearScreen")
}
