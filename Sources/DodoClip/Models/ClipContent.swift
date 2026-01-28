import Foundation
import AppKit

/// Type of content stored in a clip
enum ClipContentType: String, Codable, CaseIterable {
    case text
    case richText
    case image
    case file
    case link
    case color

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .richText: return "Rich Text"
        case .image: return "Image"
        case .file: return "File"
        case .link: return "Link"
        case .color: return "Color"
        }
    }

    var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .richText: return "doc.richtext"
        case .image: return "photo"
        case .file: return "doc"
        case .link: return "link"
        case .color: return "paintpalette"
        }
    }
}

/// Content structure for a clip item
struct ClipContent: Codable, Equatable {
    let type: ClipContentType
    let data: Data
    var editedData: Data?
    var metadata: [String: String]?
    var linkImageData: Data?  // og:image data for links
    var faviconData: Data?    // favicon data for links

    /// The active data (edited if available, otherwise original)
    var activeData: Data {
        editedData ?? data
    }

    /// Get text content if this is a text clip
    var textValue: String? {
        guard type == .text || type == .richText || type == .link || type == .color else { return nil }
        return String(data: activeData, encoding: .utf8)
    }

    /// Get image if this is an image clip
    var imageValue: NSImage? {
        guard type == .image else { return nil }
        return NSImage(data: activeData)
    }

    /// Get URL if this is a link clip
    var urlValue: URL? {
        guard type == .link, let urlString = textValue else { return nil }
        return URL(string: urlString)
    }

    /// Get file URL if this is a file clip
    var fileURL: URL? {
        guard type == .file, let path = metadata?["path"] else { return nil }
        return URL(fileURLWithPath: path)
    }

    /// Get color if this is a color clip
    var colorValue: NSColor? {
        guard type == .color, let hexString = textValue else { return nil }
        return NSColor(hex: hexString)
    }

    /// Get og:image for link clips
    var linkImage: NSImage? {
        guard type == .link, let data = linkImageData else { return nil }
        return NSImage(data: data)
    }

    /// Get favicon for link clips
    var favicon: NSImage? {
        guard type == .link, let data = faviconData else { return nil }
        return NSImage(data: data)
    }

    /// Get og:title for link clips
    var linkTitle: String? {
        guard type == .link else { return nil }
        return metadata?["ogTitle"] ?? metadata?["title"]
    }

    // MARK: - Convenience Initializers

    static func text(_ string: String) -> ClipContent {
        ClipContent(
            type: .text,
            data: string.data(using: .utf8) ?? Data(),
            editedData: nil,
            metadata: nil,
            linkImageData: nil,
            faviconData: nil
        )
    }

    static func image(_ image: NSImage) -> ClipContent? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let dimensions = "\(Int(image.size.width))×\(Int(image.size.height))"
        return ClipContent(
            type: .image,
            data: pngData,
            editedData: nil,
            metadata: ["dimensions": dimensions],
            linkImageData: nil,
            faviconData: nil
        )
    }

    static func link(_ urlString: String, title: String? = nil, ogTitle: String? = nil, ogImageData: Data? = nil, faviconData: Data? = nil) -> ClipContent {
        var metadata: [String: String] = [:]
        if let title = title {
            metadata["title"] = title
        }
        if let ogTitle = ogTitle {
            metadata["ogTitle"] = ogTitle
        }
        return ClipContent(
            type: .link,
            data: urlString.data(using: .utf8) ?? Data(),
            editedData: nil,
            metadata: metadata.isEmpty ? nil : metadata,
            linkImageData: ogImageData,
            faviconData: faviconData
        )
    }

    static func file(path: String, name: String) -> ClipContent {
        ClipContent(
            type: .file,
            data: path.data(using: .utf8) ?? Data(),
            editedData: nil,
            metadata: ["path": path, "name": name],
            linkImageData: nil,
            faviconData: nil
        )
    }

    static func color(hex: String) -> ClipContent {
        ClipContent(
            type: .color,
            data: hex.data(using: .utf8) ?? Data(),
            editedData: nil,
            metadata: nil,
            linkImageData: nil,
            faviconData: nil
        )
    }

    /// Update link metadata after fetching
    mutating func updateLinkMetadata(ogTitle: String?, ogImageData: Data?, faviconData: Data?) {
        guard type == .link else { return }

        if let ogTitle = ogTitle {
            if metadata == nil {
                metadata = [:]
            }
            metadata?["ogTitle"] = ogTitle
        }

        if let ogImageData = ogImageData {
            self.linkImageData = ogImageData
        }

        if let faviconData = faviconData {
            self.faviconData = faviconData
        }
    }
}

// MARK: - NSColor Hex Extension

extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: CGFloat
        switch hexSanitized.count {
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    var hexString: String {
        guard let rgbColor = usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Returns the relative luminance of the color (0 = darkest, 1 = lightest)
    var luminance: CGFloat {
        guard let rgbColor = usingColorSpace(.sRGB) else { return 0 }
        // Using the relative luminance formula: 0.2126*R + 0.7152*G + 0.0722*B
        return 0.2126 * rgbColor.redComponent + 0.7152 * rgbColor.greenComponent + 0.0722 * rgbColor.blueComponent
    }

    /// Returns true if the color is considered light (text should be dark)
    var isLightColor: Bool {
        luminance > 0.5
    }
}
