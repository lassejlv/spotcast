import AppKit
import Carbon
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: LauncherPanelController?
    private var toastWindowController: ToastWindowController?
    private var primaryHotKey: GlobalHotKey?
    private var fallbackHotKey: GlobalHotKey?
    private var cancellables = Set<AnyCancellable>()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let panelController = LauncherPanelController()
        self.panelController = panelController
        self.toastWindowController = ToastWindowController(toastCenter: .shared)
        setupStatusItem()

        HotKeySettings.shared.$shortcut
            .receive(on: RunLoop.main)
            .sink { [weak self] shortcut in
                self?.registerHotKeys(shortcut)
            }
            .store(in: &cancellables)

        registerHotKeys(HotKeySettings.shared.shortcut)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppResignedActive),
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )
    }

    private func registerHotKeys(_ shortcut: HotKeyShortcut) {
        primaryHotKey = GlobalHotKey(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers) {
            [weak panelController] in
            panelController?.toggle()
        }

        fallbackHotKey = nil
        if primaryHotKey == nil {
            fallbackHotKey = GlobalHotKey(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(optionKey))
            { [weak panelController] in
                panelController?.toggle()
            }
        }
    }

    @objc private func handleAppResignedActive() {
        panelController?.hide()
    }

    private func setupStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Spotcast"

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Open Launcher", action: #selector(openLauncher), keyEquivalent: ""))
        menu.addItem(
            NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: "Quit Spotcast", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu

        self.statusItem = statusItem
    }

    @objc private func openLauncher() {
        panelController?.show()
    }

    @objc private func openSettings() {
        openSettingsWindow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
