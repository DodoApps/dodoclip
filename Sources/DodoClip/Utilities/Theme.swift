import SwiftUI

/// DodoClip theme constants - always dark mode
enum Theme {
    // MARK: - Colors

    enum Colors {
        // Panel
        static let panelBackground = Color(hex: "1E1E1E")
        static let cardBackground = Color(hex: "2D2D2D")
        static let cardHover = Color(hex: "3D3D3D")
        static let cardSelected = Color(hex: "4A4A4A")

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "8E8E93")

        // Accent
        static let accent = Color(hex: "007AFF")

        // UI Elements
        static let searchBackground = Color(hex: "3A3A3C")
        static let filterChipBackground = Color(hex: "48484A")
        static let divider = Color(hex: "38383A")

        // Type Badges
        static let badgeText = Color(hex: "007AFF")
        static let badgeImage = Color(hex: "34C759")
        static let badgeLink = Color(hex: "AF52DE")
        static let badgeFile = Color(hex: "FF9500")
        static let badgeColor = Color(hex: "FF2D55")
        static let badgeRichText = Color(hex: "5AC8FA")

        // Status
        static let pinned = Color(hex: "FF9500")
        static let favorite = Color(hex: "FF2D55")

        static func badge(for type: ClipContentType) -> Color {
            switch type {
            case .text: return badgeText
            case .richText: return badgeRichText
            case .image: return badgeImage
            case .link: return badgeLink
            case .file: return badgeFile
            case .color: return badgeColor
            }
        }
    }

    // MARK: - Dimensions

    enum Dimensions {
        // Panel - 50% taller (280 * 1.5 = 420)
        static let panelHeight: CGFloat = 420
        static let panelHeightCompact: CGFloat = 270
        static let panelCornerRadius: CGFloat = 16
        static let panelPadding: CGFloat = 16

        // Card - proportionally taller
        static let cardWidth: CGFloat = 220
        static let cardWidthCompact: CGFloat = 165
        static let cardHeight: CGFloat = 280
        static let cardHeightCompact: CGFloat = 180
        static let cardCornerRadius: CGFloat = 12
        static let cardSpacing: CGFloat = 12
        static let cardPadding: CGFloat = 12

        // Card sections
        static let cardHeaderHeight: CGFloat = 40
        static let cardFooterHeight: CGFloat = 28
        static let appIconSize: CGFloat = 20

        // Search & Filters
        static let searchBarHeight: CGFloat = 36
        static let filterChipHeight: CGFloat = 28
        static let collectionTabHeight: CGFloat = 32

        // Menu Bar
        static let menuBarPopoverWidth: CGFloat = 320
        static let menuBarPopoverMaxHeight: CGFloat = 400
    }

    // MARK: - Typography

    enum Typography {
        static let cardTitle = Font.system(size: 13)
        static let cardMeta = Font.system(size: 11)
        static let typeBadge = Font.system(size: 10, weight: .medium)
        static let characterCount = Font.system(size: 10)
        static let searchInput = Font.system(size: 14)
        static let filterChip = Font.system(size: 12, weight: .medium)
        static let sectionHeader = Font.system(size: 12, weight: .semibold)
        static let keyboardShortcut = Font.system(size: 11, weight: .medium, design: .monospaced)
    }

    // MARK: - Animation

    enum Animation {
        static let panelShow = SwiftUI.Animation.easeOut(duration: 0.25)
        static let panelHide = SwiftUI.Animation.easeIn(duration: 0.2)
        static let cardHover = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let cardClick = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let selection = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let filterChip = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View Modifiers

extension View {
    func cardStyle(isSelected: Bool = false, isHovered: Bool = false, hasCustomBackground: Bool = false) -> some View {
        self
            .background(
                hasCustomBackground ? Color.clear :
                isSelected ? Theme.Colors.cardSelected :
                isHovered ? Theme.Colors.cardHover :
                Theme.Colors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cardCornerRadius)
                    .strokeBorder(
                        isSelected ? Theme.Colors.accent :
                        hasCustomBackground ? Color.white.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
    }

    func panelBackground() -> some View {
        self.background(Theme.Colors.panelBackground)
    }
}
