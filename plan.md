# Beeminder Status Bar App - Implementation Plan

A macOS menu bar app for tracking Beeminder goals and adding datapoints.

## Requirements Summary

| Feature | Decision |
|---------|----------|
| Authentication | OAuth 2.0 (support any Beeminder user) |
| UI Style | Popover window with full SwiftUI |
| Goal Display | Urgency dot, deadline, limsum, disclosable graphs, subtle pledge |
| Data Entry | Inline input field when goal is expanded |
| Refresh Strategy | Background polling + refresh on popover open |
| Menu Bar Icon | Static icon |
| Launch at Login | Yes, with toggle in settings |
| Distribution | App Store quality code, likely open source |

---

## Setup Progress

- [x] Install Xcode 26.2
- [x] Configure Xcode command line tools
- [x] Register OAuth app with Beeminder
  - Client ID: `1hsqczy1mop46un09x0hcdxc8`
  - Redirect URI: `beeminderbar://oauth/callback`
- [x] Create project structure
- [x] Add `.gitignore` for secrets
- [x] Create `Secrets.swift` with credentials (not tracked)
- [x] Initialize git repository
- [x] Create Xcode project (`BeeminderBar.xcodeproj`)
- [x] Implement all source files (Models, Services, Views, ViewModels)
- [x] Build and run menu bar app shell
- [x] OAuth authentication working
- [x] Goals fetching and displaying
- [x] Dark mode compatibility (fixed title color with `NSColor.labelColor`)
- [x] High-resolution graphs (switched from `thumbUrl` to `graphUrl`)
- [x] Settings window accessible via gear icon
- [x] Custom bee icons (tinted for menu bar, colorful for login)
- [x] Install script (`scripts/install.sh`)
- [x] README.md with development instructions

**Current Status**: Core app functional (Milestones 1-4 complete)

### Completed Features
- Menu bar app with popover UI
- OAuth login with Beeminder
- Goal list sorted by urgency with color-coded indicators
- Disclosable high-res graphs
- Inline datapoint input
- Settings with logout option
- Dark mode support
- Background polling (configurable interval: 1, 5, 10, or 15 minutes)
- Launch at login toggle (syncs with actual system state)

### Remaining Work
- [ ] Test datapoint submission
- [ ] Keyboard navigation refinement
- [ ] Error handling improvements

### Known Issues
- Keychain prompts for password (click "Always Allow" to fix, or sign app with developer certificate)

---

## Prerequisites

### 1. Install Xcode

```bash
# Open Mac App Store to Xcode page
open "macappstores://apps.apple.com/app/xcode/id497799835"
```

After installation (~3GB download), run once to complete setup:
```bash
sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### 2. Register OAuth Application with Beeminder

1. Go to https://www.beeminder.com/apps/new
2. Fill in:
   - **Name**: `BeeminderBar` (or your preferred name)
   - **Redirect URI**: `beeminderbar://oauth/callback`
   - **Description**: Menu bar app for tracking goals
