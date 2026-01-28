import Foundation
import SwiftData
import AppKit

@Model
final class ClipItem {
    @Attribute(.unique) var id: UUID

    // Content stored as encoded Data for SwiftData compatibility
    var contentData: Data
    var contentTypeRaw: String

    // Searchable text
    var plainText: String?
    var ocrText: String?

    // User customization
    var title: String?

    // Source information
    var sourceAppBundleID: String?
    var sourceAppName: String?

    // Organization
    var isPinned: Bool
    var isFavorite: Bool
    var isDeleted: Bool

    // Timestamps
    var createdAt: Date
    var lastUsedAt: Date
    var useCount: Int

    // Metadata
    var characterCount: Int?
    var imageDimensions: String?
    var linkTitle: String?
    var fileName: String?

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Collection.items)
    var collections: [Collection]?

    // MARK: - Computed Properties

    var contentType: ClipContentType {
        ClipContentType(rawValue: contentTypeRaw) ?? .text
    }

    var content: ClipContent? {
        get {
            try? JSONDecoder().decode(ClipContent.self, from: contentData)
        }
        set {
            if let newValue = newValue,
               let encoded = try? JSONEncoder().encode(newValue) {
                contentData = encoded
                contentTypeRaw = newValue.type.rawValue
            }
        }
    }

    /// Display title - user title or content preview
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return contentPreview
    }

    /// Preview text for the content
    var contentPreview: String {
        switch contentType {
        case .text, .richText:
            let text = plainText ?? ""
            let preview = text.prefix(100)
            return String(preview).trimmingCharacters(in: .whitespacesAndNewlines)
        case .image:
            if let dims = imageDimensions {
                return "Image \(dims)"
            }
            return "Image"
        case .file:
            return fileName ?? "File"
        case .link:
            return linkTitle ?? plainText ?? "Link"
        case .color:
            return plainText ?? "Color"
        }
    }

    /// Relative time string
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Source app icon
    var sourceAppIcon: NSImage? {
        guard let bundleID = sourceAppBundleID,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        content: ClipContent,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        isPinned: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.contentData = (try? JSONEncoder().encode(content)) ?? Data()
        self.contentTypeRaw = content.type.rawValue
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.isDeleted = false
        self.createdAt = Date()
        self.lastUsedAt = Date()
        self.useCount = 0
        self.collections = []

        // Set type-specific metadata
        switch content.type {
        case .text, .richText, .link:
            self.plainText = content.textValue
            self.characterCount = content.textValue?.count
        case .image:
            self.imageDimensions = content.metadata?["dimensions"]
        case .file:
            self.fileName = content.metadata?["name"]
        case .color:
            self.plainText = content.textValue
        }

        if content.type == .link {
            self.linkTitle = content.metadata?["title"]
        }
    }

    // MARK: - Actions

    func markUsed() {
        lastUsedAt = Date()
        useCount += 1
    }

    func togglePin() {
        isPinned.toggle()
    }

    func toggleFavorite() {
        isFavorite.toggle()
    }

    func softDelete() {
        isDeleted = true
    }

    func restore() {
        isDeleted = false
    }

    func rename(to newTitle: String) {
        title = newTitle.isEmpty ? nil : newTitle
    }

    func updateContent(_ newContent: ClipContent) {
        if var existingContent = content {
            existingContent.editedData = newContent.data
            content = existingContent
            plainText = newContent.textValue
            characterCount = newContent.textValue?.count
        }
    }

    /// Update link metadata after async fetch
    func updateLinkMetadata(ogTitle: String?, ogImageData: Data?, faviconData: Data?) {
        guard contentType == .link else { return }

        if var existingContent = content {
            existingContent.updateLinkMetadata(
                ogTitle: ogTitle,
                ogImageData: ogImageData,
                faviconData: faviconData
            )
            content = existingContent

            // Update the linkTitle if we got an ogTitle
            if let ogTitle = ogTitle, !ogTitle.isEmpty {
                linkTitle = ogTitle
            }
        }
    }
}

