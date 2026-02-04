import SwiftUI

/// Tab representing a collection or "All" filter
struct CollectionTab: View {
    let title: String
    let icon: String?
    let color: Color?
    let isSelected: Bool
    let isCustom: Bool
    let onTap: () -> Void
    var onDelete: (() -> Void)?
    var onRename: (() -> Void)?
  var onDropItem: ((UUID) -> Void)?

    @State private var isHovered = false
  @State private var isDropTarget = false
    
    private var backgroundColor: Color {
        if isSelected {
            return Theme.Colors.accent
    } else if isDropTarget {
      return Theme.Colors.accent.opacity(0.3)
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
        .contextMenu {
            if isCustom {
                Button("Rename") {
                    onRename?()
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    onDelete?()
                }
            }
        }
    .onDrop(of: [.text], isTargeted: $isDropTarget) { providers in
      // Only allow drops on custom collections
      guard isCustom, let onDrop = onDropItem else { return false }

      // Extract the dragged item ID
      guard let provider = providers.first else { return false }

      provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, error in
        if let data = item as? Data,
          let uuidString = String(data: data, encoding: .utf8),
          let itemID = UUID(uuidString: uuidString)
        {
          DispatchQueue.main.async {
            onDrop(itemID)
          }
        }
      }

      return true
    }
    }
}

/// Row of collection tabs - centered
struct CollectionTabsView: View {
    @Binding var selectedCollectionID: UUID?
    let collections: [Collection]
    var onCreateCollection: (() -> Void)?
    var onDeleteCollection: ((Collection) -> Void)?
    var onRenameCollection: ((Collection) -> Void)?
  var onAddItemToCollection: ((UUID, Collection) -> Void)?
    
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
                    isCustom: false,
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
                        isCustom: !collection.isSmartCollection,
                        onTap: {
                            selectedCollectionID = collection.id
                        },
                        onDelete: !collection.isSmartCollection
                        ? {
                            onDeleteCollection?(collection)
                        } : nil,
                        onRename: !collection.isSmartCollection
                        ? {
                            onRenameCollection?(collection)
              } : nil,
            onDropItem: !collection.isSmartCollection
              ? { itemID in
                onAddItemToCollection?(itemID, collection)
                        } : nil
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
