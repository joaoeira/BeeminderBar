import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        print("AppDelegate received URLs: \(urls)")

        guard let url = urls.first else {
            print("No URL received")
            return
        }

        print("Processing URL: \(url)")
        print("  Scheme: \(url.scheme ?? "nil")")
        print("  Host: \(url.host ?? "nil")")
        print("  Path: \(url.path)")
        print("  Fragment: \(url.fragment ?? "nil")")

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
