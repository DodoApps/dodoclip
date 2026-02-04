import AppKit
import SwiftUI
import Combine

/// Main application delegate managing menu bar and panel
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var panelController: BottomPanelController?

    // Services
    private let clipboardMonitor = ClipboardMonitor.shared
    private let hotkeyManager = HotkeyManager.shared
    private let pasteService = PasteService.shared
  private let collectionService = CollectionService.shared

    // Observers
    private var cancellables = Set<AnyCancellable>()
    
  // State
  private var showingCreateCollectionSheet = false

  func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupBottomPanel()
        setupHotkeys()
        startClipboardMonitoring()

        // Hide dock icon (agent app)
        NSApp.setActivationPolicy(.accessory)

        // Observe new clip count for badge
        clipboardMonitor.$newClipCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)
        
    // Observe collection changes to update panel
    collectionService.objectWillChange
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        // Only update if panel is visible
        if self?.panelController?.isVisible == true {
          self?.updatePanelContent()
        }
      }
      .store(in: &cancellables)

    // Show first-run HUD
        showFirstRunHUDIfNeeded()

        // Perform auto-cleanup if enabled
        clipboardMonitor.checkAutoCleanup()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stopMonitoring()
        hotkeyManager.unregisterAll()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateMenuBarIcon()

            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iconName = clipboardMonitor.isPaused ? "clipboard.fill" : "clipboard"
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "DodoClip")?
            .withSymbolConfiguration(config)
        button.image = image

        let count = clipboardMonitor.newClipCount
        if count > 0 {
            button.title = " \(min(count, 99))"
        } else {
            button.title = ""
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleMainPopover()
        }
    }

    private func toggleMainPopover() {
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }

        let popover = NSPopover()
        popover.contentSize = NSSize(
            width: Theme.Dimensions.menuBarPopoverWidth,
            height: Theme.Dimensions.menuBarPopoverMaxHeight
        )
        popover.behavior = .transient
        popover.animates = true

        let menuBarView = MenuBarPopoverView(
            onPaste: { [weak self] item in
                self?.pasteItem(item)
                self?.popover?.performClose(nil)
            },
            onPastePlainText: { [weak self] item in
                self?.pasteItemPlainText(item)
                self?.popover?.performClose(nil)
            },
            onCopy: { [weak self] item in
                self?.copyItem(item)
            },
            onPin: { [weak self] item in
                self?.togglePin(item)
            },
            onDelete: { [weak self] item in
                self?.deleteItem(item)
            },
            onShowPanel: { [weak self] in
                self?.popover?.performClose(nil)
                self?.showBottomPanel()
            }
        )

        popover.contentViewController = NSHostingController(rootView: menuBarView)
        self.popover = popover

        clipboardMonitor.resetNewClipCount()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: L10n.Menu.showPanel, action: #selector(showBottomPanelAction), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Pause submenu
        if clipboardMonitor.isPaused {
            let resumeItem = NSMenuItem(title: L10n.Menu.resumeCapture, action: #selector(resumeCapture), keyEquivalent: "")
            menu.addItem(resumeItem)
        } else {
            let pauseItem = NSMenuItem(title: L10n.Menu.pauseCapture, action: nil, keyEquivalent: "")
            let pauseMenu = NSMenu()
            pauseMenu.addItem(NSMenuItem(title: L10n.Menu.Pause.fiveMin, action: #selector(pauseFiveMinutes), keyEquivalent: ""))
            pauseMenu.addItem(NSMenuItem(title: L10n.Menu.Pause.fifteenMin, action: #selector(pauseFifteenMinutes), keyEquivalent: ""))
            pauseMenu.addItem(NSMenuItem(title: L10n.Menu.Pause.oneHour, action: #selector(pauseOneHour), keyEquivalent: ""))
            pauseMenu.addItem(NSMenuItem.separator())
            pauseMenu.addItem(NSMenuItem(title: L10n.Menu.Pause.untilResume, action: #selector(pauseUntilResume), keyEquivalent: ""))
            pauseItem.submenu = pauseMenu
            menu.addItem(pauseItem)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.Menu.preferences, action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.Menu.quit, action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    // MARK: - Bottom Panel Setup

    private func setupBottomPanel() {
        panelController = BottomPanelController.shared
        updatePanelContent()
    }

    private func updatePanelContent() {
        let panelContent = createPanelContentView()
        panelController?.setup(with: panelContent)
    }

    private func createPanelContentView() -> PanelContentView {
        PanelContentView(
            collections: collectionService.allCollections,
            isCompact: false,
            onPaste: { [weak self] item in
                self?.pasteItem(item)
                self?.panelController?.hide()
            },
            onCopy: { [weak self] item in
                self?.copyItem(item)
        self?.panelController?.hide()
            },
            onPastePlainText: { [weak self] item in
                self?.pasteItemPlainText(item)
                self?.panelController?.hide()
            },
            onPasteMultiple: { [weak self] items in
                self?.pasteItems(items)
                self?.panelController?.hide()
            },
            onPin: { [weak self] item in
                self?.togglePin(item)
            },
            onDelete: { [weak self] item in
                self?.deleteItem(item)
            },
            onOpen: { [weak self] item in
                self?.openItem(item)
            },
      onCreateCollection: { [weak self] in
        self?.showCreateCollectionSheet()
      },
            onDismiss: { [weak self] in
                self?.panelController?.hide()
            }
        )
    }

    @objc private func showBottomPanelAction() {
        showBottomPanel()
    }

    private func showBottomPanel() {
        updatePanelContent()
        clipboardMonitor.resetNewClipCount()
        panelController?.show()
    }

    // MARK: - Hotkeys

    private func setupHotkeys() {
        hotkeyManager.setupEventHandler()
        hotkeyManager.registerDefaultHotkeys()

        hotkeyManager.onPanelHotkey = { [weak self] in
            // Handle first-run HUD if showing
            if FirstRunController.shared.isShowingHUD {
                FirstRunController.shared.hotkeyPressed()
                return
            }
            self?.panelController?.toggle()
        }

        hotkeyManager.onPasteStackHotkey = { [weak self] in
            self?.activatePasteStack()
        }
    }

    // MARK: - First Run HUD

    private func showFirstRunHUDIfNeeded() {
        FirstRunController.shared.showIfNeeded { [weak self] in
            // First run completed - open the panel
            self?.showBottomPanel()
        }
    }

    // MARK: - Clipboard Monitoring

    private func startClipboardMonitoring() {
        clipboardMonitor.startMonitoring()
    }

    // MARK: - Paste Actions

    private func pasteItem(_ item: ClipItem) {
        pasteService.paste(item)
    }

    private func pasteItemPlainText(_ item: ClipItem) {
        pasteService.paste(item, asPlainText: true)
    }

    private func pasteItems(_ items: [ClipItem]) {
        pasteService.pasteMultiple(items)
    }

    private func copyItem(_ item: ClipItem) {
        pasteService.copyToClipboard(item)
    }

    private func togglePin(_ item: ClipItem) {
        clipboardMonitor.pinItem(item)
        // Don't recreate panel - ClipboardMonitor publishes changes
    }

    private func deleteItem(_ item: ClipItem) {
        clipboardMonitor.deleteItem(item)
        // Don't recreate panel - ClipboardMonitor publishes changes
    }

    private func openItem(_ item: ClipItem) {
        pasteService.open(item)
    }

    // MARK: - Paste Stack

    private func activatePasteStack() {
        // Get selected items from clipboard monitor (most recent items if none selected)
        let items = clipboardMonitor.items.prefix(10)  // Take up to 10 most recent
        guard !items.isEmpty else { return }

        PasteStackManager.shared.activate(with: Array(items))
    }

    // MARK: - Menu Actions

    @objc private func pauseFiveMinutes() {
        clipboardMonitor.pause(for: .fiveMinutes)
        updateMenuBarIcon()
    }

    @objc private func pauseFifteenMinutes() {
        clipboardMonitor.pause(for: .fifteenMinutes)
        updateMenuBarIcon()
    }

    @objc private func pauseOneHour() {
        clipboardMonitor.pause(for: .oneHour)
        updateMenuBarIcon()
    }

    @objc private func pauseUntilResume() {
        clipboardMonitor.pause(for: .untilResume)
        updateMenuBarIcon()
    }

    @objc private func resumeCapture() {
        clipboardMonitor.resumeCapture()
        updateMenuBarIcon()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showSettings()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
  // MARK: - Collection Management

  private func showCreateCollectionSheet() {
    let sheetView = CreateCollectionSheet { [weak self] name, icon, color in
      self?.collectionService.createCollection(name: name, icon: icon, colorHex: color)
      // Refresh panel to show new collection
      self?.updatePanelContent()
    }

    let hostingController = NSHostingController(rootView: sheetView)

    // Create a window for the sheet
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.center()
    window.title = "New Collection"
    window.contentViewController = hostingController
    window.isReleasedWhenClosed = false

    // Set window level above everything else (including preview window)
    window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))

    // Make sure window can become key and receive keyboard input
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
