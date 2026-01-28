import Foundation
import AppKit
import Combine

/// Manages the Paste Stack feature for sequential pasting
/// Activated with ⇧⌘C, allows pasting multiple items one at a time
@MainActor
final class PasteStackManager: ObservableObject {
    static let shared = PasteStackManager()

    @Published var isActive: Bool = false
    @Published var items: [ClipItem] = []
    @Published var currentIndex: Int = 0

    private var pasteService: PasteService { PasteService.shared }

    private init() {}

    /// Total number of items in the stack
    var totalCount: Int {
        items.count
    }

    /// Number of items remaining to paste
    var remainingCount: Int {
        max(0, items.count - currentIndex)
    }

    /// Current item to be pasted (if any)
    var currentItem: ClipItem? {
        guard isActive, currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    /// Activate paste stack with selected items
    /// - Parameter selectedItems: Items to paste sequentially
    func activate(with selectedItems: [ClipItem]) {
        guard !selectedItems.isEmpty else { return }

        items = selectedItems
        currentIndex = 0
        isActive = true

        // Show indicator
        PasteStackIndicatorWindow.shared.show(manager: self)
    }

    /// Paste the next item in the stack
    /// - Returns: The item that was pasted, or nil if stack is empty
    @discardableResult
    func pasteNext() -> ClipItem? {
        guard isActive, currentIndex < items.count else {
            deactivate()
            return nil
        }

        let item = items[currentIndex]
        currentIndex += 1

        // Paste the item
        pasteService.paste(item)

        // Update indicator
        PasteStackIndicatorWindow.shared.updateIndicator()

        // Deactivate if we've pasted all items
        if currentIndex >= items.count {
            // Small delay before deactivating to show completion
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    self.deactivate()
                }
            }
        }

        return item
    }

    /// Deactivate paste stack and reset state
    func deactivate() {
        isActive = false
        items = []
        currentIndex = 0

        // Hide indicator
        PasteStackIndicatorWindow.shared.hide()
    }

    /// Skip the current item without pasting
    func skipCurrent() {
        guard isActive, currentIndex < items.count else {
            deactivate()
            return
        }

        currentIndex += 1
        PasteStackIndicatorWindow.shared.updateIndicator()

        if currentIndex >= items.count {
            deactivate()
        }
    }
}

// MARK: - Paste Stack Indicator Window

/// Floating indicator window showing paste stack status
final class PasteStackIndicatorWindow: NSPanel {
    static let shared = PasteStackIndicatorWindow()

    private var hostingView: NSHostingView<PasteStackIndicatorView>?
    private weak var manager: PasteStackManager?

    private override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isMovableByWindowBackground = true
    }

    private convenience init() {
        self.init(contentRect: .zero, styleMask: [], backing: .buffered, defer: false)
    }

    func show(manager: PasteStackManager) {
        self.manager = manager

        let indicatorView = PasteStackIndicatorView(manager: manager)
        let hostingView = NSHostingView(rootView: indicatorView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        contentView = hostingView
        self.hostingView = hostingView

        // Position at top-right of main screen
        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 220
            let y = screen.visibleFrame.maxY - 80
            setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Fade in
        alphaValue = 0
        orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }

    func updateIndicator() {
        // SwiftUI will automatically update via @ObservedObject
    }

    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
        }
    }
}

// MARK: - Paste Stack Indicator View

import SwiftUI

struct PasteStackIndicatorView: View {
    @ObservedObject var manager: PasteStackManager

    var body: some View {
        HStack(spacing: 12) {
            // Stack icon
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Paste Stack")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("\(manager.currentIndex)/\(manager.totalCount) pasted")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Theme.Colors.textSecondary.opacity(0.3), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: progress)
            }
            .frame(width: 24, height: 24)

            // Close button
            Button {
                manager.deactivate()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.panelBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.Colors.divider, lineWidth: 1)
        )
    }

    private var progress: CGFloat {
        guard manager.totalCount > 0 else { return 0 }
        return CGFloat(manager.currentIndex) / CGFloat(manager.totalCount)
    }
}
