import AppKit
import SwiftUI

/// Controller for the settings window
/// Needed because agent apps (no dock icon) don't work well with SwiftUI Settings scene
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func showSettings() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "DodoClip Settings"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false

        // Handle window close
        window.delegate = WindowDelegate.shared

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeSettings() {
        window?.close()
    }
}

// Window delegate to handle close
private class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()

    func windowWillClose(_ notification: Notification) {
        // Window is closing, nothing special to do
    }
}
