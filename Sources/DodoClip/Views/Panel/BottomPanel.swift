import AppKit
import SwiftUI

/// Custom view that handles mouse clicks
class ClickableOverlayView: NSView {
    var onClicked: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        onClicked?()
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

/// Overlay window that covers the entire screen with a semi-transparent black mask
final class OverlayWindow: NSWindow {
    var onClickOutside: (() -> Void)?
    
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        configureOverlay()
    }
    
    private func configureOverlay() {
        // Window level - below the panel but above everything else
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        
        // Make it transparent
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        
        // Create custom view that handles clicks
        let overlayView = ClickableOverlayView()
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        overlayView.onClicked = { [weak self] in
            self?.onClickOutside?()
        }
        
        contentView = overlayView
    }
    
    func show(on screen: NSScreen) {
        let frame = screen.frame
        setFrame(frame, display: true)
        
        alphaValue = 0
        orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }
    
    func hide(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
            completion?()
        }
    }
}

/// Preview window that shows the selected clipboard item in the center
final class PreviewWindow: NSWindow {
    private var hostingController: NSHostingController<AnyView>?
    
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        configurePreview()
    }
    
    private func configurePreview() {
        // Window level - above overlay, below panel
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        
        // Appearance
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        ignoresMouseEvents = false
        
        // Visual effect background
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true
        
        contentView = visualEffect
    }
    
    func setContent<Content: View>(_ content: Content) {
        if let existingController = hostingController {
            existingController.rootView = AnyView(content)
        } else {
            let controller = NSHostingController(rootView: AnyView(content))
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            
            if let visualEffect = contentView as? NSVisualEffectView {
                visualEffect.addSubview(controller.view)
                NSLayoutConstraint.activate([
                    controller.view.topAnchor.constraint(equalTo: visualEffect.topAnchor),
                    controller.view.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
                    controller.view.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
                    controller.view.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
                ])
                
                self.hostingController = controller
            }
        }
    }
    
    func show(on screen: NSScreen, panelFrame: NSRect) {
        // Calculate preview window size and position
        let maxWidth: CGFloat = 600
        let maxHeight: CGFloat = 500
        let screenFrame = screen.frame
        
        // Top constraint: screen top with padding
        let topPadding: CGFloat = 60
        let maxTop = screenFrame.maxY - topPadding
        
        // Bottom constraint: panel top with padding
        let bottomPadding: CGFloat = 20
        let minBottom = panelFrame.maxY + bottomPadding
        
        // Calculate available height
        let availableHeight = maxTop - minBottom
        let previewHeight = min(maxHeight, availableHeight)
        let previewWidth = min(maxWidth, screenFrame.width - 200)
        
        // Center horizontally, vertically in available space
        let previewX = screenFrame.midX - previewWidth / 2
        let previewY = minBottom + (availableHeight - previewHeight) / 2
        
        let frame = NSRect(
            x: previewX,
            y: previewY,
            width: previewWidth,
            height: previewHeight
        )
        setFrame(frame, display: true)
        
        alphaValue = 0
        orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }
    
    func hide(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
            completion?()
        }
    }
}

