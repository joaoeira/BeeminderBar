import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var goalsViewModel: GoalsViewModel

    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedView
            } else {
                LoginView()
            }
        }
        .frame(width: 340, height: 480)
    }

    private var authenticatedView: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            if let error = goalsViewModel.error {
                ErrorBannerView(error: error) {
                    goalsViewModel.error = nil
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            if goalsViewModel.isLoading && goalsViewModel.goals.isEmpty {
                loadingView
            } else if goalsViewModel.goals.isEmpty {
                emptyView
            } else {
                GoalListView()
            }

            Divider()
            footerView
        }
        .task {
            // Polling is started at app launch, just fetch on first view
            if goalsViewModel.goals.isEmpty {
                await goalsViewModel.fetchGoals()
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Beeminder")
                    .font(.headline)
                if let username = authService.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                Task { await goalsViewModel.refreshService.refreshNow() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(goalsViewModel.isLoading)
            .help("Refresh goals")

            SettingsLink {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Text("Loading goals...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.green)
            Text("No goals found")
                .font(.headline)
            Text("Create goals at beeminder.com")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var footerView: some View {
        HStack {
            if goalsViewModel.emergencyCount > 0 {
                Label("\(goalsViewModel.emergencyCount)", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if let lastRefresh = goalsViewModel.refreshService.lastRefresh {
                Text("Updated \(lastRefresh, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
