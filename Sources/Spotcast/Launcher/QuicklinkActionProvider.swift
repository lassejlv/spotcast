import Foundation

struct StoredQuicklink: Codable {
    let name: String
    let url: String
    let icon: String?
}

@MainActor
enum QuicklinkActionProvider {
    static func loadActions() async -> [LauncherAction] {
        let storage = LocalPluginStorage(pluginID: "quicklinks")
        guard
            let raw = await storage.string(forKey: "items"),
            let data = raw.data(using: .utf8),
            let items = try? JSONDecoder().decode([StoredQuicklink].self, from: data)
        else {
            return []
        }

        return
            items
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { LauncherAction.quicklink(name: $0.name, url: $0.url, iconSystemName: $0.icon) }
    }
}
