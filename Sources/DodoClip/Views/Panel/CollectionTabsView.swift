import SwiftUI

/// Tab representing a collection or "All" filter
struct CollectionTab: View {
    let title: String
    let icon: String?
    let color: Color?
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    private var backgroundColor: Color {
        if isSelected {
            return Theme.Colors.accent
        } else if isHovered {
            return Theme.Colors.cardHover
        } else {
            return Color.clear
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : (color ?? Theme.Colors.textSecondary))
                }

                Text(title)
                    .font(Theme.Typography.filterChip)
                    .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(height: Theme.Dimensions.collectionTabHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isSelected ? Color.clear : (isHovered ? Theme.Colors.textSecondary.opacity(0.3) : Theme.Colors.divider),
                        lineWidth: 1
                    )
            )
            .animation(Theme.Animation.cardHover, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help("View \(title) clips")
    }
}

/// Row of collection tabs - centered
struct CollectionTabsView: View {
    @Binding var selectedCollectionID: UUID?
    let collections: [Collection]
    var onCreateCollection: (() -> Void)?

    var body: some View {
        HStack {
            Spacer()

            HStack(spacing: 8) {
                // "All" tab
                CollectionTab(
                    title: L10n.Section.all,
                    icon: "tray.full",
                    color: nil,
                    isSelected: selectedCollectionID == nil,
                    onTap: {
                        selectedCollectionID = nil
                    }
                )

                // Collection tabs
                ForEach(collections, id: \.id) { collection in
                    CollectionTab(
                        title: collection.name,
                        icon: collection.icon,
                        color: Color(hex: collection.colorHex),
                        isSelected: selectedCollectionID == collection.id,
                        onTap: {
                            selectedCollectionID = collection.id
                        }
                    )
                }

                // Add collection button
                if let onCreate = onCreateCollection {
                    Button(action: onCreate) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .frame(width: Theme.Dimensions.collectionTabHeight, height: Theme.Dimensions.collectionTabHeight)
                            .background(Theme.Colors.filterChipBackground.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Dimensions.panelPadding)
    }
}

// MARK: - Previews

#Preview("Collection Tabs") {
    CollectionTabsView(
        selectedCollectionID: .constant(nil),
        collections: Collection.defaultCollections,
        onCreateCollection: {}
    )
    .padding(.vertical)
    .background(Theme.Colors.panelBackground)
}
