import AppKit
import Carbon
import Combine
import SwiftUI

private final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class LauncherPanelController: NSObject {
    private let panelWidth: CGFloat = 700
    private let expandedHeight: CGFloat = 404
    private let collapsedHeight: CGFloat = 88

    private let panel: NSPanel
    private let viewModel = LauncherViewModel()
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    override init() {
        panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 404),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.contentView = NSHostingView(
            rootView: LauncherView(viewModel: viewModel) { [weak self] in
                self?.hide()
            }
        )
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

        viewModel.$isResultsVisible
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.resizeForCurrentState(animated: false)
            }
            .store(in: &cancellables)

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isVisible else {
                return event
            }

            if self.viewModel.pluginFormSession != nil {
                if event.keyCode == UInt16(kVK_Escape) {
                    _ = self.viewModel.handleEscape()
                    return nil
                }
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
                if self.viewModel.handleEscape() {
                    self.hide()
                }
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
        viewModel.prepareForPresentation()

        let defaults = UserDefaults.standard
        let shouldAnimate = (defaults.object(forKey: "ui.animateLauncher") as? Bool) ?? true

        let finalFrame = targetFrame(for: desiredHeight)
        var startFrame = finalFrame
        startFrame.origin.y -= 18

        if shouldAnimate {
            panel.setFrame(startFrame, display: false)
            panel.alphaValue = 0
        } else {
            panel.setFrame(finalFrame, display: false)
            panel.alphaValue = 1
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(finalFrame, display: true)
                panel.animator().alphaValue = 1
            }
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func resizeForCurrentState(animated: Bool) {
        guard panel.isVisible else {
            return
        }

        let currentFrame = panel.frame
        let newHeight = desiredHeight
        let lockedTopY = currentFrame.maxY
        let newOriginY = lockedTopY - newHeight
        let frame = NSRect(
            x: currentFrame.origin.x,
            y: newOriginY,
            width: panelWidth,
            height: newHeight
        )
        panel.setFrame(frame, display: true, animate: animated)
    }

    private var desiredHeight: CGFloat {
        if viewModel.pluginFormSession != nil {
            return expandedHeight
        }
        return viewModel.isResultsVisible ? expandedHeight : collapsedHeight
    }

    private func targetFrame(for height: CGFloat) -> NSRect {
        let screen = panel.screen ?? NSScreen.main
        let visibleFrame =
            screen?.visibleFrame ?? NSScreen.screens.first?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1280, height: 800)

        let defaults = UserDefaults.standard
        let shouldCenter = (defaults.object(forKey: "ui.centerLauncher") as? Bool) ?? true

        let x = visibleFrame.midX - (panelWidth / 2)
        let y: CGFloat
        if shouldCenter {
            y = visibleFrame.midY - (height / 2) + 150
        } else {
            y = visibleFrame.maxY - height - 44
        }

        return NSRect(x: x, y: y, width: panelWidth, height: height)
    }

    deinit {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
