import AppKit
import Foundation
import Plugins
import SpotcastPluginKit

struct PluginFormSession: Identifiable {
    let id = UUID()
    let plugin: any SpotcastPlugin
}

struct RuntimePluginToaster: PluginToaster {
    func show(_ toast: PluginToast) async {
        await MainActor.run {
            ToastCenter.shared.push(toast)
        }
    }
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
            let namespace = plugin.metadata.storageNamespace ?? plugin.metadata.id
            let storage = LocalPluginStorage(pluginID: namespace)
            let context = PluginContext(
                values: PluginInputValues(storage: values),
                workspacePath: FileManager.default.currentDirectoryPath,
                storage: storage,
                toaster: RuntimePluginToaster()
            )
            let result = try await plugin.run(context: context)
            return handle(result)
        } catch {
            ToastCenter.shared.push(
                PluginToast(
                    title: "Plugin Error",
                    message: error.localizedDescription,
                    style: .error,
                    duration: 2.6
                )
            )
            return nil
        }
    }

    private static func handle(_ result: PluginExecutionResult) -> String? {
        switch result {
        case .none:
            return nil
        case .openURL(let raw):
            guard let url = normalizedURL(raw) else {
                ToastCenter.shared.push(
                    PluginToast(
                        title: "Open URL",
                        message: "Invalid URL",
                        style: .error
                    )
                )
                return nil
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
            ToastCenter.shared.push(
                PluginToast(
                    title: "Clipboard",
                    message: "Copied to clipboard",
                    style: .success
                )
            )
            return nil
        case .message(let message):
            ToastCenter.shared.push(
                PluginToast(
                    title: "Spotcast",
                    message: message,
                    style: .info
                )
            )
            return nil
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