// MARK: - Sample Data for Previews

extension ClipItem {
    static var sampleItems: [ClipItem] {
        [
            // Text - Long paragraph
            ClipItem(
                content: .text("The quick brown fox jumps over the lazy dog. This pangram contains every letter of the alphabet and is commonly used for typography testing."),
                sourceAppBundleID: "com.apple.Safari",
                sourceAppName: "Safari"
            ),
            // Link - GitHub
            ClipItem(
                content: .link("https://github.com/anthropics/claude", title: "Claude on GitHub"),
                sourceAppBundleID: "com.apple.Safari",
                sourceAppName: "Safari"
            ),
            // Code - Swift function (pinned)
            ClipItem(
                content: .text("func greet(name: String) -> String {\n    return \"Hello, \\(name)!\"\n}"),
                sourceAppBundleID: "com.apple.dt.Xcode",
                sourceAppName: "Xcode",
                isPinned: true
            ),
            // Color - Blue
            ClipItem(
                content: .color(hex: "#007AFF"),
                sourceAppBundleID: "com.figma.Desktop",
                sourceAppName: "Figma"
            ),
            // File - PDF
            ClipItem(
                content: .file(path: "/Users/demo/Documents/report.pdf", name: "report.pdf"),
                sourceAppBundleID: "com.apple.finder",
                sourceAppName: "Finder"
            ),
            // Terminal command (favorite)
            ClipItem(
                content: .text("npm install @anthropic-ai/sdk"),
                sourceAppBundleID: "com.apple.Terminal",
                sourceAppName: "Terminal",
                isFavorite: true
            ),
            // Email address
            ClipItem(
                content: .text("contact@example.com"),
                sourceAppBundleID: "com.apple.mail",
                sourceAppName: "Mail"
            ),
            // JSON snippet
            ClipItem(
                content: .text("{\n  \"name\": \"DodoClip\",\n  \"version\": \"1.0.0\",\n  \"description\": \"Clipboard manager\"\n}"),
                sourceAppBundleID: "com.microsoft.VSCode",
                sourceAppName: "VS Code"
            ),
            // Link - Documentation
            ClipItem(
                content: .link("https://developer.apple.com/documentation/swiftui", title: "SwiftUI Documentation"),
                sourceAppBundleID: "com.apple.Safari",
                sourceAppName: "Safari"
            ),
            // Color - Green
            ClipItem(
                content: .color(hex: "#34C759"),
                sourceAppBundleID: "com.figma.Desktop",
                sourceAppName: "Figma"
            ),
            // SQL query
            ClipItem(
                content: .text("SELECT * FROM users WHERE created_at > '2024-01-01' ORDER BY name ASC LIMIT 100;"),
                sourceAppBundleID: "com.sequel-ace.sequel-ace",
                sourceAppName: "Sequel Ace",
                isPinned: true
            ),
            // Phone number
            ClipItem(
                content: .text("+1 (555) 123-4567"),
                sourceAppBundleID: "com.apple.MobileSMS",
                sourceAppName: "Messages"
            ),
            // Python code
            ClipItem(
                content: .text("def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)"),
                sourceAppBundleID: "com.microsoft.VSCode",
                sourceAppName: "VS Code"
            ),
            // URL - API endpoint
            ClipItem(
                content: .link("https://api.anthropic.com/v1/messages", title: "Anthropic API"),
                sourceAppBundleID: "com.postmanlabs.mac",
                sourceAppName: "Postman"
            ),
            // Color - Purple
            ClipItem(
                content: .color(hex: "#AF52DE"),
                sourceAppBundleID: "com.figma.Desktop",
                sourceAppName: "Figma"
            ),
            // File - Image
            ClipItem(
                content: .file(path: "/Users/demo/Pictures/screenshot.png", name: "screenshot.png"),
                sourceAppBundleID: "com.apple.finder",
                sourceAppName: "Finder"
            )
        ]
    }
}
