import SwiftData

// MARK: - ModelContainerFactory

/// Centralises ModelContainer creation so the same configuration is used by the app entry
/// point and tests can swap in an in-memory variant.
///
/// Production: writes to a shared App Group container and mirrors to CloudKit (D-13).
/// Testing: in-memory store with no App Group or CloudKit binding.
enum ModelContainerFactory {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(SchemaV1.models, version: SchemaV1.versionIdentifier)

        // On Simulator, App Group entitlements are not provisioned, so skip group container
        // and CloudKit to avoid a fatal assertion crash at launch (affects both app and test runner).
        #if targetEnvironment(simulator)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        #else
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier("group.com.kyleharrington.VitaminG"),
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        #endif

        return try ModelContainer(for: schema, configurations: config)
    }
}

// MARK: - CloudKit Schema Initialization (DEBUG only)

#if DEBUG
import CoreData

extension ModelContainerFactory {
    /// Forces CloudKit to register every attribute and relationship in the schema so sync works
    /// for all properties — not just properties that have been written at least once.
    ///
    /// Call once during development until the CloudKit console shows all attributes.
    /// Left guarded by #if DEBUG — it is slow but harmless in debug builds.
    ///
    /// Source: https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/
    static func initializeCloudKitSchema(container: ModelContainer) {
        do {
            // Mirror the store URL from the SwiftData container
            guard let storeURL = container.configurations.first?.url else { return }

            let desc = NSPersistentStoreDescription(url: storeURL)
            let opts = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.kyleharrington.VitaminG"
            )
            desc.cloudKitContainerOptions = opts
            desc.shouldAddStoreAsynchronously = false  // Required — schema init must be synchronous

            if let mom = NSManagedObjectModel.makeManagedObjectModel(
                for: [Goal.self, CompletionEvent.self]
            ) {
                let ckContainer = NSPersistentCloudKitContainer(
                    name: "VitaminG",
                    managedObjectModel: mom
                )
                ckContainer.persistentStoreDescriptions = [desc]
                ckContainer.loadPersistentStores { _, error in
                    if let error { print("Schema init load error: \(error)") }
                }
                try ckContainer.initializeCloudKitSchema()
                // Remove store to avoid double-open with SwiftData
                if let store = ckContainer.persistentStoreCoordinator.persistentStores.first {
                    try ckContainer.persistentStoreCoordinator.remove(store)
                }
                print("[DEBUG] initializeCloudKitSchema completed successfully")
            }
        } catch {
            print("[DEBUG] initializeCloudKitSchema error: \(error)")
            // Non-fatal in DEBUG — log and continue
        }
    }
}
#endif
