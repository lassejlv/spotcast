import Foundation
import SpotcastPluginKit

struct QuickLinkItem: Codable {
    let name: String
    let url: String
    let icon: String?
}

enum QuickLinkStore {
    private static let key = "items"

    static func load(from storage: any PluginStorage) async -> [QuickLinkItem] {
        guard
            let raw = await storage.string(forKey: key),
            let data = raw.data(using: .utf8),
            let decoded = try? JSONDecoder().decode([QuickLinkItem].self, from: data)
        else {
            return []
        }

        return decoded
    }

    static func save(_ items: [QuickLinkItem], to storage: any PluginStorage) async {
        guard let data = try? JSONEncoder().encode(items),
            let raw = String(data: data, encoding: .utf8)
        else {
            return
        }

        await storage.setString(raw, forKey: key)
    }

    static func normalizeURL(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        return "https://\(trimmed)"
    }

    static func bestMatch(query: String, in items: [QuickLinkItem]) -> QuickLinkItem? {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else {
            return nil
        }

        if let exact = items.first(where: { $0.name.lowercased() == q }) { return exact }
        if let prefix = items.first(where: { $0.name.lowercased().hasPrefix(q) }) { return prefix }
        return items.first(where: {
            $0.name.lowercased().contains(q) || $0.url.lowercased().contains(q)
        })
    }
}
