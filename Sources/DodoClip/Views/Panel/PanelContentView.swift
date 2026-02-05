import SwiftUI
import SwiftData

/// Main content view for the bottom panel
struct PanelContentView: View {
    // Observe clipboard monitor directly for live updates
    @ObservedObject private var clipboardMonitor = ClipboardMonitor.shared
    
    // State
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @State private var selectedItemID: UUID?
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var selectedCollectionID: UUID?
    @State private var selectedTypes: Set<ClipContentType> = []
    @State private var draggedItemID: UUID?
    
    // Performance: limit visible items to improve render performance
    private let initialVisibleLimit = 50
    @State private var visibleLimit = 50
    
    // Data (items now come from clipboardMonitor)
    let collections: [Collection]
    let isCompact: Bool
    
    // Actions
    var onPaste: ((ClipItem) -> Void)?
    var onCopy: ((ClipItem) -> Void)?
    var onPastePlainText: ((ClipItem) -> Void)?
    var onPasteMultiple: (([ClipItem]) -> Void)?
    var onPin: ((ClipItem) -> Void)?
    var onDelete: ((ClipItem) -> Void)?
    var onOpen: ((ClipItem) -> Void)?
    var onCreateCollection: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    // Use items from clipboard monitor
    private var items: [ClipItem] {
        clipboardMonitor.items
    }
    
    private var filteredItems: [ClipItem] {
        var result = items.filter { !$0.isDeleted }
        
        // Filter by search text
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            result = result.filter { item in
                item.plainText?.lowercased().contains(lowercased) == true ||
                item.ocrText?.lowercased().contains(lowercased) == true ||
                item.title?.lowercased().contains(lowercased) == true ||
                item.sourceAppName?.lowercased().contains(lowercased) == true
            }
        }
        
        // Filter by type
        if !selectedTypes.isEmpty {
            result = result.filter { selectedTypes.contains($0.contentType) }
        }
        
        // Filter by collection
        if let collectionID = selectedCollectionID,
           let collection = collections.first(where: { $0.id == collectionID }) {
            if let smartType = collection.smartFilterType {
                // Smart collection - filter by content type
                result = result.filter { $0.contentType == smartType }
            } else {
                // Manual collection - filter by membership
                result = result.filter { item in
                    item.collections?.contains { $0.id == collectionID } == true
                }
            }
        }
        
