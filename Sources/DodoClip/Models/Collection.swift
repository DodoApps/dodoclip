import Foundation
import SwiftData

@Model
final class Collection {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int

    /// If set, this is a smart collection that filters by content type
    var smartFilterTypeRaw: String?

    var items: [ClipItem]?

    var itemCount: Int {
        items?.count ?? 0
    }

    /// The content type this smart collection filters by (if any)
    var smartFilterType: ClipContentType? {
        get {
            guard let raw = smartFilterTypeRaw else { return nil }
            return ClipContentType(rawValue: raw)
        }
        set {
            smartFilterTypeRaw = newValue?.rawValue
        }
    }

    /// Whether this is a smart collection (auto-filters by type)
    var isSmartCollection: Bool {
        smartFilterTypeRaw != nil
    }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0,
        smartFilterType: ClipContentType? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.smartFilterTypeRaw = smartFilterType?.rawValue
        self.items = []
    }
}

// MARK: - Default Collections

extension Collection {
    static var defaultCollections: [Collection] {
        [
            Collection(name: L10n.Section.links, icon: "link", colorHex: "#AF52DE", sortOrder: 0, smartFilterType: .link),
            Collection(name: L10n.Section.images, icon: "photo", colorHex: "#FF9500", sortOrder: 1, smartFilterType: .image),
            Collection(name: L10n.Section.colors, icon: "paintpalette", colorHex: "#34C759", sortOrder: 2, smartFilterType: .color)
        ]
    }
}
