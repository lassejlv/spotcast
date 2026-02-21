import Combine
import Foundation
import SpotcastPluginKit

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var query = "" {
        didSet {
            rebuildFilteredActions(resetSelection: true)
        }
    }

    @Published private(set) var selectedIndex = 0
    @Published private(set) var selectedActionID: String?
    @Published private(set) var scrollTargetActionID: String?
    @Published private(set) var actions: [LauncherAction] = LauncherAction.builtins() {
        didSet {
            rebuildFilteredActions(resetSelection: false)
        }
    }
    @Published private(set) var filteredActions: [LauncherAction] = []
    @Published var pluginFormSession: PluginFormSession?
    @Published var statusMessage: String?

    private let usageStore = ActionUsageStore.shared
    private let pluginSettings = PluginSettings.shared
    private var cachedQuicklinkActions: [LauncherAction] = []
    private var cachedAppActions: [LauncherAction] = []
    private var lastAppRefreshAt: Date?
    private var isRefreshingApps = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        pluginSettings.$disabledActionIDs
            .sink { [weak self] _ in
                guard let self else { return }
                self.actions =
                    self.baseActions() + self.cachedQuicklinkActions + self.cachedAppActions
            }
            .store(in: &cancellables)

        rebuildFilteredActions(resetSelection: true)
    }

    func prepareForPresentation() {
        selectedIndex = 0
        selectedActionID = nil
        scrollTargetActionID = nil
        query = ""
        actions = baseActions() + cachedQuicklinkActions + cachedAppActions
        refreshQuicklinks()
        refreshCatalogIfNeeded()
    }

    private func refreshCatalogIfNeeded() {
        let now = Date()
        if let last = lastAppRefreshAt, now.timeIntervalSince(last) < 60, !cachedAppActions.isEmpty
        {
            return
        }
        refreshCatalog()
    }

    func refreshCatalog() {
        guard !isRefreshingApps else {
            return
        }

        isRefreshingApps = true
        actions = baseActions() + cachedQuicklinkActions + cachedAppActions

        Task.detached(priority: .utility) {
            let appActions = AppIndexer.installedApps().map(LauncherAction.app)

            await MainActor.run {
                self.cachedAppActions = appActions
                self.lastAppRefreshAt = Date()
                self.actions = self.baseActions() + self.cachedQuicklinkActions + appActions
                self.isRefreshingApps = false
            }
        }
    }

    private func refreshQuicklinks() {
        Task {
            let quicklinkActions = await QuicklinkActionProvider.loadActions()
            await MainActor.run {
                self.cachedQuicklinkActions = quicklinkActions
                self.actions = self.baseActions() + quicklinkActions + self.cachedAppActions
            }
        }
    }

    private func baseActions() -> [LauncherAction] {
        let scriptPluginActions = PluginCommandLoader.load()
            .map(LauncherAction.plugin)
            .filter { pluginSettings.isEnabled(actionID: $0.id) }
        let settingsActions = SystemSettingsCatalog.entries().map(LauncherAction.setting)
        let swiftPluginActions = SwiftPluginRuntime.plugins()
            .map(LauncherAction.swiftPlugin)
            .filter { pluginSettings.isEnabled(actionID: $0.id) }
        return LauncherAction.builtins() + swiftPluginActions + settingsActions
            + scriptPluginActions
    }

    func moveSelection(up: Bool) {
        guard !filteredActions.isEmpty else {
            selectedIndex = 0
            selectedActionID = nil
            scrollTargetActionID = nil
            return
        }

        let count = filteredActions.count
        let nextIndex: Int
        if up {
            nextIndex = (selectedIndex - 1 + count) % count
        } else {
            nextIndex = (selectedIndex + 1) % count
        }

        updateSelection(index: nextIndex, requestScroll: true)
    }

    func executeSelected() -> Bool {
        guard filteredActions.indices.contains(selectedIndex) else {
            return false
        }

        return execute(action: filteredActions[selectedIndex])
    }

    func execute(at index: Int) -> Bool {
        guard filteredActions.indices.contains(index) else {
            return false
        }

        updateSelection(index: index)
        return execute(action: filteredActions[index])
    }

    func execute(actionID: String) -> Bool {
        guard let index = filteredActions.firstIndex(where: { $0.id == actionID }) else {
            return false
        }

        return execute(at: index)
    }

    func select(actionID: String) {
        guard let index = filteredActions.firstIndex(where: { $0.id == actionID }) else {
            return
        }

        updateSelection(index: index)
    }

    func dismissPluginForm() {
        pluginFormSession = nil
    }

    func submitPluginForm(values: [String: PluginFieldValue]) -> Bool {
        guard let session = pluginFormSession else {
            return false
        }

        pluginFormSession = nil
        executePlugin(session.plugin, values: values)
        return true
    }

    private func execute(action: LauncherAction) -> Bool {
        usageStore.recordExecution(for: action.id)

        switch action.kind {
        case .instant(let run):
            run()
            return true
        case .swiftPlugin(let plugin):
            if plugin.fields.isEmpty {
                executePlugin(plugin, values: [:])
                return true
            }

            pluginFormSession = PluginFormSession(plugin: plugin)
            return false
        }
    }

    private func executePlugin(_ plugin: any SpotcastPlugin, values: [String: PluginFieldValue]) {
        Task {
            let message = await SwiftPluginRuntime.execute(plugin: plugin, values: values)
            await MainActor.run {
                self.showStatus(message)
                self.refreshQuicklinks()
            }
        }
    }

    private func showStatus(_ message: String?) {
        guard let message, !message.isEmpty else {
            return
        }

        statusMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await MainActor.run {
                if self.statusMessage == message {
                    self.statusMessage = nil
                }
            }
        }
    }

    private func rebuildFilteredActions(resetSelection: Bool) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let scored: [(action: LauncherAction, score: Double)] = actions.compactMap { action in
            let matchScore = SearchScorer.score(action: action, query: trimmed)
            if !trimmed.isEmpty && matchScore <= 0 {
                return nil
            }

            let usageBoost = usageStore.rankingBoost(for: action.id)
            return (action, matchScore + usageBoost)
        }

        filteredActions =
            scored
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.action.title.localizedCaseInsensitiveCompare(rhs.action.title)
                        == .orderedAscending
                }
                return lhs.score > rhs.score
            }
            .map(\.action)

        if filteredActions.isEmpty {
            selectedIndex = 0
            selectedActionID = nil
            scrollTargetActionID = nil
            return
        }

        if resetSelection {
            updateSelection(index: 0)
            return
        }

        if let selectedActionID,
            let existingIndex = filteredActions.firstIndex(where: { $0.id == selectedActionID })
        {
            updateSelection(index: existingIndex)
        } else {
            updateSelection(index: min(selectedIndex, filteredActions.count - 1))
        }
    }

    private func updateSelection(index: Int) {
        guard filteredActions.indices.contains(index) else {
            selectedIndex = 0
            selectedActionID = nil
            scrollTargetActionID = nil
            return
        }

        selectedIndex = index
        selectedActionID = filteredActions[index].id
    }

    private func updateSelection(index: Int, requestScroll: Bool) {
        updateSelection(index: index)
        if requestScroll {
            scrollTargetActionID = selectedActionID
        }
    }

    func consumeScrollTarget() {
        scrollTargetActionID = nil
    }
}
