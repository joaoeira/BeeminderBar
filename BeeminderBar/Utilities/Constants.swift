import Foundation

enum Constants {
    static let beeminderBaseURL = "https://www.beeminder.com/api/v1"
    static let beeminderAuthURL = "https://www.beeminder.com/apps/authorize"
    static let redirectURI = "beeminderbar://oauth/callback"
    static let keychainService = Bundle.main.bundleIdentifier ?? "com.yourname.beeminderbar"
    static let launchAtLoginKey = "launchAtLogin"
    static let refreshIntervalKey = "refreshInterval"
}
