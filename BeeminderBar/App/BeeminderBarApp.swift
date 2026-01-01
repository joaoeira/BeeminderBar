import SwiftUI

@main
struct BeeminderBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService = AuthenticationService()
    @StateObject private var goalsViewModel = GoalsViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(authService)
                .environmentObject(goalsViewModel)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        } label: {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(authService)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        print("Received URL: \(url)")
        print("Scheme: \(url.scheme ?? "nil")")
        print("Host: \(url.host ?? "nil")")
        print("Path: \(url.path)")
        print("Fragment: \(url.fragment ?? "nil")")

        guard url.scheme == "beeminderbar" else {
            print("Wrong scheme, ignoring")
            return
        }

        NotificationCenter.default.post(
            name: .oauthCallback,
            object: nil,
            userInfo: ["url": url]
        )
    }
}
