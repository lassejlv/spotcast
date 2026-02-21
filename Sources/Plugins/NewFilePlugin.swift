import Foundation
import SpotcastPluginKit

public struct NewFilePlugin: SpotcastPlugin {
    public init() {}

    public let metadata = PluginMetadata(
        id: "swift.new-file",
        title: "Create File",
        subtitle: "Create a file in current workspace",
        keywords: ["touch", "file", "workspace"],
        iconSystemName: "doc.badge.plus"
    )

    public let fields: [PluginField] = [
        PluginField(
            id: "name",
            label: "File name",
            placeholder: "notes.txt",
            required: true,
            type: .text(multiline: false)
        ),
        PluginField(
            id: "content",
            label: "Content",
            placeholder: "Optional file content",
            type: .text(multiline: true)
        )
    ]

    public func run(context: PluginContext) async throws -> PluginExecutionResult {
        guard let name = context.values.string("name")?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return .message("File name is required")
        }

        let escapedPath = "\(context.workspacePath)/\(name)".replacingOccurrences(of: "\"", with: "\\\"")
        let content = context.values.string("content") ?? ""

        if content.isEmpty {
            return .runShell("touch \"\(escapedPath)\"")
        }

        let escapedContent = content.replacingOccurrences(of: "\"", with: "\\\"")
        return .runShell("printf \"%s\" \"\(escapedContent)\" > \"\(escapedPath)\"")
    }
}
