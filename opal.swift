import AppKit

class OpalWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "Opal Terminal"
        self.center()
        self.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        
        let view = OpalTerminalView(frame: self.contentView!.bounds)
        self.contentView?.addSubview(view)
    }
}

class OpalTerminalView: NSView {
    override var acceptsFirstResponder: Bool { true }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0).setFill()
        dirtyRect.fill()
        
        let text = "Opal Terminal v0.1.0\n\nInitializing..."
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(red: 0, green: 0.83, blue: 1.0, alpha: 1.0),
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        ]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        attrString.draw(at: NSPoint(x: 20, y: bounds.height - 40))
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle keyboard input
    }
}

class OpalAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = OpalWindow()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = OpalAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
