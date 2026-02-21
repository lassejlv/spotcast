import Foundation

@MainActor
final class HotKeySettings: ObservableObject {
    static let shared = HotKeySettings()

    @Published private(set) var shortcut: HotKeyShortcut

    private let defaults: UserDefaults
    private let keyCodeKey = "hotkey.keyCode"
    private let modifiersKey = "hotkey.modifiers"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let keyCode = defaults.object(forKey: keyCodeKey) as? UInt32
        let modifiers = defaults.object(forKey: modifiersKey) as? UInt32

        if let keyCode, let modifiers {
            let stored = HotKeyShortcut(keyCode: keyCode, modifiers: modifiers)
            if stored == .legacyDefault {
                shortcut = .default
                defaults.set(shortcut.keyCode, forKey: keyCodeKey)
                defaults.set(shortcut.modifiers, forKey: modifiersKey)
            } else {
                shortcut = stored
            }
        } else {
            shortcut = .default
            defaults.set(shortcut.keyCode, forKey: keyCodeKey)
            defaults.set(shortcut.modifiers, forKey: modifiersKey)
        }
    }

    var selectedModifierPreset: HotKeyModifierPreset {
        HotKeyModifierPreset.from(shortcut.modifiers)
    }

    var selectedKeyPreset: HotKeyKeyPreset {
        HotKeyKeyPreset.from(shortcut.keyCode)
    }

    func update(modifierPreset: HotKeyModifierPreset) {
        apply(HotKeyShortcut(keyCode: shortcut.keyCode, modifiers: modifierPreset.carbonModifiers))
    }

    func update(keyPreset: HotKeyKeyPreset) {
        apply(HotKeyShortcut(keyCode: keyPreset.keyCode, modifiers: shortcut.modifiers))
    }

    private func apply(_ value: HotKeyShortcut) {
        guard shortcut != value else {
            return
        }

        shortcut = value
        defaults.set(value.keyCode, forKey: keyCodeKey)
        defaults.set(value.modifiers, forKey: modifiersKey)
    }
}
