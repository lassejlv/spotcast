import Foundation
import SpotcastPluginKit

public enum QuickLinkPlugin {
    public static let commands: [any SpotcastPlugin] = [
        SearchCommand(),
        CreateCommand(),
        DeleteCommand(),
    ]
}

public struct SearchCommand: SpotcastPlugin {
    public init() {}

    public let metadata = PluginMetadata(
        id: "quicklinks.search",
        title: "Search Quicklinks",
        subtitle: "Search and open a saved quicklink",
        keywords: ["quicklink", "bookmark", "link"],
        iconSystemName: "magnifyingglass",
        storageNamespace: "quicklinks"
    )

    public let fields: [PluginField] = [
        PluginField(
            id: "query",
            label: "Quicklink",
            placeholder: "Type quicklink name...",
            required: true,
            type: .text(multiline: false)
        )
    ]

    public func run(context: PluginContext) async throws -> PluginExecutionResult {
        guard let query = context.values.string("query") else {
            return .message("Quicklink query is required")
        }

        let items = await QuickLinkStore.load(from: context.storage)
        guard let match = QuickLinkStore.bestMatch(query: query, in: items) else {
            return .message("No quicklink found for '\(query)'")
        }

        return .openURL(match.url)
    }
}

public struct CreateCommand: SpotcastPlugin {
    public init() {}

    public let metadata = PluginMetadata(
        id: "quicklinks.create",
        title: "Create Quicklink",
        subtitle: "Save a quicklink name and URL",
        keywords: ["quicklink", "bookmark", "new"],
        iconSystemName: "plus.circle",
        storageNamespace: "quicklinks"
    )

    public let fields: [PluginField] = [
        PluginField(
            id: "name",
            label: "Name",
            placeholder: "docs",
            required: true,
            type: .text(multiline: false)
        ),
        PluginField(
            id: "url",
            label: "URL",
            placeholder: "https://example.com",
            required: true,
            type: .text(multiline: false)
        ),
        PluginField(
            id: "icon",
            label: "Icon (SF Symbol)",
            placeholder: "link.circle",
            type: .text(multiline: false),
            defaultValue: .string("link.circle")
        ),
    ]

    public func run(context: PluginContext) async throws -> PluginExecutionResult {
        guard
            let name = context.values.string("name")?.trimmingCharacters(
                in: .whitespacesAndNewlines), !name.isEmpty
        else {
            return .message("Name is required")
        }

        guard
            let rawURL = context.values.string("url")?.trimmingCharacters(
                in: .whitespacesAndNewlines), !rawURL.isEmpty
        else {
            return .message("URL is required")
        }

        let normalizedURL = QuickLinkStore.normalizeURL(rawURL)
        let icon = context.values.string("icon")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
        var items = await QuickLinkStore.load(from: context.storage)

        if let index = items.firstIndex(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            items[index] = QuickLinkItem(name: name, url: normalizedURL, icon: icon)
        } else {
            items.append(QuickLinkItem(name: name, url: normalizedURL, icon: icon))
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        await QuickLinkStore.save(items, to: context.storage)
        await context.toaster.show(
            PluginToast(
                title: "Quicklink Created",
                message: "Saved '\(name)'",
                style: .success
            )
        )
        return .none
    }
}

public struct DeleteCommand: SpotcastPlugin {
    public init() {}

    public let metadata = PluginMetadata(
        id: "quicklinks.delete",
        title: "Delete Quicklink",
        subtitle: "Delete a saved quicklink",
        keywords: ["quicklink", "remove", "delete"],
        iconSystemName: "trash",
        storageNamespace: "quicklinks"
    )

    public let fields: [PluginField] = [
        PluginField(
            id: "name",
            label: "Name",
            placeholder: "docs",
            required: true,
            type: .text(multiline: false)
        )
    ]

    public func run(context: PluginContext) async throws -> PluginExecutionResult {
        guard
            let name = context.values.string("name")?.trimmingCharacters(
                in: .whitespacesAndNewlines), !name.isEmpty
        else {
            return .message("Name is required")
        }

        var items = await QuickLinkStore.load(from: context.storage)
        let startCount = items.count
        items.removeAll { $0.name.caseInsensitiveCompare(name) == .orderedSame }

        guard startCount != items.count else {
            return .message("Quicklink '\(name)' not found")
        }

        await QuickLinkStore.save(items, to: context.storage)
        return .message("Deleted quicklink '\(name)'")
    }
}

extension String {
    fileprivate var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
