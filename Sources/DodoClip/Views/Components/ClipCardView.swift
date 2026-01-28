import SwiftUI

/// Individual clip card for the bottom panel
struct ClipCardView: View {
    let item: ClipItem
    let isSelected: Bool
    let isCompact: Bool
    let index: Int?
    let onSelect: () -> Void
    let onPaste: () -> Void
    var onPastePlainText: (() -> Void)?
    var onPin: (() -> Void)?
    var onDelete: (() -> Void)?
    var onOpen: (() -> Void)?

    @State private var isHovered: Bool = false

    private var cardWidth: CGFloat {
        isCompact ? Theme.Dimensions.cardWidthCompact : Theme.Dimensions.cardWidth
    }

    private var cardHeight: CGFloat {
        isCompact ? Theme.Dimensions.cardHeightCompact : Theme.Dimensions.cardHeight
    }

    @ViewBuilder
    private var cardBackground: some View {
        if item.contentType == .color,
           let content = item.content,
           let color = content.colorValue {
            Color(nsColor: color)
        } else {
            Color.clear
        }
    }

    /// Whether this is a color card with a light background (needs dark text)
    private var isLightColorCard: Bool {
        guard item.contentType == .color,
              let content = item.content,
              let color = content.colorValue else { return false }
        return color.isLightColor
    }

    /// Text color for color cards - dark for light backgrounds, light for dark backgrounds
    private var colorCardTextPrimary: Color {
        isLightColorCard ? .black : .white
    }

    private var colorCardTextSecondary: Color {
        isLightColorCard ? .black.opacity(0.6) : .white.opacity(0.7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            cardHeader

            // Content
            cardContent

            // Footer
            if !isCompact {
                cardFooter
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(cardBackground)
        .cardStyle(isSelected: isSelected, isHovered: isHovered, hasCustomBackground: item.contentType == .color)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(Theme.Animation.cardHover, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    onPaste()
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onSelect()
                }
        )
        .contextMenu {
            contextMenuContent
        }
        .help(cardTooltip)
    }

    private var cardTooltip: String {
        var tooltip = item.contentPreview.prefix(50)
        if item.contentPreview.count > 50 {
            tooltip += "..."
        }
        if let index = index, index < 9 {
            tooltip += "\n⌘\(index + 1) to paste"
        }
        tooltip += "\nDouble-click to paste"
        return String(tooltip)
    }

    // MARK: - Header

    private var cardHeader: some View {
        HStack(spacing: 8) {
            // App icon
            if let icon = item.sourceAppIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: Theme.Dimensions.appIconSize, height: Theme.Dimensions.appIconSize)
            } else {
                Image(systemName: "app")
                    .font(.system(size: 14))
                    .foregroundColor(item.contentType == .color ? colorCardTextSecondary : Theme.Colors.textSecondary)
                    .frame(width: Theme.Dimensions.appIconSize, height: Theme.Dimensions.appIconSize)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.sourceAppName ?? "Unknown")
                    .font(Theme.Typography.cardMeta)
                    .foregroundColor(item.contentType == .color ? colorCardTextSecondary : Theme.Colors.textSecondary)
                    .lineLimit(1)

                Text(item.relativeTimeString)
                    .font(Theme.Typography.cardMeta)
                    .foregroundColor(item.contentType == .color ? colorCardTextSecondary.opacity(0.7) : Theme.Colors.textSecondary.opacity(0.7))
            }

            Spacer()

            // Keyboard shortcut indicator
            if let index = index, index < 9 {
                Text("⌘\(index + 1)")
                    .font(Theme.Typography.keyboardShortcut)
                    .foregroundColor(item.contentType == .color ? colorCardTextSecondary.opacity(0.7) : Theme.Colors.textSecondary.opacity(0.5))
                    .padding(.trailing, 4)
            }

