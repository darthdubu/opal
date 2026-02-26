import Foundation

struct RuntimeStatusBadgeModel {
    let activeShell: String
    let activeShellPath: String
    let attemptedShellPath: String
    let fallbackReason: String
    let seashellVersion: String
    let checkedAt: Date

    static let unavailable = RuntimeStatusBadgeModel(
        activeShell: "zsh",
        activeShellPath: "/bin/zsh",
        attemptedShellPath: "",
        fallbackReason: "status unavailable",
        seashellVersion: "unavailable",
        checkedAt: .distantPast
    )

    var badgeText: String {
        activeShell.lowercased().contains("sea") ? "Sea" : "zsh"
    }

    var diagnosticsText: String {
        let checked = checkedAt == .distantPast
            ? "never"
            : DateFormatter.localizedString(from: checkedAt, dateStyle: .none, timeStyle: .medium)
        let reason = fallbackReason.isEmpty ? "none" : fallbackReason
        let attempted = attemptedShellPath.isEmpty ? "n/a" : attemptedShellPath
        let version = seashellVersion.isEmpty ? "unavailable" : seashellVersion

        return "Shell: \(activeShell)\nPath: \(activeShellPath)\nFallback reason: \(reason)\nAttempted shell: \(attempted)\nSeashell version: \(version)\nLast check: \(checked)"
    }

    var isFallback: Bool {
        !fallbackReason.isEmpty
    }
}

final class RuntimeStatusStore: ObservableObject {
    static let shared = RuntimeStatusStore()

    @Published private(set) var status: RuntimeStatusBadgeModel = .unavailable

    private enum StorageKey {
        static let activeShell = "opal.runtime.activeShell"
        static let activeShellPath = "opal.runtime.activeShellPath"
        static let attemptedShellPath = "opal.runtime.attemptedShellPath"
        static let fallbackReason = "opal.runtime.fallbackReason"
        static let seashellVersion = "opal.runtime.seashellVersion"
        static let checkedAt = "opal.runtime.checkedAt"
    }

    private let defaults = UserDefaults.standard

    private init() {
        loadFromDefaults()
    }

    func update(_ status: RuntimeStatusBadgeModel) {
        self.status = status
        defaults.set(status.activeShell, forKey: StorageKey.activeShell)
        defaults.set(status.activeShellPath, forKey: StorageKey.activeShellPath)
        defaults.set(status.attemptedShellPath, forKey: StorageKey.attemptedShellPath)
        defaults.set(status.fallbackReason, forKey: StorageKey.fallbackReason)
        defaults.set(status.seashellVersion, forKey: StorageKey.seashellVersion)
        defaults.set(status.checkedAt.timeIntervalSince1970, forKey: StorageKey.checkedAt)
    }

    private func loadFromDefaults() {
        guard let activeShell = defaults.string(forKey: StorageKey.activeShell), !activeShell.isEmpty else {
            return
        }

        let checkedAt = Date(timeIntervalSince1970: defaults.double(forKey: StorageKey.checkedAt))
        status = RuntimeStatusBadgeModel(
            activeShell: activeShell,
            activeShellPath: defaults.string(forKey: StorageKey.activeShellPath) ?? "",
            attemptedShellPath: defaults.string(forKey: StorageKey.attemptedShellPath) ?? "",
            fallbackReason: defaults.string(forKey: StorageKey.fallbackReason) ?? "",
            seashellVersion: defaults.string(forKey: StorageKey.seashellVersion) ?? "unavailable",
            checkedAt: checkedAt
        )
    }
}
