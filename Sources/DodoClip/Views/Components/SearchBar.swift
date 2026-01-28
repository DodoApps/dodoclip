import SwiftUI

/// Search bar component with filter chips
struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearchFocused: Bool
    var onSearch: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.textSecondary)
                    .font(.system(size: 14))

                TextField("Search clips...", text: $searchText, prompt: Text("Search clips...").foregroundColor(Theme.Colors.textPrimary.opacity(0.5)))
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.searchInput)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .focused($isFocused)
                    .onChange(of: searchText) { _, newValue in
                        onSearch(newValue)
                    }
                    .onSubmit {
                        onSearch(searchText)
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        onSearch("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.textSecondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(height: Theme.Dimensions.searchBarHeight)
            .background(Theme.Colors.searchBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Keyboard shortcut hint
            Text("⌘F")
                .font(Theme.Typography.keyboardShortcut)
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Theme.Colors.searchBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .onChange(of: isSearchFocused) { _, newValue in
            isFocused = newValue
        }
        .onChange(of: isFocused) { _, newValue in
            isSearchFocused = newValue
        }
    }
}

/// Filter chip for type/date filters
struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let onTap: () -> Void
    var onRemove: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }

                Text(title)
                    .font(Theme.Typography.filterChip)

                if isSelected, onRemove != nil {
                    Button {
                        onRemove?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(height: Theme.Dimensions.filterChipHeight)
            .background(isSelected ? Theme.Colors.accent : Theme.Colors.filterChipBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(isSelected ? "Remove \(title) filter" : "Filter by \(title)")
    }
}

/// Row of filter chips
struct FilterChipsRow: View {
    @Binding var selectedTypes: Set<ClipContentType>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ClipContentType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        icon: type.iconName,
                        isSelected: selectedTypes.contains(type),
                        onTap: {
                            if selectedTypes.contains(type) {
                                selectedTypes.remove(type)
                            } else {
                                selectedTypes.insert(type)
                            }
                        },
                        onRemove: selectedTypes.contains(type) ? {
                            selectedTypes.remove(type)
                        } : nil
                    )
                }
            }
            .padding(.horizontal, Theme.Dimensions.panelPadding)
        }
    }
}

// MARK: - Previews

#Preview("Search Bar") {
    VStack {
        SearchBar(
            searchText: .constant(""),
            isSearchFocused: .constant(false),
            onSearch: { _ in }
        )
        .padding()

        SearchBar(
            searchText: .constant("hello world"),
            isSearchFocused: .constant(true),
            onSearch: { _ in }
        )
        .padding()
    }
    .background(Theme.Colors.panelBackground)
}

#Preview("Filter Chips") {
    FilterChipsRow(selectedTypes: .constant([.text, .image]))
        .padding()
        .background(Theme.Colors.panelBackground)
}
