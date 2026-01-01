import AppKit
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("BeeIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)

            Text("BeeminderBar")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Track your Beeminder goals from the menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                authService.startOAuthFlow()
            } label: {
                if authService.isAuthenticating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Sign in with Beeminder")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authService.isAuthenticating)

            if let error = authService.error {
                VStack(spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)

                    Button("Try Again") {
                        authService.error = nil
                        authService.isAuthenticating = false
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}
