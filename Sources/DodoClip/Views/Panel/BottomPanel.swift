import AppKit
import SwiftUI

/// Custom NSPanel for the bottom clipboard panel
/// Floats above all windows, no title bar, dark appearance
final class BottomPanel: NSPanel {

    private var hostingController: NSHostingController<AnyView>?
    private var isCompactMode: Bool = false

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configurePanel()
    }

    private func configurePanel() {
        // Window level and behavior
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        // Appearance
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        // Make it not activate the app
        styleMask.insert(.nonactivatingPanel)

        // Accept key events
        isMovableByWindowBackground = false
        acceptsMouseMovedEvents = true

        // Visual effect for the background
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = Theme.Dimensions.panelCornerRadius
        visualEffect.layer?.masksToBounds = true

        contentView = visualEffect
    }

    /// Set the SwiftUI content for the panel
    func setContent<Content: View>(_ content: Content) {
        if let existingController = hostingController {
            // Update the existing controller's root view to preserve SwiftUI state
            existingController.rootView = AnyView(content)
        } else {
            // Create new hosting controller
            let controller = NSHostingController(rootView: AnyView(content))
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            if let visualEffect = contentView as? NSVisualEffectView {
                visualEffect.addSubview(controller.view)
                NSLayoutConstraint.activate([
                    controller.view.topAnchor.constraint(equalTo: visualEffect.topAnchor),
                    controller.view.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
                    controller.view.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
                    controller.view.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor)
                ])

                self.hostingController = controller
            }
        }
    }

    /// Show the panel with animation on the specified screen
    func show(on screen: NSScreen, compact: Bool = false) {
        isCompactMode = compact
        let panelHeight = compact ? Theme.Dimensions.panelHeightCompact : Theme.Dimensions.panelHeight

        // Calculate dock position and gaps
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame

        let leftDockGap = visibleFrame.minX - screenFrame.minX
        let rightDockGap = screenFrame.maxX - visibleFrame.maxX
        let bottomDockGap = visibleFrame.minY - screenFrame.minY

        // Padding for aesthetics
        let bottomPadding: CGFloat = 8
        let sidePadding: CGFloat = 48

        // Panel positioning - use visibleFrame which already accounts for dock
        let panelX = visibleFrame.minX + sidePadding
        let panelWidth = visibleFrame.width - (sidePadding * 2)
        let panelY = visibleFrame.minY + bottomPadding

        // Position at bottom of visible screen area
        let frame = NSRect(
            x: panelX,
            y: panelY,
            width: panelWidth,
            height: panelHeight
        )
        setFrame(frame, display: true)

        // Animate in
        alphaValue = 0
        orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }

        makeKey()
    }

    /// Hide the panel with animation
    func hide(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
            completion?()
        }
    }

    /// Toggle visibility
    func toggle(on screen: NSScreen, compact: Bool = false) {
        if isVisible && alphaValue > 0 {
            hide()
        } else {
            show(on: screen, compact: compact)
        }
    }

    // MARK: - Key handling

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        // Handle Escape to close
        if event.keyCode == 53 { // Escape key
            hide()
            return
        }
        super.keyDown(with: event)
    }

    override func resignKey() {
        super.resignKey()
        // Optionally hide when losing focus
        // hide()
    }
}

// MARK: - Panel Controller

@MainActor
final class BottomPanelController: ObservableObject {
    static let shared = BottomPanelController()

    private var panel: BottomPanel?
    @Published var isVisible: Bool = false

    private init() {}

    func setup<Content: View>(with content: Content) {
        if panel == nil {
            // Create panel only once
            panel = BottomPanel(
                contentRect: .zero,
                styleMask: [],
                backing: .buffered,
                defer: false
            )
        }
        // Always update the content - this replaces the hosting view
        panel?.setContent(content)
    }

    /// Update content only if panel is visible (for live updates)
    func updateContentIfVisible<Content: View>(with content: Content) {
        guard isVisible else { return }
        panel?.setContent(content)
    }

    func show(compact: Bool = false) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        panel?.show(on: screen, compact: compact)
        isVisible = true
    }

    func hide() {
        panel?.hide { [weak self] in
            self?.isVisible = false
        }
    }

    func toggle(compact: Bool = false) {
        if isVisible {
            hide()
        } else {
            show(compact: compact)
        }
    }
}
