import AppKit
import Foundation
import SpotcastPluginKit

enum LauncherActionKind {
    case instant(() -> Void)
    case swiftPlugin(any SpotcastPlugin)
}

struct LauncherAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let keywords: [String]
    let icon: NSImage?
    let appIconPath: String?
    let kind: LauncherActionKind

    static func builtins() -> [LauncherAction] {
        [
            LauncherAction(
                id: "builtin.open-repo",
                title: "Open Spotcast Repo",
                subtitle: "Open this folder in Finder",
                keywords: ["project", "folder", "repo"],
                icon: NSImage(systemSymbolName: "folder", accessibilityDescription: nil),
                appIconPath: nil,
                kind: .instant {
                    NSWorkspace.shared.open(URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
                }
            ),
            LauncherAction(
                id: "builtin.search-google",
                title: "Search Google",
                subtitle: "Open google.com",
                keywords: ["web", "internet"],
                icon: NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil),
                appIconPath: nil,
                kind: .instant {
                    NSWorkspace.shared.open(URL(string: "https://google.com")!)
                }
            ),
            LauncherAction(
                id: "builtin.open-settings",
                title: "Open Launcher Settings",
                subtitle: "Open Spotcast preferences",
                keywords: ["preferences", "hotkey", "config"],
                icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil),
                appIconPath: nil,
                kind: .instant {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            )
        ]
    }

    static func app(_ indexedApp: IndexedApp) -> LauncherAction {
        LauncherAction(
            id: "app:\(indexedApp.path)",
            title: indexedApp.name,
            subtitle: "Open \(indexedApp.path)",
            keywords: ["app", "application", indexedApp.name.lowercased()],
            icon: nil,
            appIconPath: indexedApp.path,
            kind: .instant {
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: indexedApp.path),
                    configuration: .init()
                ) { _, _ in }
            }
        )
    }

    static func plugin(_ command: PluginCommand) -> LauncherAction {
        LauncherAction(
            id: "plugin:\(command.id)",
            title: command.title,
            subtitle: command.subtitle,
            keywords: ["plugin", "command"] + command.keywords,
            icon: NSImage(systemSymbolName: "terminal", accessibilityDescription: nil),
            appIconPath: nil,
            kind: .instant {
                ShellCommandRunner.runDetached(command.command)
            }
        )
    }

    static func setting(_ entry: SystemSettingsEntry) -> LauncherAction {
        LauncherAction(
            id: "setting:\(entry.id)",
            title: entry.title,
            subtitle: "Open System Settings: \(entry.title)",
            keywords: ["system settings", "preferences"] + entry.keywords,
            icon: NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil),
            appIconPath: nil,
            kind: .instant {
                SystemSettingsCatalog.open(entry)
            }
        )
    }

    static func swiftPlugin(_ plugin: any SpotcastPlugin) -> LauncherAction {
        LauncherAction(
            id: "swift-plugin:\(plugin.metadata.id)",
            title: plugin.metadata.title,
            subtitle: plugin.metadata.subtitle,
            keywords: ["swift", "plugin"] + plugin.metadata.keywords,
            icon: plugin.metadata.iconSystemName.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: nil) }
                ?? NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: nil),
            appIconPath: nil,
            kind: .swiftPlugin(plugin)
        )
    }
}
