import Foundation
import OpalCore

struct ShellRuntimeStatusLite {
    let activeShell: String
    let activeShellPath: String
    let attemptedShellPath: String
    let fallbackReason: String
    let seashellVersion: String
}

final class PtySessionLite {
    private let session: PtySession

    init(cols: UInt32, rows: UInt32, preferredShell: String) {
        let trimmed = preferredShell.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            session = PtySession(cols: cols, rows: rows)
        } else {
            session = PtySession.newWithShell(cols: cols, rows: rows, preferredShell: trimmed)
        }
    }

    func read() -> Data {
        session.read()
    }

    func write(_ data: Data) {
        session.write(data: data)
    }

    func resize(cols: UInt32, rows: UInt32) {
        session.resize(cols: cols, rows: rows)
    }

    func isAlive() -> Bool {
        session.isAlive()
    }

    func shellRuntimeStatus() -> ShellRuntimeStatusLite {
        let status = session.shellRuntimeStatus()
        return ShellRuntimeStatusLite(
            activeShell: status.activeShell,
            activeShellPath: status.activeShellPath,
            attemptedShellPath: status.attemptedShellPath,
            fallbackReason: status.fallbackReason,
            seashellVersion: status.seashellVersion
        )
    }

    func terminal() -> TerminalHandleLite {
        TerminalHandleLite(handle: session.getTerminal())
    }
}

final class TerminalHandleLite {
    private let handle: TerminalHandle

    init(handle: TerminalHandle) {
        self.handle = handle
    }

    func processInputWithResponses(data: Data) -> Data {
        handle.processInputWithResponses(data: data)
    }

    func rows() -> UInt32 {
        handle.rows()
    }

    func cols() -> UInt32 {
        handle.cols()
    }

    func cursorRow() -> UInt32 {
        handle.cursorRow()
    }

    func cursorCol() -> UInt32 {
        handle.cursorCol()
    }

    func cursorVisible() -> Bool {
        handle.cursorVisible()
    }

    func cellAt(col: UInt32, row: UInt32) -> TerminalCell? {
        handle.cellAt(col: col, row: row)
    }

    func currentDirectory() -> String {
        handle.currentDirectory()
    }

    func resize(cols: UInt32, rows: UInt32) {
        handle.resize(cols: cols, rows: rows)
    }
}
