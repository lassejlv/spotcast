import AppKit
import Carbon
import SwiftUI

private final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class LauncherPanelController: NSObject {
    private let panel: NSPanel
    private let viewModel = LauncherViewModel()
    private var eventMonitor: Any?

    override init() {
        panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 430),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.contentView = NSHostingView(
            rootView: LauncherView(viewModel: viewModel) { [weak self] in
                self?.hide()
            })
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isOpaque = false
        panel.hidesOnDeactivate = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.collectionBehavior = [
            .canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle,
        ]

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isVisible else {
                return event
            }

            switch event.keyCode {
            case UInt16(kVK_UpArrow):
                self.viewModel.moveSelection(up: true)
                return nil
            case UInt16(kVK_DownArrow):
                self.viewModel.moveSelection(up: false)
                return nil
            case UInt16(kVK_Return):
                let shouldClose = self.viewModel.executeSelected()
                if shouldClose {
                    self.hide()
                }
                return nil
            case UInt16(kVK_Escape):
                self.hide()
                return nil
            default:
                return event
            }
        }
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        guard let screen = NSScreen.main else {
            return
        }

        viewModel.prepareForPresentation()

        let defaults = UserDefaults.standard
        let shouldAnimate = (defaults.object(forKey: "ui.animateLauncher") as? Bool) ?? true
        let shouldCenter = (defaults.object(forKey: "ui.centerLauncher") as? Bool) ?? true

        let visibleFrame = screen.visibleFrame
        let size = panel.frame.size
        let x = visibleFrame.midX - (size.width / 2)
        let y: CGFloat
        if shouldCenter {
            y = visibleFrame.midY - (size.height / 2) + 40
        } else {
            y = visibleFrame.maxY - size.height - 44
        }
        let finalOrigin = NSPoint(x: x, y: y)
        let startOrigin = NSPoint(x: x, y: y - 18)

        if shouldAnimate {
            panel.setFrameOrigin(startOrigin)
            panel.alphaValue = 0
        } else {
            panel.setFrameOrigin(finalOrigin)
            panel.alphaValue = 1
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrameOrigin(finalOrigin)
                panel.animator().alphaValue = 1
            }
        } else {
            panel.alphaValue = 1
            panel.setFrameOrigin(finalOrigin)
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    deinit {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
