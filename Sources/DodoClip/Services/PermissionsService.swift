import AppKit
@preconcurrency import ApplicationServices

enum PermissionsPromptDecision: Equatable {
    case skip
    case promptAccessibility
}

@MainActor
final class PermissionsService {
    static let shared = PermissionsService()

    private var hasPromptedThisLaunch = false

    private init() {}

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func promptForRequiredPermissionsIfNeeded() {
        guard Self.permissionsPromptDecision(
            hasPromptedThisLaunch: hasPromptedThisLaunch,
            isAccessibilityTrusted: isAccessibilityTrusted
        ) == .promptAccessibility else {
            return
        }

        hasPromptedThisLaunch = true

        let alert = NSAlert()
        alert.messageText = L10n.Permissions.accessibilityTitle
        alert.informativeText = L10n.Permissions.accessibilityMessage
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.Permissions.openSettings)
        alert.addButton(withTitle: L10n.Settings.later)

        if alert.runModal() == .alertFirstButtonReturn {
            requestAccessibilityPermission()
            openAccessibilitySettings()
        }
    }

    static func permissionsPromptDecision(hasPromptedThisLaunch: Bool, isAccessibilityTrusted: Bool) -> PermissionsPromptDecision {
        guard !hasPromptedThisLaunch, !isAccessibilityTrusted else {
            return .skip
        }

        return .promptAccessibility
    }

    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
