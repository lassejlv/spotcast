import Foundation
import SpotcastPluginKit

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published private(set) var currentToast: PluginToast?

    private var dismissTask: Task<Void, Never>?

    private init() {}

    func push(_ toast: PluginToast) {
        dismissTask?.cancel()
        currentToast = toast

        dismissTask = Task { [weak self] in
            guard let self else {
                return
            }

            let delay = UInt64(max(0.5, toast.duration) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            await MainActor.run {
                if self.currentToast?.id == toast.id {
                    self.currentToast = nil
                }
            }
        }
    }
}
