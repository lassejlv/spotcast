import Foundation

@MainActor
final class PluginSettings: ObservableObject {
    static let shared = PluginSettings()

    @Published private(set) var disabledActionIDs: Set<String>

    private let defaults: UserDefaults
    private let disabledKey = "plugins.disabledActionIDs"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.stringArray(forKey: disabledKey) ?? []
        self.disabledActionIDs = Set(raw)
    }

    func isEnabled(actionID: String) -> Bool {
        !disabledActionIDs.contains(actionID)
    }

    func setEnabled(_ enabled: Bool, actionID: String) {
        if enabled {
            disabledActionIDs.remove(actionID)
        } else {
            disabledActionIDs.insert(actionID)
        }
        persist()
    }

    private func persist() {
        defaults.set(Array(disabledActionIDs).sorted(), forKey: disabledKey)
    }
}
