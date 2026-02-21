import Plugins
import SwiftUI

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case launcher
    case plugins
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .launcher: "Launcher"
        case .plugins: "Plugins"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .general: "switch.2"
        case .launcher: "sparkles"
        case .plugins: "puzzlepiece.extension"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: HotKeySettings
    @ObservedObject var pluginSettings: PluginSettings
    @State private var selection: SettingsPane? = .launcher
    @AppStorage("ui.animateLauncher") private var animateLauncher = true
    @AppStorage("ui.centerLauncher") private var centerLauncher = true

    private var scriptPlugins: [PluginCommand] {
        PluginCommandLoader.load()
    }

    var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, selection: $selection) { pane in
                Label(pane.title, systemImage: pane.icon)
                    .tag(pane)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selection ?? .launcher {
                    case .general:
                        generalPane
                    case .launcher:
                        launcherPane
                    case .plugins:
                        pluginsPane
                    case .about:
                        aboutPane
                    }
                }
                .padding(22)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 900, minHeight: 560)
    }

    private var generalPane: some View {
        settingsCard(title: "Interface") {
            Toggle("Animate launcher", isOn: $animateLauncher)
            Toggle("Center launcher panel", isOn: $centerLauncher)
        }
    }

    private var launcherPane: some View {
        settingsCard(title: "Hotkey") {
            Picker("Modifier", selection: Binding(
                get: { settings.selectedModifierPreset },
                set: { settings.update(modifierPreset: $0) }
            )) {
                ForEach(HotKeyModifierPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }

            Picker("Key", selection: Binding(
                get: { settings.selectedKeyPreset },
                set: { settings.update(keyPreset: $0) }
            )) {
                ForEach(HotKeyKeyPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }

            Text("Current: \(settings.selectedModifierPreset.title) + \(settings.selectedKeyPreset.title)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private var pluginsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsCard(title: "Swift Plugins") {
                ForEach(PluginRegistry.all, id: \.metadata.id) { plugin in
                    let actionID = "swift-plugin:\(plugin.metadata.id)"
                    Toggle(
                        isOn: Binding(
                            get: { pluginSettings.isEnabled(actionID: actionID) },
                            set: { pluginSettings.setEnabled($0, actionID: actionID) }
                        )
                    ) {
                        HStack(spacing: 10) {
                            Image(systemName: plugin.metadata.iconSystemName ?? "wand.and.stars")
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plugin.metadata.title)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(plugin.metadata.subtitle)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                }
            }

            settingsCard(title: "Script Plugins") {
                if scriptPlugins.isEmpty {
                    Text("No script plugins found in config/commands.json or config/commands.toml")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(scriptPlugins, id: \.id) { plugin in
                        let actionID = "plugin:\(plugin.id)"
                        Toggle(
                            isOn: Binding(
                                get: { pluginSettings.isEnabled(actionID: actionID) },
                                set: { pluginSettings.setEnabled($0, actionID: actionID) }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plugin.title)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(plugin.subtitle)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }
            }

            settingsCard(title: "Paths") {
                pathRow("Swift plugin source", value: "Sources/Plugins")
                pathRow("Script plugin config", value: "config/commands.json | config/commands.toml")
                pathRow("Plugin storage", value: "~/Library/Application Support/spotcast/plugin-storage")
            }
        }
    }

    private var aboutPane: some View {
        settingsCard(title: "Spotcast") {
            Text("Raycast-style Swift launcher with SwiftUI plugin forms.")
                .font(.system(size: 13, weight: .regular))
            Text("Version: dev")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            content()
        }
        .padding(16)
        .frame(maxWidth: 760, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func pathRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .regular))
                .textSelection(.enabled)
        }
    }
}
