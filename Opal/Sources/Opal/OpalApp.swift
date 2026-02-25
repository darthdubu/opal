import SwiftUI
import MetalKit
import Combine
import OpalCore

private let opalVersion = "1.1.3"

@main
struct OpalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            OpalCommands()
        }
        
        // Settings window as a separate floating window
        SettingsWindowScene()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Window transparency is now handled in ContentView
    }
}

struct OpalCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings...") {
                // Open settings window by ID using SwiftUI's openWindow
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
            
            Button("Clear Screen") {
                NotificationCenter.default.post(name: .clearScreen, object: nil)
            }
            .keyboardShortcut("k", modifiers: .command)

            Button("Restore Session") {
                NotificationCenter.default.post(name: .restoreSession, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
        
        CommandMenu("View") {
            Button("Toggle Sidebar") {
                NotificationCenter.default.post(name: .toggleSidebar, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            
            Button("Command Palette") {
                NotificationCenter.default.post(name: .showCommandPalette, object: nil)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Enter Full Screen") {
                NSApp.keyWindow?.toggleFullScreen(nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .control])
        }
        
        CommandMenu("Window") {
            Button("Minimize") {
                NSApp.keyWindow?.miniaturize(nil)
            }
            .keyboardShortcut("m", modifiers: .command)
            
            Button("Zoom") {
                NSApp.keyWindow?.zoom(nil)
            }
        }
        
        CommandGroup(replacing: .help) {
            Button("About Opal") {
                // Get app icon from bundle or create default
                let appIcon = NSApp.applicationIconImage ?? createDefaultAppIcon()
                let seashellBuild = readBundledSeashellBuildVersion()
                let credits = """
A beautiful Metal-accelerated terminal emulator.
Shell Build: Seashell \(seashellBuild)

© 2026 Opal Terminal
"""
                
                NSApp.orderFrontStandardAboutPanel(options: [
                    .applicationName: "Opal",
                    .applicationVersion: opalVersion,
                    .applicationIcon: appIcon,
                    .credits: NSAttributedString(string: credits)
                ])
            }
            
            Divider()
            
            Button("Check for Updates...") {
                if let url = URL(string: "https://github.com/opal-terminal/opal/releases") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Button("Opal Help") {
                // Could open help documentation
            }
            .keyboardShortcut("?", modifiers: .command)
        }
    }
}

// MARK: - Helper Functions
func readBundledSeashellBuildVersion() -> String {
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

func createDefaultAppIcon() -> NSImage {
    let size = NSSize(width: 128, height: 128)
    let image = NSImage(size: size)
    
    image.lockFocus()
    
    // Create gradient background
    let gradient = NSGradient(colors: [
        NSColor(hue: 210/360, saturation: 0.8, brightness: 0.9, alpha: 1.0),
        NSColor(hue: 260/360, saturation: 0.8, brightness: 0.9, alpha: 1.0)
    ])
    
    let rect = NSRect(origin: .zero, size: size)
    let path = NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28)
    
    gradient?.draw(in: path, angle: 45)
    
    // Add terminal symbol
    let terminalText = ">_" as NSString
    let font = NSFont.monospacedSystemFont(ofSize: 48, weight: .bold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    
    let textSize = terminalText.size(withAttributes: attributes)
    let textRect = NSRect(
        x: (size.width - textSize.width) / 2,
        y: (size.height - textSize.height) / 2 - 4,
        width: textSize.width,
        height: textSize.height
    )
    
    terminalText.draw(in: textRect, withAttributes: attributes)
    
    image.unlockFocus()
    
    return image
}

// MARK: - Settings Window Scene
struct SettingsWindowScene: Scene {
    var body: some Scene {
        Window("Settings", id: "settings") {
            SettingsView()
                .frame(minWidth: 700, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
        .commandsRemoved()
    }
}

extension Notification.Name {
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let clearScreen = Notification.Name("clearScreen")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let showCommandPalette = Notification.Name("showCommandPalette")
    static let restoreSession = Notification.Name("restoreSession")
    static let showShellDiagnostics = Notification.Name("showShellDiagnostics")
}