/// SwiftUI preview content view
struct PreviewContentView: View {
    let item: ClipItem
    @State private var cachedContent: ClipContent?
    @State private var cachedThumbnail: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.sourceAppName ?? "Unknown")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text(item.relativeTimeString)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                }
                
                Spacer()
                
                // Type badge
                Text(item.contentType.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.badge(for: item.contentType))
                    .clipShape(Capsule())
            }
            
            Divider()
                .background(Theme.Colors.divider)
            
            // Content preview
            ScrollView {
                previewContent
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            loadContent()
        }
        .onChange(of: item.id) { _, _ in
            loadContent()
        }
    }
    
    @ViewBuilder
    private var previewContent: some View {
        switch item.contentType {
            case .text, .richText:
                textPreview
            case .image:
                imagePreview
            case .link:
                linkPreview
            case .file:
                filePreview
            case .color:
                colorPreview
        }
    }
    
    private var textPreview: some View {
        Text(item.plainText ?? "")
            .font(.system(size: 14))
            .foregroundColor(Theme.Colors.textPrimary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var imagePreview: some View {
        Group {
            if let thumbnail = cachedThumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 400)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    if let dims = item.imageDimensions {
                        Text(dims)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var linkPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = item.linkTitle, !title.isEmpty {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            Text(item.plainText ?? "")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "5AC8FA"))
                .textSelection(.enabled)
        }
    }
    
    private var filePreview: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.badgeFile)
            
            Text(item.fileName ?? "File")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textPrimary)
        }
    }
    
    private var colorPreview: some View {
        VStack(spacing: 16) {
            if let colorValue = cachedContent?.colorValue {
                Rectangle()
                    .fill(Color(nsColor: colorValue))
                    .frame(width: 200, height: 200)
                    .cornerRadius(12)
            }
            
            Text(item.plainText ?? "")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.Colors.textPrimary)
                .textSelection(.enabled)
        }
    }
    
    private var appIcon: NSImage? {
        guard let bundleID = item.sourceAppBundleID else { return nil }
        return ImageCacheService.shared.appIcon(for: bundleID)
    }
    
    private func loadContent() {
        cachedContent = item.content
        
        if item.contentType == .image, let content = cachedContent {
            cachedThumbnail = ImageCacheService.shared.thumbnail(
                for: item.id,
                imageData: content.activeData
            )
        }
    }
}

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
        // Window level and behavior - higher than overlay
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
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
            // Use controller's hide method to close all windows (panel, overlay, preview)
            BottomPanelController.shared.hide()
            return
        }
        super.keyDown(with: event)
    }

    override func resignKey() {
        super.resignKey()
        // Hide when losing focus if setting is enabled
        if SettingsService.shared.closeOnFocusLoss {
            // Use controller's hide method to close all windows
            BottomPanelController.shared.hide()
        }
    }
}

// MARK: - Panel Controller

@MainActor
final class BottomPanelController: ObservableObject {
    static let shared = BottomPanelController()

    private var panel: BottomPanel?
    private var overlayWindow: OverlayWindow?
  private var previewWindow: PreviewWindow?
    @Published var isVisible: Bool = false
  @Published var selectedItem: ClipItem?

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
        
    // Create overlay window if not exists
    if overlayWindow == nil {
      overlayWindow = OverlayWindow(
        contentRect: .zero,
        styleMask: [],
        backing: .buffered,
        defer: false
      )
      overlayWindow?.onClickOutside = { [weak self] in
        // Only hide when closeOnFocusLoss setting is enabled
        if SettingsService.shared.closeOnFocusLoss {
          self?.hide()
        }
      }
    }

    // Create preview window if not exists
    if previewWindow == nil {
      previewWindow = PreviewWindow(
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
        
        // Show overlay first
        overlayWindow?.show(on: screen)
        
    // Calculate panel frame for preview positioning
    let panelHeight = compact ? Theme.Dimensions.panelHeightCompact : Theme.Dimensions.panelHeight
    let visibleFrame = screen.visibleFrame
    let sidePadding: CGFloat = 48
    let bottomPadding: CGFloat = 8
    let panelFrame = NSRect(
      x: visibleFrame.minX + sidePadding,
      y: visibleFrame.minY + bottomPadding,
      width: visibleFrame.width - (sidePadding * 2),
      height: panelHeight
    )

    // Show preview if there's a selected item
    if let item = selectedItem {
      updatePreview(for: item, screen: screen, panelFrame: panelFrame)
    }

    // Then show panel on top
        panel?.show(on: screen, compact: compact)
        isVisible = true
    }
    
    func hide() {
    // Hide preview
    previewWindow?.hide()

    // Hide overlay
        overlayWindow?.hide()

        // Hide panel
        panel?.hide { [weak self] in
            self?.isVisible = false
        }
    }
    
  func updateSelectedItem(_ item: ClipItem?) {
    selectedItem = item

    guard isVisible else { return }
    guard let item = item else {
      previewWindow?.hide()
      return
    }

    guard let screen = NSScreen.main ?? NSScreen.screens.first,
      let panelFrame = panel?.frame
    else { return }

    updatePreview(for: item, screen: screen, panelFrame: panelFrame)
  }

  private func updatePreview(for item: ClipItem, screen: NSScreen, panelFrame: NSRect) {
    let previewView = PreviewContentView(item: item)
    previewWindow?.setContent(previewView)
    previewWindow?.show(on: screen, panelFrame: panelFrame)
  }

  func toggle(compact: Bool = false) {
        if isVisible {
            hide()
        } else {
            show(compact: compact)
        }
    }
}
