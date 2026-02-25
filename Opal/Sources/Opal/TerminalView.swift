import SwiftUI
import OpalCore

struct TerminalView: NSViewRepresentable {
    @ObservedObject var viewModel: TerminalViewModel
    
    var refreshTrigger: Int
    var size: CGSize
    
    func makeNSView(context: Context) -> TerminalScrollView {
        let scrollView = TerminalScrollView()
        scrollView.viewModel = viewModel
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        
        // Configure the text view
        let textView = scrollView.documentView as! TerminalTextView
        textView.viewModel = viewModel
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.autoresizingMask = [.width, .height]
        textView.allowsUndo = false
        
        return scrollView
    }
    
    func updateNSView(_ nsView: TerminalScrollView, context: Context) {
        _ = refreshTrigger
        guard let terminalHandle = viewModel.terminalHandle,
              let textView = nsView.documentView as? TerminalTextView else { return }
        
        let rows = Int(terminalHandle.rows())
        let cols = Int(terminalHandle.cols())
        let cursorRow = Int(terminalHandle.cursorRow())
        let cursorCol = Int(terminalHandle.cursorCol())
        let cursorVisible = terminalHandle.cursorVisible()
        
        // Find the last row with actual content
        var lastContentRow = 0
        for row in (0..<rows).reversed() {
            var hasContent = false
            for col in 0..<cols {
                if let cell = terminalHandle.cellAt(col: UInt32(col), row: UInt32(row)) {
                    if cell.content != " " {
                        hasContent = true
                        break
                    }
                }
            }
            if hasContent {
                lastContentRow = row
                break
            }
        }
        
        // Build attributed string - render from row 0 to the last row with content
        // Include a few extra rows for visual buffer, but not the entire grid
        let renderEndRow = max(lastContentRow, cursorRow) + 2
        let attributedString = NSMutableAttributedString()
        
        for row in 0..<min(renderEndRow, rows) {
            let rowAttributed = NSMutableAttributedString()
            
            for col in 0..<cols {
                if let cell = terminalHandle.cellAt(col: UInt32(col), row: UInt32(row)) {
                    let char = cell.content
                    
                    // Check if cell has actual content or is the cursor position
                    let isCursorCell = cursorVisible && (row == cursorRow && col == cursorCol)
                    
                    // Get true colors from cell
                    let fgColor = nsColor(from: cell.foreground)
                    let bgColor = nsColor(from: cell.background)
                    
                    var attributes: [NSAttributedString.Key: Any] = [
                        .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                        .foregroundColor: fgColor
                    ]
                    
                    // Add background color - use clear for default to show aurora shader
                    if cell.background == .default {
                        attributes[.backgroundColor] = NSColor.clear
                    } else {
                        attributes[.backgroundColor] = bgColor
                    }
                    
                    // Draw the cursor directly in the text grid to avoid overlay drift.
                    if isCursorCell {
                        attributes[.foregroundColor] = NSColor.black
                        attributes[.backgroundColor] = NSColor.white
                    }
                    
                    // Add bold/italic attributes
                    if cell.bold {
                        attributes[.font] = NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
                    }
                    
                    let attrChar = NSAttributedString(string: String(char), attributes: attributes)
                    rowAttributed.append(attrChar)
                }
            }
            
            // Always add the row if it has content or is before the last content row
            // This prevents gaps in the terminal display
            attributedString.append(rowAttributed)
            if row < min(renderEndRow, rows) - 1 {
                attributedString.append(NSAttributedString(string: "\n"))
            }
        }
        
        // Only update if content changed
        if !textView.hasSameContent(as: attributedString) {
            textView.textStorage?.setAttributedString(attributedString)
        }
        
        let renderedRowCount = min(renderEndRow, rows)
        if renderedRowCount > 0 && cols > 0 {
            let safeRow = max(0, min(cursorRow, renderedRowCount - 1))
            let safeCol = max(0, min(cursorCol, cols - 1))
            let rowSpan = cols + 1 // +1 for newline separator between rows.
            let cursorIndex = min(attributedString.length, safeRow * rowSpan + safeCol)
            textView.scrollRangeToVisible(NSRange(location: cursorIndex, length: 0))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Convert TerminalColor to NSColor with true color support
    private func nsColor(from color: TerminalColor) -> NSColor {
        switch color {
        case .default:
            return .white
        case .black:
            return NSColor(red: 0, green: 0, blue: 0, alpha: 1)
        case .red:
            return NSColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1)
        case .green:
            return NSColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1)
        case .yellow:
            return NSColor(red: 0.8, green: 0.8, blue: 0.2, alpha: 1)
        case .blue:
            return NSColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
        case .magenta:
            return NSColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 1)
        case .cyan:
            return NSColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1)
        case .white:
            return NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        case .brightBlack:
            return NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        case .brightRed:
            return NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1)
        case .brightGreen:
            return NSColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1)
        case .brightYellow:
            return NSColor(red: 1.0, green: 1.0, blue: 0.4, alpha: 1)
        case .brightBlue:
            return NSColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)
        case .brightMagenta:
            return NSColor(red: 1.0, green: 0.4, blue: 1.0, alpha: 1)
        case .brightCyan:
            return NSColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1)
        case .brightWhite:
            return NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        case .indexed(let index):
            return colorFor256(index: index)
        case .rgb(let r, let g, let b):
            return NSColor(red: CGFloat(r) / 255.0, 
                          green: CGFloat(g) / 255.0, 
                          blue: CGFloat(b) / 255.0, 
                          alpha: 1.0)
        }
    }
    
    // Convert 256-color index to NSColor
    private func colorFor256(index: UInt8) -> NSColor {
        if index < 16 {
            // Standard 16 colors
            let colors: [NSColor] = [
                .black, .red, .green, .yellow, .blue, .magenta, .cyan, .white,
                NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1), // bright black
                NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1), // bright red
                NSColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1), // bright green
                NSColor(red: 1.0, green: 1.0, blue: 0.4, alpha: 1), // bright yellow
                NSColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1), // bright blue
                NSColor(red: 1.0, green: 0.4, blue: 1.0, alpha: 1), // bright magenta
                NSColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1), // bright cyan
                NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1), // bright white
            ]
            return colors[Int(index)]
        } else if index < 232 {
            // 6x6x6 color cube
            let idx = Int(index - 16)
            let r = CGFloat(idx / 36) / 5.0
            let g = CGFloat((idx % 36) / 6) / 5.0
            let b = CGFloat(idx % 6) / 5.0
            return NSColor(red: r, green: g, blue: b, alpha: 1)
        } else {
            // Grayscale
            let gray = CGFloat(index - 232) / 23.0
            return NSColor(red: gray, green: gray, blue: gray, alpha: 1)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TerminalView
        
        init(_ parent: TerminalView) {
            self.parent = parent
        }
    }
}

