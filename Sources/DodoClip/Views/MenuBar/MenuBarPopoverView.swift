import SwiftUI

/// Quick access menu bar popover view
struct MenuBarPopoverView: View {
    // Observe clipboard monitor directly for live updates
    @ObservedObject private var clipboardMonitor = ClipboardMonitor.shared

    var onPaste: ((ClipItem) -> Void)?
    var onPastePlainText: ((ClipItem) -> Void)?
    var onCopy: ((ClipItem) -> Void)?
    var onPin: ((ClipItem) -> Void)?
    var onDelete: ((ClipItem) -> Void)?
    var onShowPanel: (() -> Void)?

    @State private var searchText = ""
    @State private var selectedIndex: Int = 0

    private var items: [ClipItem] {
        clipboardMonitor.items
    }

    private var filteredItems: [ClipItem] {
        if searchText.isEmpty {
            return items
        }
        let lowercased = searchText.lowercased()
        return items.filter { item in
            item.plainText?.lowercased().contains(lowercased) == true ||
            item.title?.lowercased().contains(lowercased) == true ||
            item.sourceAppName?.lowercased().contains(lowercased) == true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()
                .background(Theme.Colors.divider)

            // Items list
            if filteredItems.isEmpty {
                emptyState
            } else {
                itemsList
            }

            Divider()
                .background(Theme.Colors.divider)

            // Footer
            footer
        }
        .frame(width: Theme.Dimensions.menuBarPopoverWidth)
        .frame(maxHeight: Theme.Dimensions.menuBarPopoverMaxHeight)
        .background(Theme.Colors.panelBackground)
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            pasteSelectedItem()
            return .handled
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.textSecondary)
                .font(.system(size: 12))

            TextField("Search clips...", text: $searchText, prompt: Text("Search clips...").foregroundColor(Theme.Colors.textSecondary))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.textSecondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.Colors.searchBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Items List

    private var itemsList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 2) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipRowView(
                            item: item,
                            isSelected: index == selectedIndex,
                            shortcutNumber: index < 9 ? index + 1 : nil,
                            onSelect: {
                                selectedIndex = index
                            },
                            onPaste: {
                                onPaste?(item)
                            },
                            onPastePlainText: {
                                onPastePlainText?(item)
                            },
                            onCopy: {
                                onCopy?(item)
                            },
                            onPin: {
                                onPin?(item)
                            },
                            onDelete: {
                                onDelete?(item)
                            }
                        )
                        .id(item.id)
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: selectedIndex) { _, newIndex in
                if newIndex < filteredItems.count {
                    withAnimation {
                        proxy.scrollTo(filteredItems[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))

            Text(searchText.isEmpty ? "No clips yet" : "No matches found")
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button {
                onShowPanel?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.expand.vertical")
                        .font(.system(size: 11))
                    Text("Show Panel")
                        .font(.system(size: 11))
                }
                .foregroundColor(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Open full clipboard panel (⇧⌘V)")

            Spacer()

            // Keyboard shortcut hint
            Text("⇧⌘V")
                .font(Theme.Typography.keyboardShortcut)
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func moveSelection(by delta: Int) {
        let newIndex = selectedIndex + delta
        if newIndex >= 0 && newIndex < filteredItems.count {
            selectedIndex = newIndex
        }
    }

    private func pasteSelectedItem() {
        guard selectedIndex < filteredItems.count else { return }
        onPaste?(filteredItems[selectedIndex])
    }
}

/// Row view for menu bar popover
struct ClipRowView: View {
    let item: ClipItem
    let isSelected: Bool
    let shortcutNumber: Int?
    var onSelect: (() -> Void)?
    var onPaste: (() -> Void)?
    var onPastePlainText: (() -> Void)?
    var onCopy: (() -> Void)?
    var onPin: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // App icon
            if let icon = item.sourceAppIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "app")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(width: 20, height: 20)
            }

            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    // Type badge
                    Text(item.contentType.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.Colors.badge(for: item.contentType))

                    Text("•")
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))

                    Text(item.relativeTimeString)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            // Pin indicator
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.pinned)
            }

            // Shortcut number
            if let number = shortcutNumber {
                Text("⌘\(number)")
                    .font(Theme.Typography.keyboardShortcut)
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            (isSelected || isHovered) ? Theme.Colors.cardHover : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelect?()
        }
        .onTapGesture(count: 2) {
            onPaste?()
        }
        .contextMenu {
            Button("Paste") { onPaste?() }
            Button("Paste as Plain Text") { onPastePlainText?() }
            Divider()
            Button("Copy to Clipboard") { onCopy?() }
            Divider()
            Button(item.isPinned ? "Unpin" : "Pin") { onPin?() }
            Divider()
            Button("Delete", role: .destructive) { onDelete?() }
        }
        .help(tooltipText)
    }

    private var tooltipText: String {
        var tooltip = item.contentPreview.prefix(60)
        if item.contentPreview.count > 60 {
            tooltip += "..."
        }
        if let number = shortcutNumber {
            tooltip += "\n⌘\(number) to paste"
        }
        tooltip += "\nDouble-click to paste"
        return String(tooltip)
    }
}

// MARK: - Previews

#Preview("Menu Bar Popover") {
    MenuBarPopoverView(
        onPaste: { item in
            print("Paste: \(item.contentPreview)")
        },
        onShowPanel: {
            print("Show panel")
        }
    )
}

#Preview("Menu Bar Popover - Empty") {
    MenuBarPopoverView(
        onPaste: { _ in },
        onShowPanel: {}
    )
}

#Preview("Clip Row") {
    VStack(spacing: 2) {
        ForEach(Array(ClipItem.sampleItems.prefix(5).enumerated()), id: \.element.id) { index, item in
            ClipRowView(
                item: item,
                isSelected: index == 0,
                shortcutNumber: index + 1,
                onSelect: {},
                onPaste: {}
            )
        }
    }
    .padding()
    .background(Theme.Colors.panelBackground)
}
