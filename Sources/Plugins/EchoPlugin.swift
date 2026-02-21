import Foundation
import SpotcastPluginKit

public struct EchoPlugin: SpotcastPlugin {
    public init() {}

    public let metadata = PluginMetadata(
        id: "swift.echo",
        title: "Echo Message",
        subtitle: "Copy text to clipboard",
        keywords: ["clipboard", "copy", "text"],
        iconSystemName: "doc.on.doc"
    )

    public let fields: [PluginField] = [
        PluginField(
            id: "text",
            label: "Text",
            placeholder: "What should be copied?",
            required: true,
            type: .text(multiline: true)
        )
    ]

    public func run(context: PluginContext) async throws -> PluginExecutionResult {
        guard let text = context.values.string("text"), !text.isEmpty else {
            return .message("Text is required")
        }

        return .copyToClipboard(text)
    }
}
