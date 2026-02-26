import Foundation

struct TabSession: Identifiable {
    let id: UUID
    let terminalVM: TerminalViewModel

    init(id: UUID = UUID(), terminalVM: TerminalViewModel = TerminalViewModel()) {
        self.id = id
        self.terminalVM = terminalVM
    }

    var title: String {
        let directoryName = URL(fileURLWithPath: terminalVM.currentDirectory).lastPathComponent
        return directoryName.isEmpty ? "Terminal" : directoryName
    }
}

final class TabStore: ObservableObject {
    @Published private(set) var tabs: [TabSession] = [TabSession()]
    @Published var selectedTabID: UUID = UUID()

    init() {
        selectedTabID = tabs[0].id
    }

    var selectedTab: TabSession {
        if let tab = tabs.first(where: { $0.id == selectedTabID }) {
            return tab
        }
        return tabs[0]
    }

    @discardableResult
    func newTab() -> TabSession {
        let tab = TabSession()
        tabs.append(tab)
        selectedTabID = tab.id
        return tab
    }

    func close(tabID: UUID) {
        guard tabs.count > 1 else { return }
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }

        let wasSelected = tabID == selectedTabID
        tabs.remove(at: index)

        if wasSelected {
            let nextIndex = min(index, tabs.count - 1)
            selectedTabID = tabs[nextIndex].id
        }
    }

    func closeSelectedTab() {
        close(tabID: selectedTabID)
    }
}
