import Carbon
import Foundation

struct HotKeyShortcut: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    static let `default` = HotKeyShortcut(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(optionKey))
    static let legacyDefault = HotKeyShortcut(
        keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey))
}

enum HotKeyModifierPreset: String, CaseIterable, Identifiable {
    case control
    case option
    case command
    case controlOption
    case controlCommand
    case optionCommand

    var id: String { rawValue }

    var title: String {
        switch self {
        case .control: "Control"
        case .option: "Option"
        case .command: "Command"
        case .controlOption: "Control + Option"
        case .controlCommand: "Control + Command"
        case .optionCommand: "Option + Command"
        }
    }

    var carbonModifiers: UInt32 {
        switch self {
        case .control: UInt32(controlKey)
        case .option: UInt32(optionKey)
        case .command: UInt32(cmdKey)
        case .controlOption: UInt32(controlKey | optionKey)
        case .controlCommand: UInt32(controlKey | cmdKey)
        case .optionCommand: UInt32(optionKey | cmdKey)
        }
    }

    static func from(_ modifiers: UInt32) -> HotKeyModifierPreset {
        switch modifiers {
        case UInt32(controlKey): .control
        case UInt32(optionKey): .option
        case UInt32(cmdKey): .command
        case UInt32(controlKey | optionKey): .controlOption
        case UInt32(controlKey | cmdKey): .controlCommand
        case UInt32(optionKey | cmdKey): .optionCommand
        default: .control
        }
    }
}

enum HotKeyKeyPreset: String, CaseIterable, Identifiable {
    case space
    case k
    case p
    case j

    var id: String { rawValue }

    var title: String {
        switch self {
        case .space: "Space"
        case .k: "K"
        case .p: "P"
        case .j: "J"
        }
    }

    var keyCode: UInt32 {
        switch self {
        case .space: UInt32(kVK_Space)
        case .k: UInt32(kVK_ANSI_K)
        case .p: UInt32(kVK_ANSI_P)
        case .j: UInt32(kVK_ANSI_J)
        }
    }

    static func from(_ keyCode: UInt32) -> HotKeyKeyPreset {
        switch keyCode {
        case UInt32(kVK_ANSI_K): .k
        case UInt32(kVK_ANSI_P): .p
        case UInt32(kVK_ANSI_J): .j
        default: .space
        }
    }
}
