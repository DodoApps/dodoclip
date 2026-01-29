import AppKit
import Combine
import SwiftData

/// Service that monitors the system clipboard for changes
@MainActor
final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    // Published state
    @Published private(set) var items: [ClipItem] = []
    @Published var isPaused: Bool = false
    @Published var newClipCount: Int = 0

    // Private state
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var pauseUntil: Date?
    private var modelContext: ModelContext?

    // Configuration
    private var historyLimit: Int = 1000
    private var ignorePasswordManagers: Bool = true
    private var passwordManagerBundleIDs: Set<String> = [
        "com.agilebits.onepassword7",
        "com.1password.1password",
        "com.lastpass.LastPass",
        "com.bitwarden.desktop",
        "com.dashlane.dashlanephonefinal"
    ]
    private var ignoredBundleIDs: Set<String> = []

    private init() {
        // Initialize with SwiftData
        setupPersistence()
    }

    // MARK: - Persistence

    private func setupPersistence() {
        do {
            let schema = Schema([ClipItem.self, Collection.self, AppSettings.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(container)
            loadPersistedItems()
        } catch {
            print("Failed to setup SwiftData: \(error)")
        }
    }

    private func loadPersistedItems() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate { !$0.isDeleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            items = try context.fetch(descriptor)
            objectWillChange.send()
        } catch {
            print("Failed to load items: \(error)")
        }
    }

    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard timer == nil else { return }

        lastChangeCount = NSPasteboard.general.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        // Check if paused
        if isPaused {
            if let until = pauseUntil, Date() > until {
                resumeCapture()
            } else {
                return
            }
        }

        let pasteboard = NSPasteboard.general

        // Check if clipboard changed
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Check for transient/concealed data (password managers)
        if isTransientOrConcealed(pasteboard) { return }

        // Get frontmost app
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let bundleID = frontmostApp?.bundleIdentifier

        // Check if source app is ignored
        if let bundleID = bundleID {
            if ignoredBundleIDs.contains(bundleID) {
                return
            }
            // Check password managers if enabled
            if ignorePasswordManagers && passwordManagerBundleIDs.contains(bundleID) {
                return
            }
        }

        // Process clipboard content
        processClipboardContent(pasteboard, from: frontmostApp)
    }

    private func isTransientOrConcealed(_ pasteboard: NSPasteboard) -> Bool {
        // Check for concealed types (used by password managers)
        let concealedTypes: [NSPasteboard.PasteboardType] = [
            NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"),
            NSPasteboard.PasteboardType("org.nspasteboard.TransientType"),
            NSPasteboard.PasteboardType("com.agilebits.onepassword")
        ]

        for type in concealedTypes {
            if pasteboard.data(forType: type) != nil {
                return true
            }
        }

        return false
    }

    private func processClipboardContent(_ pasteboard: NSPasteboard, from app: NSRunningApplication?) {
        let bundleID = app?.bundleIdentifier
        let appName = app?.localizedName

        // Try to create content from pasteboard
        guard let content = extractContent(from: pasteboard) else { return }

        // Check for duplicates - if duplicate, move to top
        if let existingIndex = items.firstIndex(where: { $0.content == content }) {
            let existing = items.remove(at: existingIndex)
            existing.markUsed()
            items.insert(existing, at: 0)
            saveContext()
            objectWillChange.send()
            return
        }

        // Create new clip item
        let item = ClipItem(
            content: content,
            sourceAppBundleID: bundleID,
            sourceAppName: appName
        )

        // Insert into SwiftData context
        modelContext?.insert(item)

        // Add to front
        items.insert(item, at: 0)
        newClipCount += 1

        // Enforce history limit
        enforceHistoryLimit()
        saveContext()
        objectWillChange.send()

        // Fetch link metadata asynchronously if it's a link
        if content.type == .link, let urlString = content.textValue {
            Task {
                await fetchLinkMetadata(for: item, urlString: urlString)
            }
        }

        // Perform OCR on images asynchronously
        if content.type == .image {
            Task {
                await performOCR(for: item)
            }
        }
    }

    /// Perform OCR on an image item and store the recognized text
    private func performOCR(for item: ClipItem) async {
        guard let content = item.content,
              content.type == .image,
              let recognizedText = await OCRService.shared.recognizeText(in: content.data) else {
            return
        }

        // Update the item with OCR text
        item.ocrText = recognizedText
        saveContext()
        objectWillChange.send()
    }

    /// Fetch og:image and favicon for a link item
    private func fetchLinkMetadata(for item: ClipItem, urlString: String) async {
        guard let metadata = await LinkMetadataService.shared.fetchMetadata(for: urlString) else {
            return
        }

        // Update the item with fetched metadata
        item.updateLinkMetadata(
            ogTitle: metadata.ogTitle,
            ogImageData: metadata.ogImageData,
            faviconData: metadata.faviconData
        )

        saveContext()
        objectWillChange.send()
    }

    private func extractContent(from pasteboard: NSPasteboard) -> ClipContent? {
        // Priority: Image > File > URL > Text

        // Check for image
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            if let image = NSImage(data: imageData) {
                return .image(image)
            }
        }

        // Check for file URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           let firstURL = urls.first {
            return .file(path: firstURL.path, name: firstURL.lastPathComponent)
        }

        // Check for plain text (which may contain URLs)
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if it's a URL (http/https link)
            if isURL(trimmed) {
                return .link(trimmed, title: nil)
            }

            // Check if it's a color hex code
            if isColorHex(trimmed) {
                return .color(hex: trimmed)
            }

            return .text(text)
        }

        return nil
    }

    private func isURL(_ string: String) -> Bool {
        // Check for common URL schemes
        let lowercased = string.lowercased()
        guard lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") else {
            return false
        }

        // Validate it's a proper URL
        guard let url = URL(string: string),
              url.host != nil else {
            return false
        }

        return true
    }

    private func isColorHex(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    private func enforceHistoryLimit() {
        // Keep pinned items regardless of limit
        let pinnedItems = items.filter { $0.isPinned }
        var unpinnedItems = items.filter { !$0.isPinned }

        let maxUnpinned = max(0, historyLimit - pinnedItems.count)
        if unpinnedItems.count > maxUnpinned {
            // Delete excess items from SwiftData
            let itemsToDelete = Array(unpinnedItems.dropFirst(maxUnpinned))
            for item in itemsToDelete {
                modelContext?.delete(item)
            }
            unpinnedItems = Array(unpinnedItems.prefix(maxUnpinned))
        }

        items = pinnedItems + unpinnedItems
        items.sort { $0.createdAt > $1.createdAt }
    }

    // MARK: - Pause Control

    func pause(for duration: PauseDuration) {
        isPaused = true
        if let interval = duration.interval {
            pauseUntil = Date().addingTimeInterval(interval)
        } else {
            pauseUntil = nil
        }
    }

    func resumeCapture() {
        isPaused = false
        pauseUntil = nil
    }

    // MARK: - Configuration

    func setHistoryLimit(_ limit: Int) {
        historyLimit = limit
        enforceHistoryLimit()
    }

    func setIgnorePasswordManagers(_ ignore: Bool) {
        ignorePasswordManagers = ignore
    }

    func addIgnoredApp(_ bundleID: String) {
        ignoredBundleIDs.insert(bundleID)
    }

    func removeIgnoredApp(_ bundleID: String) {
        ignoredBundleIDs.remove(bundleID)
    }

    // MARK: - Actions

    func deleteItem(_ item: ClipItem) {
        item.softDelete()
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
        saveContext()
        objectWillChange.send()
    }

    func restoreItem(_ item: ClipItem) {
        item.restore()
        saveContext()
        objectWillChange.send()
    }

    func pinItem(_ item: ClipItem) {
        item.togglePin()
        saveContext()
        objectWillChange.send()
    }

    func resetNewClipCount() {
        newClipCount = 0
    }
}
