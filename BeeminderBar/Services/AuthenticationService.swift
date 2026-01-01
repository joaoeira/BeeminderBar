import AppKit
import AuthenticationServices
import Foundation

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var username: String?
    @Published var error: AuthError?

    private let clientId = Secrets.beeminderClientId
    private let redirectUri = Constants.redirectURI
    private let authUrl = Constants.beeminderAuthURL

    var accessToken: String? {
        KeychainService.load(.accessToken)
    }

    init() {
        if KeychainService.load(.accessToken) != nil {
            self.isAuthenticated = true
            self.username = KeychainService.load(.username)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOAuthCallback),
            name: .oauthCallback,
            object: nil
        )
    }

    func startOAuthFlow() {
        isAuthenticating = true
        error = nil

        var components = URLComponents(string: authUrl)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "token")
        ]

        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func handleOAuthCallback(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }

        Task {
            await processCallback(url)
        }
    }

    private func processCallback(_ url: URL) async {
        print("Processing OAuth callback: \(url)")

        // Beeminder returns token in query parameters, not fragment
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("Failed to parse URL components")
            error = .invalidCallback
            isAuthenticating = false
            return
        }

        let queryItems = components.queryItems ?? []
        let token = queryItems.first(where: { $0.name == "access_token" })?.value
        let username = queryItems.first(where: { $0.name == "username" })?.value

        print("Parsed token: \(token != nil ? "present" : "nil")")
        print("Parsed username: \(username ?? "nil")")

        guard let token = token, let username = username else {
            print("Missing token or username in callback")
            error = .missingToken
            isAuthenticating = false
            return
        }

        do {
            try KeychainService.save(token, for: .accessToken)
            try KeychainService.save(username, for: .username)

            self.username = username
            self.isAuthenticated = true
            self.isAuthenticating = false
            print("OAuth successful for user: \(username)")
        } catch {
            print("Keychain error: \(error)")
            self.error = .keychainError
            isAuthenticating = false
        }
    }

    func logout() {
        KeychainService.clear()
        isAuthenticated = false
        username = nil
    }

    enum AuthError: LocalizedError {
        case invalidCallback
        case missingToken
        case keychainError

        var errorDescription: String? {
            switch self {
            case .invalidCallback: return "Invalid OAuth callback"
            case .missingToken: return "No access token received"
            case .keychainError: return "Failed to save credentials"
            }
        }
    }
}
