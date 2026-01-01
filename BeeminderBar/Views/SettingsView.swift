import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @AppStorage(Constants.refreshIntervalKey) private var refreshInterval = 5
    @State private var launchAtLogin = false
    @State private var launchAtLoginError: String?

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

                if let error = launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
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
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 300)
        .onAppear {
            // Sync toggle with actual system state
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = "Failed: \(error.localizedDescription)"
            // Revert toggle to actual state
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
