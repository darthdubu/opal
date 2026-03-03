import AutoUpdate
import Combine
import Foundation

@MainActor
final class SunshineUpdateStore: ObservableObject {
    static let shared = SunshineUpdateStore()

    @Published private(set) var snapshot: UpdateStateSnapshot = .idle
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var configured = false

    private var manager: AutoUpdateManager?
    private var cancellables = Set<AnyCancellable>()

    private enum DefaultsKey {
        static let owner = "opal.updates.owner"
        static let repository = "opal.updates.repository"
        static let publicKey = "opal.updates.publicKey"
        static let launchChecks = "opal.updates.launchChecks"
    }

    private init() {
        if UserDefaults.standard.object(forKey: DefaultsKey.owner) == nil {
            UserDefaults.standard.set("darthdubu", forKey: DefaultsKey.owner)
        }
        if UserDefaults.standard.object(forKey: DefaultsKey.repository) == nil {
            UserDefaults.standard.set("opal", forKey: DefaultsKey.repository)
        }
        if UserDefaults.standard.object(forKey: DefaultsKey.launchChecks) == nil {
            UserDefaults.standard.set(true, forKey: DefaultsKey.launchChecks)
        }
        rebuildManager()
    }

    var owner: String { UserDefaults.standard.string(forKey: DefaultsKey.owner) ?? "" }
    var repository: String { UserDefaults.standard.string(forKey: DefaultsKey.repository) ?? "" }
    var publicKey: String { UserDefaults.standard.string(forKey: DefaultsKey.publicKey) ?? "" }
    var launchChecksEnabled: Bool { UserDefaults.standard.bool(forKey: DefaultsKey.launchChecks) }

    func applyConfiguration(owner: String, repository: String, publicKey: String, launchChecksEnabled: Bool) {
        UserDefaults.standard.set(owner.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.owner)
        UserDefaults.standard.set(repository.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.repository)
        UserDefaults.standard.set(publicKey.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.publicKey)
        UserDefaults.standard.set(launchChecksEnabled, forKey: DefaultsKey.launchChecks)
        rebuildManager()
    }

    func checkNow() {
        guard let manager else { return }
        Task { await manager.checkForUpdates() }
    }

    func downloadUpdate() {
        guard let manager else { return }
        Task { await manager.downloadUpdate() }
    }

    func installUpdate() {
        guard let manager else { return }
        Task { await manager.installUpdate() }
    }

    private func rebuildManager() {
        cancellables.removeAll()
        snapshot = .idle
        lastErrorMessage = nil

        let owner = self.owner
        let repository = self.repository
        let publicKey = self.publicKey
        guard !owner.isEmpty, !repository.isEmpty else {
            configured = false
            manager = nil
            return
        }

        let config = AutoUpdateConfiguration(
            owner: owner,
            repository: repository,
            currentVersion: opalVersion,
            appName: "Opal",
            userAgent: "Opal/\(opalVersion)",
            publicKey: publicKey.isEmpty ? nil : publicKey,
            automaticLaunchCheckEnabled: launchChecksEnabled
        )
        let manager = AutoUpdateManager(configuration: config)
        self.manager = manager
        configured = true

        manager.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
                self?.lastErrorMessage = snapshot.error?.userMessage
            }
            .store(in: &cancellables)

        manager.performLaunchCheck()
    }
}
