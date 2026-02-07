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
    
  // MARK: - Public Access

  /// Get the model context for shared use
  func getModelContext() -> ModelContext? {
    return modelContext
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
            // Only save if there are actual changes
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Failed to save context: \(error)")
            // Rollback on error to prevent inconsistent state
            context.rollback()
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
        if let existingIndex = items.firstIndex(where: { item in
            // Safely check if item is still valid before comparing
            guard !item.isDeleted else { return false }
            return item.content == content
        }) {
            let existing = items.remove(at: existingIndex)
            // Double-check item is still valid before accessing
            guard !existing.isDeleted else {
                items.insert(existing, at: existingIndex) // Put it back
                return
            }
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
        // Check if item is still valid before accessing
        guard !item.isDeleted,
              let content = item.content,
              content.type == .image,
              let recognizedText = await OCRService.shared.recognizeText(in: content.data) else {
            return
        }

        // Double-check item is still valid after async operation
        guard !item.isDeleted else { return }

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

        // Check if item is still valid after async operation
        guard !item.isDeleted else { return }

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

        // Check for file URLs - use safer approach to avoid NSSecureCoding crashes
        // First check if the pasteboard contains file URL types
        if pasteboard.types?.contains(.fileURL) == true {
            // Try to read file URLs with explicit error handling
            if let propertyList = pasteboard.propertyList(forType: .fileURL) as? String,
               let url = URL(string: propertyList),
               url.isFileURL {
                return .file(path: url.path, name: url.lastPathComponent)
            }
            
            // Fallback: try reading as string and check if it's a file path
            if let urlString = pasteboard.string(forType: .fileURL),
               let url = URL(string: urlString),
               url.isFileURL {
                return .file(path: url.path, name: url.lastPathComponent)
            }
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
        // Filter out any already deleted items first
        items = items.filter { !$0.isDeleted }

        // Keep pinned items regardless of limit
        let pinnedItems = items.filter { $0.isPinned }
        var unpinnedItems = items.filter { !$0.isPinned }

        let maxUnpinned = max(0, historyLimit - pinnedItems.count)
        if unpinnedItems.count > maxUnpinned {
            // Delete excess items from SwiftData
            let itemsToDelete = Array(unpinnedItems.dropFirst(maxUnpinned))
            for item in itemsToDelete {
                guard !item.isDeleted else { continue }
                modelContext?.delete(item)
            }
            unpinnedItems = Array(unpinnedItems.prefix(maxUnpinned))
        }

        // Sort pinned and unpinned separately, then combine
        let sortedPinned = pinnedItems.sorted { $0.createdAt > $1.createdAt }
        let sortedUnpinned = unpinnedItems.sorted { $0.createdAt > $1.createdAt }
        items = sortedPinned + sortedUnpinned
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
        
        // Don't re-sort immediately to avoid index confusion in UI
        // The UI layer (PanelContentView) already handles separating pinned/unpinned items
        saveContext()
        
        // Check if we need to enforce history limit without re-sorting
        // Only delete excess unpinned items if needed (oldest first)
        let pinnedCount = items.filter { $0.isPinned && !$0.isDeleted }.count
        let unpinnedItems = items.filter { !$0.isPinned && !$0.isDeleted }
            .sorted { $0.createdAt < $1.createdAt } // Sort by creation time, oldest first
        let maxUnpinned = max(0, historyLimit - pinnedCount)
        
        if unpinnedItems.count > maxUnpinned {
            let itemsToDelete = Array(unpinnedItems.prefix(unpinnedItems.count - maxUnpinned))
            for itemToDelete in itemsToDelete {
                modelContext?.delete(itemToDelete)
                if let index = items.firstIndex(where: { $0.id == itemToDelete.id }) {
                    items.remove(at: index)
                }
            }
            saveContext()
        }
        
        objectWillChange.send()
    }

    func resetNewClipCount() {
        newClipCount = 0
    }
    
  // MARK: - Reordering

  /// Move an item to a new position in the list
  func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
    guard sourceIndex != destinationIndex,
      sourceIndex >= 0, sourceIndex < items.count,
      destinationIndex >= 0, destinationIndex < items.count
    else {
      return
    }

    let item = items.remove(at: sourceIndex)
    items.insert(item, at: destinationIndex)

    // Update the createdAt timestamp to maintain order
    // Items earlier in the list should have newer timestamps
    let now = Date()
    for (index, item) in items.enumerated() {
      // Subtract index seconds to create unique timestamps in order
      item.createdAt = now.addingTimeInterval(-Double(index))
    }

    saveContext()
    objectWillChange.send()
  }
    
  // MARK: - Collection Management

  /// Add an item to a collection by collection ID
  func addItemToCollection(_ item: ClipItem, collectionID: UUID) {
    guard let context = modelContext else { return }

    // Fetch the collection from the same context
    let descriptor = FetchDescriptor<Collection>(
      predicate: #Predicate<Collection> { $0.id == collectionID }
    )

    guard let collection = try? context.fetch(descriptor).first else {
      print("Collection not found in context")
      return
    }

    guard !collection.isSmartCollection else { return }

    // Initialize collections array if needed
    if item.collections == nil {
      item.collections = []
    }

    // Check if item is already in collection
    let alreadyInCollection = item.collections?.contains(where: { $0.id == collectionID }) ?? false

    if !alreadyInCollection {
      item.collections?.append(collection)
      saveContext()
      objectWillChange.send()
    }
  }

  /// Add an item to a collection (legacy method for compatibility)
  func addItemToCollection(_ item: ClipItem, collection: Collection) {
    addItemToCollection(item, collectionID: collection.id)
  }

  // MARK: - Auto Cleanup

    /// Delete unpinned items older than specified days
    func performAutoCleanup(olderThanDays days: Int) {
        guard days > 0 else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Find items to delete (older than cutoff, not pinned, not already deleted)
        let itemsToDelete = items.filter { item in
            !item.isPinned && !item.isDeleted && item.createdAt < cutoffDate
        }

        guard !itemsToDelete.isEmpty else { return }

        // Delete items
        for item in itemsToDelete {
            modelContext?.delete(item)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items.remove(at: index)
            }
        }

        saveContext()
        objectWillChange.send()

        print("Auto-cleanup: deleted \(itemsToDelete.count) items older than \(days) days")
    }

    /// Check and perform auto-cleanup based on settings
    func checkAutoCleanup() {
        let days = SettingsService.shared.autoDeleteAfterDays
        if days > 0 {
            performAutoCleanup(olderThanDays: days)
        }
    }
}