            // Type badge
            typeBadge
        }
        .padding(.horizontal, Theme.Dimensions.cardPadding)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var typeBadge: some View {
        Group {
            if item.contentType == .color {
                // For color cards, use a pill with contrasting background
                Text(item.contentType.displayName)
                    .font(Theme.Typography.typeBadge)
                    .foregroundColor(isLightColorCard ? .white : .black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isLightColorCard ? Color.black.opacity(0.5) : Color.white.opacity(0.5))
                    .clipShape(Capsule())
            } else {
                Text(item.contentType.displayName)
                    .font(Theme.Typography.typeBadge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.badge(for: item.contentType))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Content

    private var cardContent: some View {
        Group {
            switch item.contentType {
            case .text, .richText:
                textContent
            case .image:
                imageContent
            case .link:
                linkContent
            case .file:
                fileContent
            case .color:
                colorContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.Dimensions.cardPadding)
        .padding(.vertical, 4)
    }

    private var textContent: some View {
        Text(item.plainText ?? "")
            .font(Theme.Typography.cardTitle)
            .foregroundColor(Theme.Colors.textPrimary)
            .lineLimit(isCompact ? 3 : 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var imageContent: some View {
        Group {
            if let content = item.content, let image = content.imageValue {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.textSecondary)
                    if let dims = item.imageDimensions {
                        Text(dims)
                            .font(Theme.Typography.cardMeta)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var linkContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Favicon or link icon
                if let content = item.content, let favicon = content.favicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    Image(systemName: "link")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.badgeLink)
                }

                Spacer()

                // Open indicator
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            }

            // OG Image preview
            if let content = item.content, let ogImage = content.linkImage {
                Image(nsImage: ogImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: isCompact ? 60 : 100)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let title = item.linkTitle, !title.isEmpty {
                Text(title)
                    .font(Theme.Typography.cardTitle)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
            }

            Text(item.plainText ?? "")
                .font(Theme.Typography.cardMeta)
                .foregroundColor(Color(hex: "5AC8FA")) // Light blue, readable on dark background
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var fileContent: some View {
        VStack(spacing: 8) {
            Image(systemName: fileIcon)
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.badgeFile)

            Text(item.fileName ?? "File")
                .font(Theme.Typography.cardTitle)
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileIcon: String {
        guard let fileName = item.fileName else { return "doc" }
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.text"
        case "png", "jpg", "jpeg", "gif", "webp": return "photo"
        case "mp4", "mov", "avi": return "film"
        case "mp3", "wav", "aac": return "music.note"
        case "zip", "tar", "gz": return "doc.zipper"
        case "swift", "js", "py", "ts": return "chevron.left.forwardslash.chevron.right"
        default: return "doc"
        }
    }

    private var colorContent: some View {
        VStack {
            Spacer()

            // Hex code with contrasting background for readability
            Text(item.plainText ?? "")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(isLightColorCard ? .white : .black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isLightColorCard ? Color.black.opacity(0.4) : Color.white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var cardFooter: some View {
        HStack {
            // Pin indicator
            if item.isPinned {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                    Text("Pinned")
                        .font(Theme.Typography.characterCount)
                }
                .foregroundColor(item.contentType == .color ? colorCardTextPrimary : Theme.Colors.pinned)
            }

            if item.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(item.contentType == .color ? colorCardTextPrimary : Theme.Colors.favorite)
            }

            Spacer()

            // Character count or dimensions
            metadataText
        }
        .padding(.horizontal, Theme.Dimensions.cardPadding)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    private var metadataText: some View {
        Group {
            switch item.contentType {
            case .text, .richText, .link:
                if let count = item.characterCount {
                    Text("\(count) chars")
                }
            case .image:
                if let dims = item.imageDimensions {
                    Text(dims)
                }
            case .file:
                Text("File")
            case .color:
                EmptyView()
            }
        }
        .font(Theme.Typography.characterCount)
        .foregroundColor(Theme.Colors.textSecondary)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            onPaste()
        } label: {
            Label("Paste", systemImage: "doc.on.clipboard")
        }
        .keyboardShortcut(.return, modifiers: [])

        Button {
            onPastePlainText?()
        } label: {
            Label("Paste as plain text", systemImage: "text.alignleft")
        }
        .keyboardShortcut(.return, modifiers: .shift)

        Divider()

        if item.contentType == .link || item.contentType == .file {
            Button {
                onOpen?()
            } label: {
                Label("Open", systemImage: "arrow.up.right.square")
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        Divider()

        Button {
            onPin?()
        } label: {
            Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
        }
        .keyboardShortcut("p", modifiers: .command)

        Divider()

        Button(role: .destructive) {
            onDelete?()
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .keyboardShortcut(.delete, modifiers: [])
    }
}

// MARK: - Convenience initializer

extension ClipCardView {
    init(
        item: ClipItem,
        isSelected: Bool,
        isCompact: Bool,
        onSelect: @escaping () -> Void,
        onPaste: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.isCompact = isCompact
        self.index = nil
        self.onSelect = onSelect
        self.onPaste = onPaste
        self.onPastePlainText = nil
        self.onPin = nil
        self.onDelete = nil
        self.onOpen = nil
    }
}

// MARK: - Preview

#Preview("Clip Cards") {
    HStack(spacing: Theme.Dimensions.cardSpacing) {
        ForEach(Array(ClipItem.sampleItems.prefix(4).enumerated()), id: \.element.id) { index, item in
            ClipCardView(
                item: item,
                isSelected: index == 0,
                isCompact: false,
                index: index,
                onSelect: {},
                onPaste: {}
            )
        }
    }
    .padding()
    .background(Theme.Colors.panelBackground)
}
