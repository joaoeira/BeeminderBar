import Combine
import Foundation

@MainActor
class GoalRefreshService: ObservableObject {
    @Published var lastRefresh: Date?

    private var timer: Timer?
    private let refreshInterval: TimeInterval = 5 * 60  // 5 minutes

    var onRefreshNeeded: (() async -> Void)?

    func startPolling() {
        stopPolling()

        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.onRefreshNeeded?()
                self?.lastRefresh = Date()
            }
        }

        Task {
            await onRefreshNeeded?()
            lastRefresh = Date()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func refreshNow() async {
        await onRefreshNeeded?()
        lastRefresh = Date()
    }

    deinit {
        timer?.invalidate()
    }
}
