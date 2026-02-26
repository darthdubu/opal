import AppKit
import OpalCore
import SwiftUI

struct TerminalView: NSViewRepresentable {
    @ObservedObject var viewModel: TerminalViewModel
    @ObservedObject private var appearance = TerminalAppearanceSettings.shared

    var refreshTrigger: Int

    func makeNSView(context: Context) -> TerminalScrollView {
        let scrollView = TerminalScrollView()
        scrollView.viewModel = viewModel
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear

        guard let textView = scrollView.documentView as? TerminalTextView else {
            return scrollView
        }

        textView.viewModel = viewModel
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.font = appearance.resolvedFont()
        textView.allowsUndo = false

        return scrollView
    }

    func updateNSView(_ nsView: TerminalScrollView, context: Context) {
        _ = refreshTrigger

        guard let terminalHandle = viewModel.terminalHandle,
              let textView = nsView.documentView as? TerminalTextView else {
            return
        }

        let bodyFont = appearance.resolvedFont()
        textView.font = bodyFont

        let rows = Int(terminalHandle.rows())
        let cols = Int(terminalHandle.cols())
        let cursorRow = Int(terminalHandle.cursorRow())
        let cursorCol = Int(terminalHandle.cursorCol())

        let shouldDrawCursor = terminalHandle.cursorVisible()
            && (!appearance.cursorBlink || viewModel.cursorBlinkVisible)

        let renderEndRow = max(findLastContentRow(rows: rows, cols: cols, terminalHandle: terminalHandle), cursorRow) + 2
        let attributed = NSMutableAttributedString()

        for row in 0..<min(renderEndRow, rows) {
            let rowAttributed = NSMutableAttributedString()

            for col in 0..<cols {
                guard let cell = terminalHandle.cellAt(col: UInt32(col), row: UInt32(row)) else {
                    continue
                }

                let isCursorCell = shouldDrawCursor && row == cursorRow && col == cursorCol
                let tuple = styledCharacter(for: cell, isCursorCell: isCursorCell, font: bodyFont)
                let char = tuple.character
                let attrs = tuple.attributes
                rowAttributed.append(NSAttributedString(string: char, attributes: attrs))
            }

            attributed.append(rowAttributed)
            if row < min(renderEndRow, rows) - 1 {
                attributed.append(NSAttributedString(string: "\n"))
            }
        }

        if !textView.hasSameContent(as: attributed) {
            textView.textStorage?.setAttributedString(attributed)
        }

        let renderedRows = min(renderEndRow, rows)
        if renderedRows > 0 && cols > 0 {
            let safeRow = max(0, min(cursorRow, renderedRows - 1))
            let safeCol = max(0, min(cursorCol, cols - 1))
            let rowSpan = cols + 1
            let cursorIndex = min(attributed.length, safeRow * rowSpan + safeCol)
            textView.scrollRangeToVisible(NSRange(location: cursorIndex, length: 0))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func findLastContentRow(rows: Int, cols: Int, terminalHandle: TerminalHandleLite) -> Int {
        for row in (0..<rows).reversed() {
            for col in 0..<cols {
                if let cell = terminalHandle.cellAt(col: UInt32(col), row: UInt32(row)), cell.content != " " {
                    return row
                }
            }
        }
        return 0
    }

    private func styledCharacter(for cell: TerminalCell,
                                 isCursorCell: Bool,
                                 font: NSFont) -> (character: String, attributes: [NSAttributedString.Key: Any]) {
        var character = String(cell.content)
        let foreground = nsColor(from: cell.foreground)
        let background = (cell.background == .default) ? NSColor.clear : nsColor(from: cell.background)

        var attrs: [NSAttributedString.Key: Any] = [
            .font: cell.bold ? appearance.resolvedFont(weight: .bold) : font,
            .foregroundColor: foreground,
            .backgroundColor: background,
        ]

        if isCursorCell {
            switch appearance.cursorStyle {
            case .block:
                attrs[.foregroundColor] = NSColor.black
                attrs[.backgroundColor] = NSColor.white
            case .bar:
                character = "▏"
                attrs[.foregroundColor] = NSColor.white
                attrs[.backgroundColor] = NSColor.clear
            case .underline:
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                attrs[.underlineColor] = NSColor.white
            }
        }

        return (character, attrs)
    }

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
            return indexedColor(index)
        case .rgb(let r, let g, let b):
            return NSColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
        }
    }

    private func indexedColor(_ index: UInt8) -> NSColor {
        if index < 16 {
            let colors: [NSColor] = [
                .black, .red, .green, .yellow, .blue, .magenta, .cyan, .white,
                NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1),
                NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1),
                NSColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1),
                NSColor(red: 1.0, green: 1.0, blue: 0.4, alpha: 1),
                NSColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1),
                NSColor(red: 1.0, green: 0.4, blue: 1.0, alpha: 1),
                NSColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1),
                NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
            ]
            return colors[Int(index)]
        }

        if index < 232 {
            let idx = Int(index - 16)
            let r = CGFloat(idx / 36) / 5.0
            let g = CGFloat((idx % 36) / 6) / 5.0
            let b = CGFloat(idx % 6) / 5.0
            return NSColor(red: r, green: g, blue: b, alpha: 1)
        }

        let gray = CGFloat(index - 232) / 23.0
        return NSColor(red: gray, green: gray, blue: gray, alpha: 1)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TerminalView

        init(_ parent: TerminalView) {
            self.parent = parent
        }
    }
}

final class TerminalTextView: NSTextView {
    weak var viewModel: TerminalViewModel?

    override var acceptsFirstResponder: Bool { true }

    func hasSameContent(as attributedString: NSAttributedString) -> Bool {
        guard let current = textStorage else { return false }
        return current.isEqual(to: attributedString)
    }

    override func keyDown(with event: NSEvent) {
        guard let viewModel else {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 36:
            viewModel.recordSubmit()
            viewModel.sendInput("\r")
        case 51:
            viewModel.recordBackspace()
            viewModel.sendInput("\u{7f}")
        case 48:
            viewModel.sendInput("\t")
        case 49:
            viewModel.recordPrintableInput(" ")
            viewModel.sendInput(" ")
        case 53:
            viewModel.sendInput("\u{1b}")
        case 126:
            viewModel.sendInput("\u{1b}[A")
        case 125:
            viewModel.sendInput("\u{1b}[B")
        case 124:
            viewModel.sendInput("\u{1b}[C")
        case 123:
            viewModel.sendInput("\u{1b}[D")
        default:
            if let characters = event.characters {
                viewModel.sendInput(characters)

                let modifiers = event.modifierFlags.intersection([.command, .control])
                let isPrintable = characters.unicodeScalars.allSatisfy {
                    !CharacterSet.controlCharacters.contains($0)
                }

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

    @objc func terminalPaste() {
        if let value = NSPasteboard.general.string(forType: .string) {
            viewModel?.sendInput(value)
            viewModel?.recordPrintableInput(value.replacingOccurrences(of: "\n", with: " "))
        }
    }
}

final class TerminalScrollView: NSScrollView {
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
        let textView = TerminalTextView()
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainerInset = NSSize(width: 10, height: 10)

        documentView = textView
    }
}
