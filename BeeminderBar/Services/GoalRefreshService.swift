import Combine
import Foundation

@MainActor
class GoalRefreshService: ObservableObject {
    @Published var lastRefresh: Date?

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var onRefreshNeeded: (() async -> Void)?

    /// Refresh interval in minutes, read from UserDefaults
    private var refreshIntervalMinutes: Int {
        let interval = UserDefaults.standard.integer(forKey: Constants.refreshIntervalKey)
        return interval > 0 ? interval : 5  // Default 5 minutes
    }

    private var refreshInterval: TimeInterval {
        TimeInterval(refreshIntervalMinutes * 60)
    }

    init() {
        // Watch for settings changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.restartPollingIfNeeded()
                }
            }
            .store(in: &cancellables)
    }

    func startPolling() {
        stopPolling()

        print("Starting background polling every \(refreshIntervalMinutes) minutes")

        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.onRefreshNeeded?()
                self?.lastRefresh = Date()
            }
        }

        // Also run immediately
        Task {
            await onRefreshNeeded?()
            lastRefresh = Date()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func restartPollingIfNeeded() {
        guard timer != nil else { return }
        print("Refresh interval changed, restarting polling")
        startPolling()
    }

    func refreshNow() async {
        await onRefreshNeeded?()
        lastRefresh = Date()
    }

    deinit {
        timer?.invalidate()
    }
}
