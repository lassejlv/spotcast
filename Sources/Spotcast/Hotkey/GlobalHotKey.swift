import Carbon
import Foundation

final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let action: () -> Void
    private let hotKeyID: EventHotKeyID

    init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.action = action
        self.hotKeyID = EventHotKeyID(signature: OSType(0x53504354), id: UInt32.random(in: 1...UInt32.max))

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, userData in
            guard
                let userData,
                let event,
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue() as GlobalHotKey?
            else {
                return noErr
            }

            var incomingID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &incomingID
            )

            guard status == noErr, incomingID.id == hotKey.hotKeyID.id else {
                return noErr
            }

            hotKey.action()
            return noErr
        }

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType, userData, &eventHandler)
        guard installStatus == noErr else {
            return nil
        }

        let registerStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        guard registerStatus == noErr else {
            if let eventHandler {
                RemoveEventHandler(eventHandler)
                self.eventHandler = nil
            }
            return nil
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
