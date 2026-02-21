import AppKit

func openSettingsWindow() {
    Task { @MainActor in
        NSApp.activate(ignoringOtherApps: true)

        let selectors = [
            Selector(("showSettingsWindow:")),
            Selector(("showPreferencesWindow:")),
        ]

        for selector in selectors {
            if NSApp.sendAction(selector, to: nil, from: nil) {
                return
            }
        }

        NSApp.sendAction(Selector(("showSettingsWindow")), to: nil, from: nil)
    }
}
