import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Constants.launchAtLoginKey)
        }
    }

    @Published var refreshInterval: Int {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: Constants.refreshIntervalKey)
        }
    }

    init() {
        launchAtLogin = UserDefaults.standard.bool(forKey: Constants.launchAtLoginKey)
        let interval = UserDefaults.standard.integer(forKey: Constants.refreshIntervalKey)
        refreshInterval = interval == 0 ? 5 : interval
    }
}
