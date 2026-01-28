import AppKit
import Carbon

/// Service that handles pasting content to the frontmost application
@MainActor
final class PasteService {
    static let shared = PasteService()

    private init() {}

    // MARK: - Paste Actions

    /// Paste a clip item to the frontmost application
    func paste(_ item: ClipItem, asPlainText: Bool = false) {
        guard let content = item.content else { return }

        // Write content to pasteboard
        writeToPasteboard(content, asPlainText: asPlainText)

        // Mark item as used
        item.markUsed()

        // Simulate Cmd+V
        simulatePaste()
    }

    /// Paste multiple items concatenated (for text types)
    func pasteMultiple(_ items: [ClipItem], separator: String = "\n") {
        let textItems = items.compactMap { item -> String? in
            guard let content = item.content else { return nil }
            return content.textValue
        }

        guard !textItems.isEmpty else { return }

        let combinedText = textItems.joined(separator: separator)
        let combinedContent = ClipContent.text(combinedText)

        writeToPasteboard(combinedContent, asPlainText: true)

        items.forEach { $0.markUsed() }

        simulatePaste()
    }

    /// Copy item to clipboard without pasting
    func copyToClipboard(_ item: ClipItem, asPlainText: Bool = false) {
        guard let content = item.content else { return }
        writeToPasteboard(content, asPlainText: asPlainText)
        item.markUsed()
    }

    // MARK: - Pasteboard Operations

    private func writeToPasteboard(_ content: ClipContent, asPlainText: Bool) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // If plain text is requested, just write the text value
        if asPlainText {
            if let text = content.textValue {
                pasteboard.setString(text, forType: .string)
            }
            return
        }

        switch content.type {
        case .text, .richText:
            if let text = content.textValue {
                pasteboard.setString(text, forType: .string)
            }

        case .image:
            if let imageData = content.activeData as Data? {
                pasteboard.setData(imageData, forType: .png)
                // Also set as TIFF for compatibility
                if let image = NSImage(data: imageData),
                   let tiffData = image.tiffRepresentation {
                    pasteboard.setData(tiffData, forType: .tiff)
                }
            }

        case .link:
            if let urlString = content.textValue {
                pasteboard.setString(urlString, forType: .string)
                if let url = URL(string: urlString) {
                    pasteboard.setString(urlString, forType: .URL)
                }
            }

        case .file:
            if let fileURL = content.fileURL {
                pasteboard.writeObjects([fileURL as NSURL])
            }

        case .color:
            if let hex = content.textValue {
                pasteboard.setString(hex, forType: .string)
            }
        }
    }

    // MARK: - Simulate Paste

    private func simulatePaste() {
        // Small delay to ensure pasteboard is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.sendPasteKeystroke()
        }
    }

    private func sendPasteKeystroke() {
        // Create Cmd+V key event
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand

        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand

        // Post events
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    // MARK: - Open Actions

    /// Open a link or file
    func open(_ item: ClipItem) {
        guard let content = item.content else { return }

        switch content.type {
        case .link:
            if let url = content.urlValue {
                NSWorkspace.shared.open(url)
            }
        case .file:
            if let fileURL = content.fileURL {
                NSWorkspace.shared.open(fileURL)
            }
        default:
            break
        }

        item.markUsed()
    }
}
