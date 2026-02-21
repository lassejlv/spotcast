import AppKit
import Foundation
import Plugins
import SpotcastPluginKit

struct PluginFormSession: Identifiable {
    let id = UUID()
    let plugin: any SpotcastPlugin
}

@MainActor
enum SwiftPluginRuntime {
    static func plugins() -> [any SpotcastPlugin] {
        PluginRegistry.all
    }

    static func execute(plugin: any SpotcastPlugin, values: [String: PluginFieldValue]) async
        -> String?
    {
        do {
            let storage = LocalPluginStorage(pluginID: plugin.metadata.id)
            let context = PluginContext(
                values: PluginInputValues(storage: values),
                workspacePath: FileManager.default.currentDirectoryPath,
                storage: storage
            )
            let result = try await plugin.run(context: context)
            return handle(result)
        } catch {
            return error.localizedDescription
        }
    }

    private static func handle(_ result: PluginExecutionResult) -> String? {
        switch result {
        case .none:
            return nil
        case .openURL(let raw):
            guard let url = normalizedURL(raw) else {
                return "Invalid URL"
            }
            NSWorkspace.shared.open(url)
            return nil
        case .runShell(let command):
            ShellCommandRunner.runDetached(command)
            return nil
        case .copyToClipboard(let text):
            let board = NSPasteboard.general
            board.clearContents()
            board.setString(text, forType: .string)
            return "Copied to clipboard"
        case .message(let message):
            return message
        }
    }

    private static func normalizedURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let direct = URL(string: trimmed), direct.scheme != nil {
            return direct
        }

        return URL(string: "https://\(trimmed)")
    }
}
