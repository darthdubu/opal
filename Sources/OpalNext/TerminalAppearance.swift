import AppKit
import Foundation

enum CursorStyle: String, CaseIterable {
    case block = "Block"
    case bar = "Bar"
    case underline = "Underline"
}

final class TerminalAppearanceSettings: ObservableObject {
    static let shared = TerminalAppearanceSettings()

    @Published var fontFamily: String = "SF Mono" { didSet { persistIfReady() } }
    @Published var fontSize: Double = 14.0 { didSet { persistIfReady() } }
    @Published var cursorStyle: CursorStyle = .block { didSet { persistIfReady() } }
    @Published var cursorBlink: Bool = true { didSet { persistIfReady() } }

    static let commonMonospaceFamilies: [String] = [
        "SF Mono",
        "Menlo",
        "Monaco",
        "JetBrains Mono",
        "Fira Code",
        "Hack",
        "Source Code Pro",
    ]

    private enum StorageKey {
        static let fontFamily = "opal.terminal.fontFamily"
        static let fontSize = "opal.terminal.fontSize"
        static let cursorStyle = "opal.terminal.cursorStyle"
        static let cursorBlink = "opal.terminal.cursorBlink"
    }

    private let defaults = UserDefaults.standard
    private var hydrating = false

    private init() {
        hydrateFromDefaults()
    }

    func resolvedFont(weight: NSFont.Weight = .regular) -> NSFont {
        let clampedSize = min(32, max(10, fontSize))

        if let named = NSFont(name: fontFamily, size: clampedSize) {
            return named
        }

        return NSFont.monospacedSystemFont(ofSize: clampedSize, weight: weight)
    }

    private func hydrateFromDefaults() {
        hydrating = true
        defer { hydrating = false }

        if let storedFamily = defaults.string(forKey: StorageKey.fontFamily), !storedFamily.isEmpty {
            fontFamily = storedFamily
        }

        if defaults.object(forKey: StorageKey.fontSize) != nil {
            fontSize = min(32, max(10, defaults.double(forKey: StorageKey.fontSize)))
        }

        if let storedStyle = defaults.string(forKey: StorageKey.cursorStyle),
           let style = CursorStyle(rawValue: storedStyle) {
            cursorStyle = style
        }

        if defaults.object(forKey: StorageKey.cursorBlink) != nil {
            cursorBlink = defaults.bool(forKey: StorageKey.cursorBlink)
        }
    }

    private func persistIfReady() {
        guard !hydrating else { return }

        defaults.set(fontFamily, forKey: StorageKey.fontFamily)
        defaults.set(fontSize, forKey: StorageKey.fontSize)
        defaults.set(cursorStyle.rawValue, forKey: StorageKey.cursorStyle)
        defaults.set(cursorBlink, forKey: StorageKey.cursorBlink)
    }
}
