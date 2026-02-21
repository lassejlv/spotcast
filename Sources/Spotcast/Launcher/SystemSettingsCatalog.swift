import AppKit
import Foundation

struct SystemSettingsEntry {
    let id: String
    let title: String
    let keywords: [String]
    let deeplink: String?
}

enum SystemSettingsCatalog {
    static func entries() -> [SystemSettingsEntry] {
        [
            SystemSettingsEntry(id: "open", title: "System Settings", keywords: ["preferences", "settings"], deeplink: nil),
            SystemSettingsEntry(id: "appearance", title: "Appearance", keywords: ["theme", "dark mode", "light mode"], deeplink: "x-apple.systempreferences:com.apple.Appearance-Settings.extension"),
            SystemSettingsEntry(id: "control-center", title: "Control Center", keywords: ["menu bar", "status"], deeplink: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"),
            SystemSettingsEntry(id: "desktop-dock", title: "Desktop & Dock", keywords: ["dock", "desktop", "stage manager"], deeplink: "x-apple.systempreferences:com.apple.Desktop-Settings.extension"),
            SystemSettingsEntry(id: "displays", title: "Displays", keywords: ["screen", "resolution", "monitor"], deeplink: "x-apple.systempreferences:com.apple.Displays-Settings.extension"),
            SystemSettingsEntry(id: "keyboard", title: "Keyboard", keywords: ["shortcuts", "key repeat", "input"], deeplink: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"),
            SystemSettingsEntry(id: "mouse", title: "Mouse", keywords: ["pointer", "scroll"], deeplink: "x-apple.systempreferences:com.apple.Mouse-Settings.extension"),
            SystemSettingsEntry(id: "trackpad", title: "Trackpad", keywords: ["gestures", "scroll"], deeplink: "x-apple.systempreferences:com.apple.Trackpad-Settings.extension"),
            SystemSettingsEntry(id: "network", title: "Network", keywords: ["wifi", "ethernet", "vpn"], deeplink: "x-apple.systempreferences:com.apple.Network-Settings.extension"),
            SystemSettingsEntry(id: "bluetooth", title: "Bluetooth", keywords: ["airpods", "devices"], deeplink: "x-apple.systempreferences:com.apple.BluetoothSettings"),
            SystemSettingsEntry(id: "sound", title: "Sound", keywords: ["audio", "volume", "mic"], deeplink: "x-apple.systempreferences:com.apple.Sound-Settings.extension"),
            SystemSettingsEntry(id: "notifications", title: "Notifications", keywords: ["alerts", "do not disturb", "focus"], deeplink: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"),
            SystemSettingsEntry(id: "privacy", title: "Privacy & Security", keywords: ["permissions", "security", "files"], deeplink: "x-apple.systempreferences:com.apple.PrivacySecurity-Settings.extension")
        ]
    }

    static func open(_ entry: SystemSettingsEntry) {
        if
            let deeplink = entry.deeplink,
            let url = URL(string: deeplink),
            NSWorkspace.shared.open(url)
        {
            return
        }

        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/System Settings.app"),
            configuration: .init()
        ) { _, _ in }
    }
}
