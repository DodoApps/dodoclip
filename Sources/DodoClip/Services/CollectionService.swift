import Foundation
import SwiftData
import Combine

@MainActor
final class CollectionService: ObservableObject {
    static let shared = CollectionService()
    
    @Published private(set) var customCollections: [Collection] = []
    private var modelContext: ModelContext?
    
    private init() {
        setupPersistence()
    }
    
    // MARK: - Persistence
    
    private func setupPersistence() {
    // Share the same ModelContext with ClipboardMonitor to avoid cross-context issues
    modelContext = ClipboardMonitor.shared.getModelContext()
    loadCollections()
    }
    
    private func loadCollections() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Collection>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        
        do {
            let allCollections = try context.fetch(descriptor)
            // Filter out smart collections (system tabs)
            customCollections = allCollections.filter { !$0.isSmartCollection }
            objectWillChange.send()
        } catch {
            print("Failed to load collections: \(error)")
        }
    }
    
    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Failed to save context: \(error)")
            context.rollback()
        }
    }
    
    // MARK: - Public API
    
    /// Get all collections (default + custom)
    var allCollections: [Collection] {
        Collection.defaultCollections + customCollections
    }
    
    /// Create a new custom collection
    func createCollection(name: String, icon: String = "folder", colorHex: String = "#007AFF") {
        let sortOrder = (customCollections.map { $0.sortOrder }.max() ?? 2) + 1
        let collection = Collection(
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            smartFilterType: nil
        )
        
        modelContext?.insert(collection)
        customCollections.append(collection)
        saveContext()
        objectWillChange.send()
    }
    
    /// Delete a custom collection
    func deleteCollection(_ collection: Collection) {
        guard !collection.isSmartCollection else { return }
        
        if let index = customCollections.firstIndex(where: { $0.id == collection.id }) {
            customCollections.remove(at: index)
        }
        
        modelContext?.delete(collection)
        saveContext()
        objectWillChange.send()
    }
    
    /// Rename a collection
    func renameCollection(_ collection: Collection, newName: String) {
        collection.name = newName
        saveContext()
        objectWillChange.send()
    }
    
  /// Add item to collection (using ClipboardMonitor's context)
    func addItem(_ item: ClipItem, to collection: Collection) {
        guard !collection.isSmartCollection else { return }
        
    // Use ClipboardMonitor's context to ensure same context for relationships
    ClipboardMonitor.shared.addItemToCollection(item, collection: collection)
    }
    
    /// Remove item from collection
    func removeItem(_ item: ClipItem, from collection: Collection) {
        guard !collection.isSmartCollection else { return }
        
        if let index = collection.items?.firstIndex(where: { $0.id == item.id }) {
            collection.items?.remove(at: index)
            saveContext()
            objectWillChange.send()
        }
    }
}
