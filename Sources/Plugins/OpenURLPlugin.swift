import Foundation
import SpotcastPluginKit

public struct OpenURLPlugin: SpotcastPlugin {
    public init() {}

    public let metadata = PluginMetadata(
        id: "swift.open-url",
        title: "Open URL",
        subtitle: "Open a URL in your default browser",
        keywords: ["browser", "link", "web"],
        iconSystemName: "link"
    )

    public let fields: [PluginField] = [
        PluginField(
            id: "url",
            label: "URL",
            placeholder: "https://example.com",
            required: true,
            type: .text(multiline: false),
            defaultValue: .string("https://")
        )
    ]

    public func run(context: PluginContext) async throws -> PluginExecutionResult {
        guard
            let value = context.values.string("url")?.trimmingCharacters(
                in: .whitespacesAndNewlines), !value.isEmpty
        else {
            return .message("URL is required")
        }

        let openCount = (await context.storage.number(forKey: "openCount")) ?? 0
        await context.storage.setNumber(openCount + 1, forKey: "openCount")
        await context.storage.setString(value, forKey: "lastURL")

        await context.toaster.show(
            PluginToast(
                title: "Open URL",
                message: "Opening \(value)",
                style: .success
            )
        )
        return .openURL(value)
    }
}