3. Save and note down:
   - **Client ID**: (you'll get this after registration)
   - **Client Secret**: (keep this secure, stored in Keychain)

---

## Project Structure

```
BeeminderBar/
├── BeeminderBar.xcodeproj
├── BeeminderBar/
│   ├── App/
│   │   ├── BeeminderBarApp.swift          # Main app entry point
│   │   └── AppDelegate.swift              # Handle URL schemes, app lifecycle
│   │
│   ├── Models/
│   │   ├── Goal.swift                     # Goal data model
│   │   ├── Datapoint.swift                # Datapoint data model
│   │   └── User.swift                     # User data model
│   │
│   ├── Services/
│   │   ├── BeeminderAPI.swift             # API client
│   │   ├── AuthenticationService.swift   # OAuth flow management
│   │   ├── KeychainService.swift          # Secure token storage
│   │   └── GoalRefreshService.swift       # Background polling
│   │
│   ├── ViewModels/
│   │   ├── GoalsViewModel.swift           # Main state management
│   │   └── SettingsViewModel.swift        # Settings state
│   │
│   ├── Views/
│   │   ├── ContentView.swift              # Main popover content
│   │   ├── GoalListView.swift             # Scrollable goal list
│   │   ├── GoalRowView.swift              # Individual goal row
│   │   ├── GoalDetailView.swift           # Expanded goal with graph
│   │   ├── DatapointInputView.swift       # Inline value input
│   │   ├── SettingsView.swift             # Settings panel
│   │   └── LoginView.swift                # OAuth login prompt
│   │
│   ├── Utilities/
│   │   ├── Constants.swift                # API URLs, keys
│   │   └── Extensions.swift               # Helpful extensions
│   │
│   └── Resources/
│       ├── Assets.xcassets                # App icon, menu bar icon
│       └── Info.plist                     # URL scheme, permissions
│
└── BeeminderBarTests/
    └── ...
```

---

## Phase 1: Project Setup & Basic Shell

### 1.1 Create Xcode Project

1. Open Xcode → File → New → Project
2. Select **macOS** → **App**
3. Configure:
   - Product Name: `BeeminderBar`
   - Organization Identifier: `com.yourname` (or your domain)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we'll use UserDefaults/Keychain)
   - Uncheck "Include Tests" for now (add later)

### 1.2 Configure as Menu Bar App

**Info.plist additions:**
```xml
<!-- Make it a menu-bar-only app (no dock icon) -->
<key>LSUIElement</key>
<true/>

<!-- Register URL scheme for OAuth callback -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourname.beeminderbar</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>beeminderbar</string>
        </array>
    </dict>
</array>
```

### 1.3 Basic App Entry Point

```swift
// BeeminderBarApp.swift
import SwiftUI

@main
struct BeeminderBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthenticationService()
    @StateObject private var goalsViewModel = GoalsViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(authService)
                .environmentObject(goalsViewModel)
        } label: {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        // Settings window (optional, can be inline in popover)
        Settings {
            SettingsView()
                .environmentObject(authService)
        }
    }
}
```

```swift
// AppDelegate.swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle OAuth callback
        guard let url = urls.first,
              url.scheme == "beeminderbar",
              url.host == "oauth" else { return }

        NotificationCenter.default.post(
            name: .oauthCallback,
            object: nil,
            userInfo: ["url": url]
        )
    }
}

extension Notification.Name {
    static let oauthCallback = Notification.Name("oauthCallback")
}
```

---

## Phase 2: Data Models

### 2.1 Goal Model

```swift
// Models/Goal.swift
import SwiftUI

struct Goal: Codable, Identifiable {
    let id: String
    let slug: String
    let title: String
    let goalType: String

    // Urgency/timing
    let losedate: Int           // Unix timestamp of derailment
    let safebuf: Int            // Days of safety buffer
    let limsum: String          // Human-readable: "+2 due in 1 day"

    // Progress
    let delta: Double           // Distance from centerline
    let todayta: Bool           // Has data today?
    let curval: Double?         // Current value
    let curday: Int?            // Current day

    // Visual
    let graphUrl: String
    let thumbUrl: String
    let svgUrl: String?

    // Stakes
    let pledge: Double          // Current pledge amount

    // Units
    let gunits: String          // Goal units (e.g., "hours", "pages")
    let rate: Double?           // Rate (e.g., 1.5 per day)
    let runits: String          // Rate units (d, w, m, y)

    // Metadata
    let updatedAt: Int?

    enum CodingKeys: String, CodingKey {
        case id, slug, title, losedate, safebuf, limsum
        case delta, todayta, curval, curday
        case pledge, gunits, rate, runits
        case goalType = "goal_type"
        case graphUrl = "graph_url"
        case thumbUrl = "thumb_url"
        case svgUrl = "svg_url"
        case updatedAt = "updated_at"
    }
}

// MARK: - Computed Properties
extension Goal {
    /// Color based on urgency
    var urgencyColor: Color {
        switch safebuf {
        case ..<1:  return .red      // Beemergency!
        case 1:     return .orange   // Due tomorrow
        case 2:     return .blue     // Due in 2 days
        case 3..<7: return .green    // Safe for now
        default:    return .gray     // Very safe
        }
    }

    /// Human-readable time until derailment
    var deadlineText: String {
        let date = Date(timeIntervalSince1970: TimeInterval(losedate))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Is this an emergency?
    var isEmergency: Bool {
        safebuf < 1
    }

    /// Formatted pledge amount
    var pledgeText: String? {
        guard pledge > 0 else { return nil }
        return "$\(Int(pledge))"
    }

    /// Rate description (e.g., "1.5/day")
    var rateText: String? {
        guard let rate = rate else { return nil }
        let unitMap = ["d": "day", "w": "week", "m": "month", "y": "year"]
        let unit = unitMap[runits] ?? runits
        return "\(rate.formatted())/\(unit)"
    }
}
```

### 2.2 Datapoint Model

```swift
// Models/Datapoint.swift
import Foundation

struct Datapoint: Codable, Identifiable {
    let id: String
    let timestamp: Int
    let daystamp: String    // "20240115" format
    let value: Double
    let comment: String
    let requestid: String?

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}

struct CreateDatapointRequest: Encodable {
    let value: Double
    let comment: String?
    let requestid: String      // UUID for idempotency
    let authToken: String

    enum CodingKeys: String, CodingKey {
        case value, comment, requestid
        case authToken = "access_token"
    }
}
```

### 2.3 User Model

```swift
// Models/User.swift
import Foundation

struct User: Codable {
    let username: String
    let timezone: String
    let updatedAt: Int
    let goals: [String]?       // Goal slugs (if requested)

    enum CodingKeys: String, CodingKey {
        case username, timezone, goals
        case updatedAt = "updated_at"
    }
}
```

---

## Phase 3: Services Layer

### 3.1 Keychain Service

```swift
// Services/KeychainService.swift
import Security
import Foundation

enum KeychainService {
    private static let service = "com.yourname.beeminderbar"

    enum Key: String {
        case accessToken = "beeminder_access_token"
        case username = "beeminder_username"
    }

    static func save(_ value: String, for key: Key) throws {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func load(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    static func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func clear() {
        delete(.accessToken)
        delete(.username)
    }

    enum KeychainError: Error {
        case saveFailed(OSStatus)
    }
}
```

### 3.2 Authentication Service

```swift
// Services/AuthenticationService.swift
import Foundation
import AuthenticationServices

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var username: String?
    @Published var error: AuthError?

    private let clientId = "YOUR_CLIENT_ID"        // From Beeminder app registration
    private let redirectUri = "beeminderbar://oauth/callback"
    private let authUrl = "https://www.beeminder.com/apps/authorize"
    private let tokenUrl = "https://www.beeminder.com/api/v1/me.json"

    var accessToken: String? {
        KeychainService.load(.accessToken)
    }

    init() {
        // Check for existing token
        if let token = KeychainService.load(.accessToken) {
            self.isAuthenticated = true
            self.username = KeychainService.load(.username)
        }

        // Listen for OAuth callbacks
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

        var components = URLComponents(string: authUrl)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "token")
        ]

        if let url = components.url {
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
        // OAuth token is in the fragment: beeminderbar://oauth/callback#access_token=xxx&username=yyy
        guard let fragment = url.fragment else {
            error = .invalidCallback
            isAuthenticating = false
            return
        }

        let params = parseFragment(fragment)

        guard let token = params["access_token"],
              let username = params["username"] else {
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
        } catch {
            self.error = .keychainError
            isAuthenticating = false
        }
    }

    private func parseFragment(_ fragment: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                result[String(parts[0])] = String(parts[1])
            }
        }
        return result
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
```

### 3.3 Beeminder API Client

```swift
// Services/BeeminderAPI.swift
import Foundation

actor BeeminderAPI {
    private let baseURL = "https://www.beeminder.com/api/v1"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Goals

    func fetchGoals(token: String) async throws -> [Goal] {
        let url = URL(string: "\(baseURL)/users/me/goals.json?access_token=\(token)")!
        let (data, response) = try await session.data(from: url)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([Goal].self, from: data)
    }

    func fetchGoal(slug: String, token: String) async throws -> Goal {
        let url = URL(string: "\(baseURL)/users/me/goals/\(slug).json?access_token=\(token)")!
        let (data, response) = try await session.data(from: url)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(Goal.self, from: data)
    }

    // MARK: - Datapoints

    func createDatapoint(
        goalSlug: String,
        value: Double,
        comment: String? = nil,
        token: String
    ) async throws -> Datapoint {
        let url = URL(string: "\(baseURL)/users/me/goals/\(goalSlug)/datapoints.json")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreateDatapointRequest(
            value: value,
            comment: comment,
            requestid: UUID().uuidString,
            authToken: token
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(Datapoint.self, from: data)
    }

    func fetchDatapoints(
        goalSlug: String,
        count: Int = 10,
        token: String
    ) async throws -> [Datapoint] {
        var components = URLComponents(string: "\(baseURL)/users/me/goals/\(goalSlug)/datapoints.json")!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "sort", value: "timestamp")
        ]

        let (data, response) = try await session.data(from: components.url!)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([Datapoint].self, from: data)
    }

    // MARK: - User

    func fetchUser(token: String) async throws -> User {
        let url = URL(string: "\(baseURL)/users/me.json?access_token=\(token)")!
        let (data, response) = try await session.data(from: url)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(User.self, from: data)
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    enum APIError: LocalizedError {
        case invalidResponse
        case unauthorized
        case notFound
        case rateLimited
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Invalid response from server"
            case .unauthorized: return "Please log in again"
            case .notFound: return "Goal not found"
            case .rateLimited: return "Too many requests, please wait"
            case .serverError(let code): return "Server error (\(code))"
            }
        }
    }
}
```

### 3.4 Goal Refresh Service

```swift
// Services/GoalRefreshService.swift
import Foundation
import Combine

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

    func refreshNow() async {
        await onRefreshNeeded?()
        lastRefresh = Date()
    }

    deinit {
        timer?.invalidate()
    }
}
```

---

## Phase 4: View Models

### 4.1 Goals View Model

```swift
// ViewModels/GoalsViewModel.swift
import SwiftUI
import Combine

@MainActor
class GoalsViewModel: ObservableObject {
    // MARK: - Published State
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedGoalId: String?
    @Published var datapointInputValues: [String: String] = [:]  // goalId -> input text
    @Published var submittingGoalIds: Set<String> = []

    // MARK: - Services
    private let api = BeeminderAPI()
    let refreshService = GoalRefreshService()

    // MARK: - Computed Properties

    var emergencyCount: Int {
        goals.filter { $0.isEmergency }.count
    }

    var sortedGoals: [Goal] {
        // API returns sorted by urgency, but we can re-sort if needed
        goals.sorted { $0.safebuf < $1.safebuf }
    }

    // MARK: - Initialization

    init() {
        refreshService.onRefreshNeeded = { [weak self] in
            await self?.fetchGoals()
        }
    }

    // MARK: - Actions

    func fetchGoals() async {
        guard let token = KeychainService.load(.accessToken) else { return }

        isLoading = goals.isEmpty  // Only show loading on first fetch
        error = nil

        do {
            goals = try await api.fetchGoals(token: token)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func addDatapoint(to goal: Goal) async {
        guard let token = KeychainService.load(.accessToken),
              let inputText = datapointInputValues[goal.id],
              let value = Double(inputText) else { return }

        submittingGoalIds.insert(goal.id)

        do {
            _ = try await api.createDatapoint(
                goalSlug: goal.slug,
                value: value,
                token: token
            )

            // Clear input and refresh
            datapointInputValues[goal.id] = nil
            await fetchGoals()
        } catch {
            self.error = error
        }

        submittingGoalIds.remove(goal.id)
    }

    func toggleGoalExpanded(_ goal: Goal) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedGoalId == goal.id {
                selectedGoalId = nil
            } else {
                selectedGoalId = goal.id
            }
        }
    }

    func startPolling() {
        refreshService.startPolling()
    }

    func stopPolling() {
        refreshService.stopPolling()
    }
}
```

---

## Phase 5: Views

### 5.1 Content View (Main Popover)

```swift
// Views/ContentView.swift
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
            await goalsViewModel.fetchGoals()
            goalsViewModel.startPolling()
        }
        .onDisappear {
            goalsViewModel.stopPolling()
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

            Button {
                // Open settings or show menu
            } label: {
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
```

### 5.2 Goal List View

```swift
// Views/GoalListView.swift
import SwiftUI

struct GoalListView: View {
    @EnvironmentObject var goalsViewModel: GoalsViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(goalsViewModel.sortedGoals) { goal in
                    GoalRowView(
                        goal: goal,
                        isExpanded: goalsViewModel.selectedGoalId == goal.id
                    )
                    .onTapGesture {
                        goalsViewModel.toggleGoalExpanded(goal)
                    }
                }
            }
            .padding()
        }
    }
}
```

### 5.3 Goal Row View

```swift
// Views/GoalRowView.swift
import SwiftUI

struct GoalRowView: View {
    let goal: Goal
    let isExpanded: Bool

    @EnvironmentObject var goalsViewModel: GoalsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row - always visible
            mainRow

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(goal.isEmergency ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }

    private var mainRow: some View {
        HStack(spacing: 10) {
            // Urgency indicator
            Circle()
                .fill(goal.urgencyColor)
                .frame(width: 10, height: 10)

            // Goal info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(goal.title)
                        .font(.system(.body, weight: .medium))
                        .lineLimit(1)

                    if goal.todayta {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Text(goal.limsum)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Right side info
            VStack(alignment: .trailing, spacing: 2) {
                Text(goal.deadlineText)
                    .font(.caption)
                    .foregroundColor(goal.isEmergency ? .red : .secondary)

                // Subtle pledge display
                if let pledgeText = goal.pledgeText {
                    Text(pledgeText)
                        .font(.caption2)
                        .foregroundColor(.orange.opacity(0.8))
                }
            }

            // Expand indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.top, 8)

            // Disclosable graph
            graphSection

            // Data input
            inputSection

            // Actions
            actionButtons
        }
    }

    @State private var showGraph = false

    private var graphSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { showGraph.toggle() }
            } label: {
                HStack {
                    Image(systemName: showGraph ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    Text("Graph")
                        .font(.caption)
                    Spacer()
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            if showGraph {
                AsyncImage(url: URL(string: goal.thumbUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(4)
                    case .failure:
                        Text("Failed to load graph")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }

    private var inputSection: some View {
        HStack {
            TextField(
                "Value (\(goal.gunits))",
                text: Binding(
                    get: { goalsViewModel.datapointInputValues[goal.id] ?? "" },
                    set: { goalsViewModel.datapointInputValues[goal.id] = $0 }
                )
            )
            .textFieldStyle(.roundedBorder)
            .onSubmit {
                Task { await goalsViewModel.addDatapoint(to: goal) }
            }

            Button {
                Task { await goalsViewModel.addDatapoint(to: goal) }
            } label: {
                if goalsViewModel.submittingGoalIds.contains(goal.id) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .buttonStyle(.borderless)
            .disabled(
                goalsViewModel.datapointInputValues[goal.id]?.isEmpty ?? true ||
                goalsViewModel.submittingGoalIds.contains(goal.id)
            )
        }
    }

    private var actionButtons: some View {
        HStack {
            Button {
                if let url = URL(string: "https://www.beeminder.com/\(KeychainService.load(.username) ?? "me")/\(goal.slug)") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Open in Browser", systemImage: "arrow.up.right.square")
                    .font(.caption)
            }
            .buttonStyle(.borderless)

            Spacer()

            if let rateText = goal.rateText {
                Text(rateText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### 5.4 Login View

```swift
// Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)

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
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
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
```

### 5.5 Settings View

```swift
// Views/SettingsView.swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("refreshInterval") private var refreshInterval = 5  // minutes

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
```

---

## Phase 6: Polish & Refinements

### 6.1 Menu Bar Icon Assets

Create the following in `Assets.xcassets`:

1. **MenuBarIcon** (Template Image)
   - 18x18 @1x
   - 36x36 @2x
   - Set "Render As" to "Template Image"
   - Use a simple bee or chart outline

### 6.2 Error Handling View

```swift
// Views/ErrorBannerView.swift
import SwiftUI

struct ErrorBannerView: View {
    let error: Error
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(error.localizedDescription)
                .font(.caption)
                .lineLimit(2)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
}
```

### 6.3 Keyboard Navigation

Add to `GoalListView`:

```swift
.onKeyPress(.upArrow) { ... }
.onKeyPress(.downArrow) { ... }
.onKeyPress(.return) { ... }
.focusable()
```

---

## Implementation Order

### Milestone 1: Working Shell
1. Create Xcode project with correct settings
2. Implement `BeeminderBarApp.swift` with MenuBarExtra
3. Create placeholder ContentView
4. Verify app appears in menu bar

### Milestone 2: Authentication
1. Register OAuth app with Beeminder
2. Implement KeychainService
3. Implement AuthenticationService
4. Create LoginView
5. Test OAuth flow end-to-end

### Milestone 3: Display Goals
1. Implement Goal model
2. Implement BeeminderAPI (fetchGoals only)
3. Implement GoalsViewModel
4. Create GoalListView and GoalRowView
5. Wire up to ContentView

### Milestone 4: Add Datapoints
1. Implement Datapoint model
2. Add createDatapoint to API
3. Add DatapointInputView
4. Handle submission and refresh

### Milestone 5: Polish
1. Add disclosable graphs
2. Implement background polling
3. Add settings with launch-at-login
4. Error handling improvements
5. Keyboard navigation
6. Icon assets

---

## Testing Checklist

- [ ] OAuth flow completes successfully
- [ ] Token persists across app restarts
- [ ] Goals load and display correctly
- [ ] Goals sorted by urgency
- [ ] Urgency colors are correct
- [ ] Graph loads when disclosed
- [ ] Datapoint submission works
- [ ] Input field clears after submit
- [ ] Goals refresh after adding datapoint
- [ ] Background polling works
- [ ] Manual refresh button works
- [ ] Launch at login toggle works
- [ ] Logout clears credentials
- [ ] App quits cleanly
- [ ] Works in light and dark mode

---

## Notes & Gotchas

1. **OAuth Fragment Parsing**: Beeminder returns the token in the URL fragment (`#access_token=...`), not query params. Make sure to parse the fragment.

2. **Graph Caching**: `AsyncImage` caches automatically, but you may want to add a cache-busting query param after submitting datapoints to see updated graphs.

3. **Sandboxing**: If distributing via App Store, you'll need proper entitlements for:
   - Keychain access
   - Outgoing network connections
   - SMAppService for launch at login

4. **Rate Limiting**: Beeminder doesn't document rate limits, but be conservative with polling. 5-minute intervals should be fine.

5. **Token in URL**: We're putting the token in query params per the API docs. For extra security in production, consider using the `Authorization: Bearer` header instead.

6. **Idempotency**: Always use `requestid` when creating datapoints to prevent duplicates on retry.