        return result
    }
    
    private var pinnedItems: [ClipItem] {
        filteredItems.filter { $0.isPinned }
    }
    
    private var unpinnedItems: [ClipItem] {
        filteredItems.filter { !$0.isPinned }
    }
    
    /// Limited unpinned items for performance (pinned always shown)
    private var visibleUnpinnedItems: [ClipItem] {
        let pinCount = pinnedItems.count
        let remainingLimit = max(0, visibleLimit - pinCount)
        return Array(unpinnedItems.prefix(remainingLimit))
    }
    
    private var allItems: [ClipItem] {
        pinnedItems + unpinnedItems
    }
    
    /// Items currently visible (for display)
    private var visibleItems: [ClipItem] {
        pinnedItems + visibleUnpinnedItems
    }
    
    /// Whether there are more items to load
    private var hasMoreItems: Bool {
        visibleUnpinnedItems.count < unpinnedItems.count
    }
    
    /// Count of hidden items
    private var hiddenItemsCount: Int {
        unpinnedItems.count - visibleUnpinnedItems.count
    }
    
    private var selectedIndex: Int? {
        guard let id = selectedItemID else { return nil }
        return allItems.firstIndex { $0.id == id }
    }
    
    @ObservedObject private var settingsService = SettingsService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar: Search + Filters + Settings + Close button
            HStack(spacing: 8) {
                topBar
                
                // Settings button
                Button {
                    SettingsWindowController.shared.showSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Settings (⌘,)")
                
                // Close button (if enabled in settings)
                if settingsService.showCloseButton {
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Close panel (Esc)")
                }
            }
            .padding(.horizontal, Theme.Dimensions.panelPadding)
            .padding(.top, Theme.Dimensions.panelPadding)
            
            // Collection tabs (includes type filtering via smart collections)
            CollectionTabsView(
                selectedCollectionID: $selectedCollectionID,
                collections: collections,
                onCreateCollection: onCreateCollection,
                onDeleteCollection: { collection in
                    CollectionService.shared.deleteCollection(collection)
                },
                onRenameCollection: { collection in
                    showRenameSheet(for: collection)
        },
        onAddItemToCollection: { itemID, collection in
          handleAddItemToCollection(itemID: itemID, collection: collection)
                }
            )
            .padding(.vertical, 8)
            
            Divider()
                .background(Theme.Colors.divider)
            
            // Cards scroll view or empty state
            if allItems.isEmpty {
                emptyState
            } else {
                cardsScrollView
            }
            
            // Bottom hint bar
            keyboardHintsBar
        }
        .panelBackground()
        .onAppear {
            // Don't auto-focus search bar - user should click it or press ⌘F
            // This prevents accidentally pasting into search bar instead of target app
            isSearchFocused = false
            selectFirstItemIfNeeded()
        }
        .onChange(of: searchText) { _, _ in
            // Reset visible limit when search changes
            visibleLimit = initialVisibleLimit
        }
        .onChange(of: selectedCollectionID) { _, _ in
            // Reset visible limit when collection changes
            visibleLimit = initialVisibleLimit
        }
        .onKeyPress(.escape) {
            if !searchText.isEmpty {
                searchText = ""
                return .handled
            }
            onDismiss?()
            return .handled
        }
        .onKeyPress(.leftArrow, phases: .down) { press in
            if press.modifiers.contains(.shift) {
                extendSelection(by: -1)
            } else {
                navigateSelection(by: -1)
            }
            return .handled
        }
        .onKeyPress(.rightArrow, phases: .down) { press in
            if press.modifiers.contains(.shift) {
                extendSelection(by: 1)
            } else {
                navigateSelection(by: 1)
            }
            return .handled
        }
        .onKeyPress(.return, phases: .down) { press in
            if press.modifiers.contains(.shift) {
                pasteSelectedItemPlainText()
            } else {
                pasteSelectedItem()
            }
            return .handled
        }
        .onKeyPress(.delete) {
            deleteSelectedItem()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "aApPcC")) { press in
            // ⌘A to select all
            if press.modifiers.contains(.command) && press.characters.lowercased() == "a" {
                selectAll()
                return .handled
            }
            // ⌘P to pin/unpin
            if press.modifiers.contains(.command) && press.characters.lowercased() == "p" {
                pinSelectedItem()
                return .handled
            }
            // ⇧⌘C to activate paste stack with selection
            if press.modifiers.contains(.command) && press.modifiers.contains(.shift) && press.characters.lowercased() == "c" {
                activatePasteStackWithSelection()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "fF")) { press in
            // ⌘F to focus search bar
            if press.modifiers.contains(.command) {
                isSearchFocused = true
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: CharacterSet(charactersIn: ",")) { press in
            // ⌘, to open settings
            if press.modifiers.contains(.command) {
                SettingsWindowController.shared.showSettings()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "123456789")) { press in
            if let number = Int(press.characters), number >= 1 && number <= 9 {
                if press.modifiers.contains(.shift) {
                    // ⇧⌘1-9 for plain text paste
                    pasteItemAtIndexPlainText(number - 1)
                } else {
                    // ⌘1-9 for quick paste
                    pasteItemAtIndex(number - 1)
                }
                return .handled
            }
            return .ignored
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.4))
            
            Text(emptyStateTitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
            
            Text(emptyStateSubtitle)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        } else if !selectedTypes.isEmpty {
            return "line.3.horizontal.decrease.circle"
        } else if selectedCollectionID != nil {
            return "folder"
        } else {
            return "clipboard"
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return L10n.Panel.noResults
        } else if !selectedTypes.isEmpty {
            return L10n.Panel.noClipsOfType
        } else if selectedCollectionID != nil {
            return L10n.Panel.collectionEmpty
        } else {
            return L10n.Panel.noItems
        }
    }
    
    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return L10n.Panel.tryDifferentSearch
        } else if selectedCollectionID != nil {
            return L10n.Panel.noItemsMatchFilter
        } else {
            return L10n.Panel.copyToSeeHere
        }
    }
    
    // MARK: - Keyboard Hints Bar
    
    private var keyboardHintsBar: some View {
        HStack(spacing: 12) {
            keyboardHint("←→", L10n.Keyboard.navigate)
            keyboardHint("⇧←→", L10n.Keyboard.multiSelect)
            keyboardHint("↵", L10n.Keyboard.paste)
            keyboardHint("⇧↵", L10n.Keyboard.plainText)
            keyboardHint("⌘1-9", L10n.Keyboard.quickPaste)
            keyboardHint("⌘A", L10n.Keyboard.selectAll)
            keyboardHint("⌘P", L10n.Keyboard.pin)
            keyboardHint("esc", L10n.Keyboard.close)
            
            Spacer()
            
            if selectedItemIDs.count > 1 {
                Text("\(selectedItemIDs.count) \(L10n.Panel.selected)")
                    .font(Theme.Typography.keyboardHintLabel)
                    .foregroundColor(Theme.Colors.accent)
            }
            
            if hasMoreItems {
                Text("\(visibleItems.count)/\(allItems.count) \(L10n.Panel.clips)")
                    .font(Theme.Typography.keyboardHintLabel)
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
            } else {
                Text("\(allItems.count) \(L10n.Panel.clips)")
                    .font(Theme.Typography.keyboardHintLabel)
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
            }
        }
        .padding(.horizontal, Theme.Dimensions.panelPadding)
        .padding(.vertical, 8)
        .background(Theme.Colors.panelBackground.opacity(0.95))
    }
    
    private func keyboardHint(_ shortcut: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(shortcut)
                .font(Theme.Typography.keyboardShortcut)
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.9))
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Theme.Colors.filterChipBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Text(label)
                .font(Theme.Typography.keyboardHintLabel)
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
        }
    }
    
    // MARK: - Keyboard Navigation
    
    private func selectFirstItemIfNeeded() {
        if selectedItemID == nil, let firstItem = allItems.first {
            selectedItemID = firstItem.id
            selectedItemIDs = [firstItem.id]
            BottomPanelController.shared.updateSelectedItem(firstItem)
        }
    }
    
    private func navigateSelection(by delta: Int) {
        let items = allItems
        guard !items.isEmpty else { return }
        
        let currentIndex = selectedIndex ?? -1
        var newIndex = currentIndex + delta
        
        // Wrap around
        if newIndex < 0 {
            newIndex = items.count - 1
        } else if newIndex >= items.count {
            newIndex = 0
        }
        
        selectedItemID = items[newIndex].id
        selectedItemIDs = [items[newIndex].id]
        BottomPanelController.shared.updateSelectedItem(items[newIndex])
    }
    
    private func extendSelection(by delta: Int) {
        let items = allItems
        guard !items.isEmpty else { return }
        
        let currentIndex = selectedIndex ?? 0
        var newIndex = currentIndex + delta
        
        // Clamp to bounds (no wrap for multi-select)
        newIndex = max(0, min(items.count - 1, newIndex))
        
        // Add to selection
        selectedItemID = items[newIndex].id
        selectedItemIDs.insert(items[newIndex].id)
    }
    
    private func selectAll() {
        selectedItemIDs = Set(allItems.map { $0.id })
        if let first = allItems.first {
            selectedItemID = first.id
        }
    }
    
    private func pasteSelectedItem() {
        guard let id = selectedItemID,
              let item = allItems.first(where: { $0.id == id }) else { return }
        handlePaste(item)
    }
    
    private func pasteSelectedItemPlainText() {
        guard let id = selectedItemID,
              let item = allItems.first(where: { $0.id == id }) else { return }
        if selectedItemIDs.count > 1 {
            // For multi-select, paste all as plain text (concatenated)
            let itemsToPaste = allItems.filter { selectedItemIDs.contains($0.id) }
            for pasteItem in itemsToPaste {
                onPastePlainText?(pasteItem)
            }
        } else {
            onPastePlainText?(item)
        }
    }
    
    private func pasteItemAtIndex(_ index: Int) {
        let items = allItems
        guard index < items.count else { return }
        handlePaste(items[index])
    }
    
    private func pasteItemAtIndexPlainText(_ index: Int) {
        let items = allItems
        guard index < items.count else { return }
        onPastePlainText?(items[index])
    }
    
    private func pinSelectedItem() {
        guard let id = selectedItemID,
              let item = allItems.first(where: { $0.id == id }) else { return }
        onPin?(item)
    }
    
    private func deleteSelectedItem() {
        guard let id = selectedItemID,
              let item = allItems.first(where: { $0.id == id }) else { return }
        onDelete?(item)
        // Select next item
        navigateSelection(by: 1)
    }
    
    private func activatePasteStackWithSelection() {
        // Get selected items or use all items if none selected
        let itemsToStack: [ClipItem]
        if selectedItemIDs.count > 1 {
            itemsToStack = allItems.filter { selectedItemIDs.contains($0.id) }
        } else {
            // Use first 10 items
            itemsToStack = Array(allItems.prefix(10))
        }
        
        guard !itemsToStack.isEmpty else { return }
        
        // Dismiss panel and activate paste stack
        onDismiss?()
        PasteStackManager.shared.activate(with: itemsToStack)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        SearchBar(
            searchText: $searchText,
            isSearchFocused: $isSearchFocused,
            onSearch: { _ in }
        )
    }
    
    // MARK: - Cards Scroll View
    
    private var cardsScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Theme.Dimensions.cardSpacing) {
                    // Pinned items first
                    if !pinnedItems.isEmpty {
                        pinnedSection
                        
                        // Divider between pinned and regular
                        VStack {
                            Rectangle()
                                .fill(Theme.Colors.divider)
                                .frame(width: 1)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Regular items (limited for performance)
                    ForEach(Array(visibleUnpinnedItems.enumerated()), id: \.element.id) { index, item in
                        cardView(for: item, index: pinnedItems.count + index)
                            .onDrag {
                                draggedItemID = item.id
                                return NSItemProvider(object: item.id.uuidString as NSString)
                            }
                    }
                    
                    // Load more button if there are hidden items
                    if hasMoreItems {
                        loadMoreButton
                    }
                }
                .padding(.horizontal, Theme.Dimensions.panelPadding)
                .padding(.vertical, Theme.Dimensions.cardSpacing)
            }
            .onChange(of: selectedItemID) { _, newID in
                if let id = newID {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
    
    private var loadMoreButton: some View {
        Button {
            withAnimation {
                visibleLimit += 50
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.accent)
                
                Text("+\(hiddenItemsCount) \(L10n.Panel.more)")
                    .font(Theme.Typography.cardMeta)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .frame(width: 80, height: Theme.Dimensions.cardHeight - 20)
            .background(Theme.Colors.cardBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius)
                    .stroke(Theme.Colors.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var pinnedSection: some View {
        ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
            cardView(for: item, index: index)
                .onDrag {
                    draggedItemID = item.id
                    return NSItemProvider(object: item.id.uuidString as NSString)
                }
        }
    }
    
    private func cardView(for item: ClipItem, index: Int) -> some View {
        ClipCardView(
            item: item,
            isSelected: selectedItemID == item.id || selectedItemIDs.contains(item.id),
            isCompact: isCompact,
            index: index,
            onSelect: { handleSelection(item) },
            onPaste: { handlePaste(item) },
            onCopy: { onCopy?(item) },
            onPastePlainText: { onPastePlainText?(item) },
            onPin: { onPin?(item) },
      onDelete: { onDelete?(item) },
      onOpen: { onOpen?(item) },
      customCollections: collections.filter { !$0.isSmartCollection },
      onCreateCollection: onCreateCollection,
      onAddToCollection: { collection in
        handleAddItemToCollection(itemID: item.id, collection: collection)
            }
        )
        .id(item.id)
        .onDrop(
            of: [.text],
            delegate: CardDropDelegate(
                item: item,
                items: items,
                draggedItemID: $draggedItemID,
                onMove: { sourceID, targetID in
                    handleMove(sourceID: sourceID, targetID: targetID)
                }
            )
        )
        .opacity(draggedItemID == item.id ? 0.5 : 1.0)
    }
    
    private func handleMove(sourceID: UUID, targetID: UUID) {
        guard let sourceIndex = items.firstIndex(where: { $0.id == sourceID }),
              let destinationIndex = items.firstIndex(where: { $0.id == targetID })
        else {
            return
        }
        
        // Only allow reordering within same category (pinned/unpinned)
        let sourceItem = items[sourceIndex]
        let targetItem = items[destinationIndex]
        if sourceItem.isPinned != targetItem.isPinned {
            return
        }
        
        // Perform the move
        clipboardMonitor.moveItem(from: sourceIndex, to: destinationIndex)
        
        draggedItemID = nil
    }
    
    // MARK: - Selection Handling
    
    private func handleSelection(_ item: ClipItem) {
        if selectedItemID == item.id {
            selectedItemID = nil
            BottomPanelController.shared.updateSelectedItem(nil)
        } else {
            selectedItemID = item.id
            selectedItemIDs = [item.id]
            BottomPanelController.shared.updateSelectedItem(item)
        }
    }
    
    private func handlePaste(_ item: ClipItem) {
        if selectedItemIDs.count > 1 {
            let itemsToPaste = filteredItems.filter { selectedItemIDs.contains($0.id) }
            onPasteMultiple?(itemsToPaste)
        } else {
            onPaste?(item)
        }
    }
    
    private func showRenameSheet(for collection: Collection) {
        let renameView = RenameCollectionSheet(originalName: collection.name) { newName in
            CollectionService.shared.renameCollection(collection, newName: newName)
        }
        
        let hostingController = NSHostingController(rootView: renameView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L10n.Collection.rename
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        // Set window level above everything else (including preview window)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
    // Make sure window can become key and receive keyboard input
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func handleAddItemToCollection(itemID: UUID, collection: Collection) {
    // Find the item from all items
    guard let item = items.first(where: { $0.id == itemID }) else {
      return
    }

    // Add item to collection using collection ID to ensure proper context
    ClipboardMonitor.shared.addItemToCollection(item, collectionID: collection.id)
    }
}

/// Drop delegate for handling card reordering
struct CardDropDelegate: DropDelegate {
    let item: ClipItem
    let items: [ClipItem]
    @Binding var draggedItemID: UUID?
    let onMove: (UUID, UUID) -> Void
    
    func dropEntered(info: DropInfo) {
        // Visual feedback could be added here
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedID = draggedItemID else { return false }
        
        if draggedID != item.id {
            onMove(draggedID, item.id)
        }
        
        draggedItemID = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Preview

#Preview("Panel Content") {
    PanelContentView(
        collections: Collection.defaultCollections,
        isCompact: false,
        onPaste: { item in print("Paste: \(item.contentPreview)") },
        onDismiss: { print("Dismiss") }
    )
    .frame(height: Theme.Dimensions.panelHeight)
}

#Preview("Panel Content - Empty") {
    PanelContentView(
        collections: Collection.defaultCollections,
        isCompact: false,
        onPaste: { _ in },
        onDismiss: {}
    )
    .frame(height: Theme.Dimensions.panelHeight)
}
