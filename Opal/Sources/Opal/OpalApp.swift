import SwiftUI
import MetalKit
import Combine
import OpalCore

@main
struct OpalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showSettings = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .frame(minWidth: 700, minHeight: 500)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            OpalCommands(showSettings: $showSettings)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Window transparency is now handled in ContentView
    }
}

struct OpalCommands: Commands {
    @Binding var showSettings: Bool
    
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings...") {
                showSettings = true
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
    }
}

extension Notification.Name {
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let clearScreen = Notification.Name("clearScreen")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let showCommandPalette = Notification.Name("showCommandPalette")
}
