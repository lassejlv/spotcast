import AppKit
import Combine
import SpotcastPluginKit
import SwiftUI

@MainActor
final class ToastWindowController {
    private let panel: NSPanel
    private let hostingView: NSHostingView<ToastHUDView>
    private var cancellable: AnyCancellable?

    init(toastCenter: ToastCenter) {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 72),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        hostingView = NSHostingView(rootView: ToastHUDView(toast: nil))
        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.alphaValue = 0

        cancellable = toastCenter.$currentToast
            .receive(on: RunLoop.main)
            .sink { [weak self] toast in
                self?.update(toast)
            }
    }

    private func update(_ toast: PluginToast?) {
        hostingView.rootView = ToastHUDView(toast: toast)

        guard let toast else {
            hideToast()
            return
        }

        showToast(toast)
    }

    private func showToast(_ toast: PluginToast) {
        guard let screen = NSScreen.main else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let width: CGFloat = min(520, max(320, CGFloat(toast.message.count) * 5.6 + 140))
        let height: CGFloat = 76
        panel.setContentSize(NSSize(width: width, height: height))

        let x = visibleFrame.midX - (width / 2)
        let y = visibleFrame.minY + 36
        panel.setFrameOrigin(NSPoint(x: x, y: y))

        if !panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
    }

    private func hideToast() {
        guard panel.isVisible else {
            return
        }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.16
                panel.animator().alphaValue = 0
            },
            completionHandler: {
                self.panel.orderOut(nil)
            })
    }
}

private struct ToastHUDView: View {
    let toast: PluginToast?

    var body: some View {
        if let toast {
            HStack(spacing: 10) {
                Circle()
                    .fill(color(for: toast.style))
                    .frame(width: 9, height: 9)

                VStack(alignment: .leading, spacing: 2) {
                    Text(toast.title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(toast.message)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func color(for style: PluginToastStyle) -> Color {
        switch style {
        case .info: .blue
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }
}
