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
    @State private var showFilters = false

    // Data (items now come from clipboardMonitor)
    let collections: [Collection]
    let isCompact: Bool

    // Actions
    var onPaste: ((ClipItem) -> Void)?
    var onPastePlainText: ((ClipItem) -> Void)?
    var onPasteMultiple: (([ClipItem]) -> Void)?
    var onPin: ((ClipItem) -> Void)?
    var onDelete: ((ClipItem) -> Void)?
    var onOpen: ((ClipItem) -> Void)?
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

    private var allItems: [ClipItem] {
        pinnedItems + unpinnedItems
    }

    private var selectedIndex: Int? {
        guard let id = selectedItemID else { return nil }
        return allItems.firstIndex { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: Search + Filters
            topBar

            if showFilters {
                FilterChipsRow(selectedTypes: $selectedTypes)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Collection tabs
            CollectionTabsView(
                selectedCollectionID: $selectedCollectionID,
                collections: collections
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
            isSearchFocused = true
            selectFirstItemIfNeeded()
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
            // ⌘F to toggle filters
            if press.modifiers.contains(.command) {
                withAnimation(Theme.Animation.filterChip) {
                    showFilters.toggle()
                }
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
            return "No matches found"
        } else if !selectedTypes.isEmpty {
            return "No clips of this type"
        } else if selectedCollectionID != nil {
            return "Collection is empty"
        } else {
            return "No clips yet"
        }
    }

    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return "Try a different search term"
        } else if !selectedTypes.isEmpty {
            return "Try removing some filters"
        } else if selectedCollectionID != nil {
            return "Add clips to this collection from the context menu"
        } else {
            return "Copy something to see it here\nPress ⇧⌘V anytime to open"
        }
    }

    // MARK: - Keyboard Hints Bar

    private var keyboardHintsBar: some View {
        HStack(spacing: 12) {
            keyboardHint("←→", "Navigate")
            keyboardHint("⇧←→", "Multi-select")
            keyboardHint("↵", "Paste")
            keyboardHint("⇧↵", "Plain text")
            keyboardHint("⌘1-9", "Quick paste")
            keyboardHint("⌘A", "Select all")
            keyboardHint("⌘P", "Pin")
            keyboardHint("esc", "Close")

            Spacer()

            if selectedItemIDs.count > 1 {
                Text("\(selectedItemIDs.count) selected")
                    .font(Theme.Typography.cardMeta)
                    .foregroundColor(Theme.Colors.accent)
            }

            Text("\(allItems.count) clips")
                .font(Theme.Typography.cardMeta)
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, Theme.Dimensions.panelPadding)
        .padding(.vertical, 8)
        .background(Theme.Colors.panelBackground.opacity(0.95))
    }

    private func keyboardHint(_ shortcut: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(shortcut)
                .font(Theme.Typography.keyboardShortcut)
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.8))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Theme.Colors.filterChipBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text(label)
                .font(Theme.Typography.cardMeta)
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
        }
    }

    // MARK: - Keyboard Navigation

    private func selectFirstItemIfNeeded() {
        if selectedItemID == nil, let firstItem = allItems.first {
            selectedItemID = firstItem.id
            selectedItemIDs = [firstItem.id]
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
        HStack(spacing: 12) {
            SearchBar(
                searchText: $searchText,
                isSearchFocused: $isSearchFocused,
                onSearch: { _ in }
            )

            // Filter toggle
            Button {
                withAnimation(Theme.Animation.filterChip) {
                    showFilters.toggle()
                }
            } label: {
                Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18))
                    .foregroundColor(showFilters || !selectedTypes.isEmpty ? Theme.Colors.accent : Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Filter by type (⌘F)")

        }
        .padding(.horizontal, Theme.Dimensions.panelPadding)
        .padding(.top, Theme.Dimensions.panelPadding)
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

                    // Regular items
                    ForEach(Array(unpinnedItems.enumerated()), id: \.element.id) { index, item in
                        cardView(for: item, index: pinnedItems.count + index)
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

    private var pinnedSection: some View {
        ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
            cardView(for: item, index: index)
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
            onPastePlainText: { onPastePlainText?(item) },
            onPin: { onPin?(item) },
            onDelete: { onDelete?(item) },
            onOpen: { onOpen?(item) }
        )
        .id(item.id)
    }

    // MARK: - Selection Handling

    private func handleSelection(_ item: ClipItem) {
        if selectedItemID == item.id {
            selectedItemID = nil
        } else {
            selectedItemID = item.id
            selectedItemIDs = [item.id]
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
