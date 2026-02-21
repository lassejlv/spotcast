import SwiftUI

@main
struct SpotcastApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(settings: HotKeySettings.shared)
        }
    }
}
