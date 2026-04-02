import Testing
@testable import DodoClip

@Suite("DodoClip Tests")
struct DodoClipTests {
    @Test("App initializes correctly")
    func appInitializes() async throws {
        // Basic test to verify the app structure
        #expect(true)
    }

    @MainActor
    @Test("Panel hotkey completes onboarding before toggling panel")
    func panelHotkeyPrefersFirstRunHUD() {
        let action = AppDelegate.panelHotkeyAction(
            isFirstRunHUDShowing: true,
            isPanelVisible: true
        )

        #expect(action == .completeFirstRun)
    }

    @MainActor
    @Test("Panel hotkey hides the panel when already visible")
    func panelHotkeyHidesVisiblePanel() {
        let action = AppDelegate.panelHotkeyAction(
            isFirstRunHUDShowing: false,
            isPanelVisible: true
        )

        #expect(action == .hidePanel)
    }

    @MainActor
    @Test("Panel hotkey shows panel through the capture-aware path")
    func panelHotkeyShowsHiddenPanel() {
        let action = AppDelegate.panelHotkeyAction(
            isFirstRunHUDShowing: false,
            isPanelVisible: false
        )

        #expect(action == .showPanel)
    }

    @MainActor
    @Test("Permissions prompt appears when accessibility is missing")
    func permissionsPromptRequiredWhenAccessibilityMissing() {
        let decision = PermissionsService.permissionsPromptDecision(
            hasPromptedThisLaunch: false,
            isAccessibilityTrusted: false
        )

        #expect(decision == .promptAccessibility)
    }

    @MainActor
    @Test("Permissions prompt is skipped after prompting once")
    func permissionsPromptSkippedAfterPrompting() {
        let decision = PermissionsService.permissionsPromptDecision(
            hasPromptedThisLaunch: true,
            isAccessibilityTrusted: false
        )

        #expect(decision == .skip)
    }

    @MainActor
    @Test("Permissions prompt is skipped when accessibility is already trusted")
    func permissionsPromptSkippedWhenTrusted() {
        let decision = PermissionsService.permissionsPromptDecision(
            hasPromptedThisLaunch: false,
            isAccessibilityTrusted: true
        )

        #expect(decision == .skip)
    }
}
