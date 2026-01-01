# BeeminderBar

A macOS menu bar app for tracking your Beeminder goals and adding datapoints.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu bar integration** — Quick access to all your goals from the menu bar
- **Goal overview** — Goals sorted by urgency with color-coded indicators
- **Inline datapoint entry** — Add data without leaving the app
- **Graph preview** — Expandable high-resolution graphs for each goal
- **Background polling** — Automatic refresh (configurable: 1, 5, 10, or 15 minutes)
- **Launch at login** — Start automatically when you log in
- **Dark mode support** — Native macOS appearance

## Screenshots

_Coming soon_

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for development)
- A [Beeminder](https://www.beeminder.com) account

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/beeminder-status-bar.git
   cd beeminder-status-bar
   ```

2. Set up your OAuth credentials (see [Development Setup](#development-setup))

3. Build and install:
   ```bash
   ./scripts/install.sh
   ```

The app will be installed to `/Applications` and launched automatically.

## Development Setup

### Prerequisites

1. **Install Xcode** from the Mac App Store

2. **Accept Xcode license** (if not already done):
   ```bash
   sudo xcodebuild -license accept
   ```

3. **Register a Beeminder OAuth app**:
   - Go to https://www.beeminder.com/apps/new
   - Name: `BeeminderBar` (or your preference)
   - Redirect URI: `beeminderbar://oauth/callback`
   - Save and note your **Client ID** and **Client Secret**

### Project Setup

1. **Create your secrets file**:
   ```bash
   cp BeeminderBar/Secrets.example.swift BeeminderBar/Secrets.swift
   ```

2. **Edit `BeeminderBar/Secrets.swift`** with your OAuth credentials:
   ```swift
   enum Secrets {
       static let beeminderClientId = "YOUR_CLIENT_ID"
       static let beeminderClientSecret = "YOUR_CLIENT_SECRET"
   }
   ```

   > ⚠️ `Secrets.swift` is git-ignored to protect your credentials

### Building

#### Using the install script (recommended)

```bash
./scripts/install.sh
```

This builds the app, copies it to `/Applications`, and launches it. Use this when you want to test "Launch at Login" functionality.

#### Using Xcode

1. Open `BeeminderBar.xcodeproj` in Xcode
2. Select the `BeeminderBar` scheme
3. Press `Cmd+R` to build and run

#### Using command line

```bash
# Build only
xcodebuild -project BeeminderBar.xcodeproj -scheme BeeminderBar -configuration Debug build

# Build and run from DerivedData (for quick testing)
xcodebuild -project BeeminderBar.xcodeproj -scheme BeeminderBar build && \
  open ~/Library/Developer/Xcode/DerivedData/BeeminderBar-*/Build/Products/Debug/BeeminderBar.app
```

### Project Structure

```
BeeminderBar/
├── App/                    # App entry point & delegates
│   ├── BeeminderBarApp.swift
│   └── AppDelegate.swift
├── Models/                 # Data models
│   ├── Goal.swift
│   ├── Datapoint.swift
│   └── User.swift
├── Services/               # Business logic & networking
│   ├── AuthenticationService.swift
│   ├── BeeminderAPI.swift
│   ├── KeychainService.swift
│   └── GoalRefreshService.swift
├── ViewModels/             # State management
│   ├── GoalsViewModel.swift
│   └── SettingsViewModel.swift
├── Views/                  # SwiftUI views
│   ├── ContentView.swift
│   ├── GoalListView.swift
│   ├── GoalRowView.swift
│   ├── GoalDetailView.swift
│   ├── DatapointInputView.swift
│   ├── LoginView.swift
│   ├── SettingsView.swift
│   └── ErrorBannerView.swift
├── Utilities/              # Helpers & constants
│   ├── Constants.swift
│   └── Extensions.swift
├── Resources/              # Assets & configuration
│   ├── Assets.xcassets/
│   └── Info.plist
├── Secrets.swift           # OAuth credentials (git-ignored)
└── Secrets.example.swift   # Template for credentials
```

### Key Files

| File | Purpose |
|------|---------|
| `BeeminderBarApp.swift` | App entry point, MenuBarExtra setup |
| `AuthenticationService.swift` | OAuth flow, token management |
| `BeeminderAPI.swift` | API client for Beeminder endpoints |
| `GoalsViewModel.swift` | Main state management for goals |
| `GoalRefreshService.swift` | Background polling logic |
| `Info.plist` | URL scheme registration, LSUIElement |

### Debugging

**View logs:**
```bash
log show --predicate 'process == "BeeminderBar"' --last 5m
```

**Common issues:**

- **"Invalid OAuth callback"** — Check that the redirect URI in your Beeminder app settings matches `beeminderbar://oauth/callback`
- **Keychain prompts** — Click "Always Allow" to grant permanent access, or sign the app with a developer certificate
- **Launch at Login not working** — Make sure the app is in `/Applications` (use `./scripts/install.sh`)

## Configuration

Settings are available via the gear icon in the popover:

| Setting | Description |
|---------|-------------|
| Launch at Login | Start BeeminderBar when you log in |
| Refresh Interval | How often to poll for goal updates (1, 5, 10, or 15 min) |

## API Reference

BeeminderBar uses the [Beeminder API](https://api.beeminder.com/). Key endpoints:

- `GET /users/me/goals.json` — Fetch all goals (sorted by urgency)
- `POST /users/me/goals/{slug}/datapoints.json` — Add a datapoint

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Beeminder](https://www.beeminder.com) for the API and goal-tracking service
- Bee icons from Beeminder's asset library
