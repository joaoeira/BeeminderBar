import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @AppStorage(Constants.launchAtLoginKey) private var launchAtLogin = false
    @AppStorage(Constants.refreshIntervalKey) private var refreshInterval = 5

    var body: some View {
        Form {
            Section("Account") {
                if let username = authService.username {
                    LabeledContent("Logged in as") {
                        Text("@\(username)")
                    }

                    Button("Log Out", role: .destructive) {
                        authService.logout()
                    }
                }
            }

            Section("Behavior") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Picker("Refresh Interval", selection: $refreshInterval) {
                    Text("1 minute").tag(1)
                    Text("5 minutes").tag(5)
                    Text("10 minutes").tag(10)
                    Text("15 minutes").tag(15)
                }
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }

                Link("Beeminder Website", destination: URL(string: "https://www.beeminder.com")!)
                Link("Report an Issue", destination: URL(string: "https://github.com/yourname/beeminderbar/issues")!)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 300)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}