// Custom NSTextView that captures keyboard input and shows cursor
class TerminalTextView: NSTextView {
    weak var viewModel: TerminalViewModel?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    func hasSameContent(as attributedString: NSAttributedString) -> Bool {
        guard let current = textStorage else { return false }
        return current.isEqual(to: attributedString)
    }
    
    override func keyDown(with event: NSEvent) {
        guard let viewModel = viewModel else {
            super.keyDown(with: event)
            return
        }
                
        // Handle special keys
        switch event.keyCode {
        case 36: // Return
            viewModel.recordSubmit()
            viewModel.sendInput("\r")
        case 51: // Delete
            viewModel.recordBackspace()
            viewModel.sendInput("\u{7f}")
        case 48: // Tab
            viewModel.sendInput("\t")
        case 49: // Space
            viewModel.recordPrintableInput(" ")
            viewModel.sendInput(" ")
        case 53: // Escape
            viewModel.sendInput("\u{1b}")
        case 126: // Up arrow
            viewModel.sendInput("\u{1b}[A")
        case 125: // Down arrow
            viewModel.sendInput("\u{1b}[B")
        case 124: // Right arrow
            viewModel.sendInput("\u{1b}[C")
        case 123: // Left arrow
            viewModel.sendInput("\u{1b}[D")
        default:
            if let characters = event.characters {
                viewModel.sendInput(characters)
                let modifiers = event.modifierFlags.intersection([.command, .control])
                let isPrintable = characters.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
                if modifiers.isEmpty && isPrintable {
                    viewModel.recordPrintableInput(characters)
                }
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
    
    // Right-click context menu
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        
        // Use the standard NSTextView selectors for copy/paste
        let copyItem = NSMenuItem(title: "Copy", action: #selector(copy(_:)), keyEquivalent: "")
        copyItem.target = self
        
        let pasteItem = NSMenuItem(title: "Paste", action: #selector(terminalPaste), keyEquivalent: "")
        pasteItem.target = self
        
        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(selectAll(_:)), keyEquivalent: "")
        selectAllItem.target = self
        
        let clearItem = NSMenuItem(title: "Clear", action: #selector(clearTerminal), keyEquivalent: "")
        clearItem.target = self
        
        menu.addItem(copyItem)
        menu.addItem(pasteItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(selectAllItem)
        menu.addItem(clearItem)
        
        return menu
    }
    
    @objc func clearTerminal() {
        textStorage?.setAttributedString(NSAttributedString())
    }
    
    @objc func terminalPaste() {
        if let string = NSPasteboard.general.string(forType: .string) {
            viewModel?.sendInput(string)
            let normalized = string.replacingOccurrences(of: "\n", with: " ")
            viewModel?.recordPrintableInput(normalized)
        }
    }
}

// Custom NSScrollView for terminal with transparent background
class TerminalScrollView: NSScrollView {
    weak var viewModel: TerminalViewModel?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Create the text view
        let textView = TerminalTextView()
        textView.minSize = NSSize(width: 0.0, height: 0.0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        // Configure container
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        self.documentView = textView
    }
}
