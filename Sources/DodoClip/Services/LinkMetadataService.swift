import Foundation
import AppKit

/// Service for fetching link metadata (og:image, favicon, title)
@MainActor
final class LinkMetadataService {
    static let shared = LinkMetadataService()

    private let session: URLSession
    private var cache: [String: LinkMetadata] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        session = URLSession(configuration: config)
    }

    /// Fetch metadata for a URL
    func fetchMetadata(for urlString: String) async -> LinkMetadata? {
        // Check cache first
        if let cached = cache[urlString] {
            return cached
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            // Fetch the HTML
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) else {
                return nil
            }

            // Parse metadata from HTML
            let ogImage = extractMetaContent(from: html, property: "og:image")
            let ogTitle = extractMetaContent(from: html, property: "og:title")
            let twitterImage = extractMetaContent(from: html, name: "twitter:image")

            // Get favicon URL
            let faviconURL = extractFaviconURL(from: html, baseURL: url) ?? defaultFaviconURL(for: url)

            // Fetch images
            let ogImageData = await fetchImage(from: ogImage ?? twitterImage)
            let faviconData = await fetchImage(from: faviconURL)

            let metadata = LinkMetadata(
                ogTitle: ogTitle,
                ogImageData: ogImageData,
                faviconData: faviconData
            )

            // Cache it
            cache[urlString] = metadata

            return metadata
        } catch {
            print("Failed to fetch metadata for \(urlString): \(error)")
            return nil
        }
    }

    // MARK: - HTML Parsing

    private func extractMetaContent(from html: String, property: String) -> String? {
        // Match <meta property="og:image" content="...">
        let pattern = #"<meta[^>]+property=["']\#(property)["'][^>]+content=["']([^"']+)["']"#
        let altPattern = #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']\#(property)["']"#

        if let match = html.range(of: pattern, options: .regularExpression) {
            let matchStr = String(html[match])
            return extractContentValue(from: matchStr)
        }

        if let match = html.range(of: altPattern, options: .regularExpression) {
            let matchStr = String(html[match])
            return extractContentValue(from: matchStr)
        }

        return nil
    }

    private func extractMetaContent(from html: String, name: String) -> String? {
        // Match <meta name="twitter:image" content="...">
        let pattern = #"<meta[^>]+name=["']\#(name)["'][^>]+content=["']([^"']+)["']"#
        let altPattern = #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']\#(name)["']"#

        if let match = html.range(of: pattern, options: .regularExpression) {
            let matchStr = String(html[match])
            return extractContentValue(from: matchStr)
        }

        if let match = html.range(of: altPattern, options: .regularExpression) {
            let matchStr = String(html[match])
            return extractContentValue(from: matchStr)
        }

        return nil
    }

    private func extractContentValue(from metaTag: String) -> String? {
        let pattern = #"content=["']([^"']+)["']"#
        guard let range = metaTag.range(of: pattern, options: .regularExpression) else { return nil }
        let match = String(metaTag[range])
        // Remove content=" and trailing "
        return match
            .replacingOccurrences(of: "content=\"", with: "")
            .replacingOccurrences(of: "content='", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private func extractFaviconURL(from html: String, baseURL: URL) -> String? {
        // Look for <link rel="icon" href="..."> or <link rel="shortcut icon" href="...">
        let patterns = [
            #"<link[^>]+rel=["'](?:shortcut )?icon["'][^>]+href=["']([^"']+)["']"#,
            #"<link[^>]+href=["']([^"']+)["'][^>]+rel=["'](?:shortcut )?icon["']"#,
            #"<link[^>]+rel=["']apple-touch-icon["'][^>]+href=["']([^"']+)["']"#
        ]

        for pattern in patterns {
            if let range = html.range(of: pattern, options: .regularExpression) {
                let match = String(html[range])
                if let href = extractHrefValue(from: match) {
                    return resolveURL(href, relativeTo: baseURL)
                }
            }
        }

        return nil
    }

    private func extractHrefValue(from linkTag: String) -> String? {
        let pattern = #"href=["']([^"']+)["']"#
        guard let range = linkTag.range(of: pattern, options: .regularExpression) else { return nil }
        let match = String(linkTag[range])
        return match
            .replacingOccurrences(of: "href=\"", with: "")
            .replacingOccurrences(of: "href='", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private func resolveURL(_ href: String, relativeTo baseURL: URL) -> String {
        if href.hasPrefix("http://") || href.hasPrefix("https://") {
            return href
        } else if href.hasPrefix("//") {
            return "https:" + href
        } else if href.hasPrefix("/") {
            return "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")\(href)"
        } else {
            return baseURL.deletingLastPathComponent().appendingPathComponent(href).absoluteString
        }
    }

    private func defaultFaviconURL(for url: URL) -> String {
        "\(url.scheme ?? "https")://\(url.host ?? "")/favicon.ico"
    }

    // MARK: - Image Fetching

    private func fetchImage(from urlString: String?) async -> Data? {
        guard let urlString = urlString, let url = URL(string: urlString) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            // Verify it's actually an image
            if NSImage(data: data) != nil {
                return data
            }

            return nil
        } catch {
            return nil
        }
    }
}

/// Metadata fetched for a link
struct LinkMetadata {
    let ogTitle: String?
    let ogImageData: Data?
    let faviconData: Data?

    var hasContent: Bool {
        ogTitle != nil || ogImageData != nil || faviconData != nil
    }
}
