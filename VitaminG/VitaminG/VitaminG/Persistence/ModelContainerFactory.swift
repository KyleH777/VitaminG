import SwiftData
import Foundation

// MARK: - ModelContainerFactory

/// Centralises ModelContainer creation so the same configuration is used by the app entry
/// point and tests can swap in an in-memory variant.
///
/// Production: writes to a shared App Group container and mirrors to CloudKit (D-13).
/// Testing: in-memory store with no App Group or CloudKit binding.
enum ModelContainerFactory {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(SchemaV10.models, version: SchemaV10.versionIdentifier)

        // Check at runtime whether the App Group is provisioned.
        // On Simulator and on device with a free personal team, this returns nil — fall back to
        // a plain local store so the app doesn't fatal-crash on launch.
        let appGroupAvailable = !inMemory &&
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.kyleharrington.VitaminG"
            ) != nil

        let config: ModelConfiguration
        if appGroupAvailable {
            // CloudKit disabled until paid Developer Program team is active in Xcode signing.
            // Switch cloudKitDatabase back to .automatic once the paid team appears in the
            // Team dropdown under Signing & Capabilities.
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.kyleharrington.VitaminG"),
                cloudKitDatabase: .none
            )
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        }

        // In-memory stores and test runs start fresh — no existing data to migrate.
        // Skip the migration plan to avoid iOS 26 SwiftData "Duplicate version checksums"
        // validation that fires when the same model type (e.g. SchemaV6.Goal) appears in
        // multiple lightweight migration stages (V6→V7 and V7→V8).
        // See: NSStagedMigrationManager._findCurrentMigrationStageFromModelChecksum crash.
        let isTestEnvironment = ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
        if inMemory || isTestEnvironment {
            return try ModelContainer(for: schema, configurations: config)
        }
        return try ModelContainer(for: schema, migrationPlan: VitaminGMigrationPlan.self, configurations: config)
    }

    /// Widget-safe ModelContainer: reads from App Group store but does NOT own CloudKit sync.
    /// Widget process has no iCloud entitlement — using .automatic would crash on device.
    /// Pitfall 2 from RESEARCH.md: widget must use cloudKitDatabase: .none.
    /// Must use same schema + migration plan as makeContainer to avoid store mismatch crash (T-07-02).
    static func makeWidgetContainer() throws -> ModelContainer {
        let schema = Schema(SchemaV10.models, version: SchemaV10.versionIdentifier)

        let appGroupAvailable = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.kyleharrington.VitaminG"
        ) != nil

        let config: ModelConfiguration
        if appGroupAvailable {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.kyleharrington.VitaminG"),
                cloudKitDatabase: .none
            )
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        return try ModelContainer(for: schema, migrationPlan: VitaminGMigrationPlan.self, configurations: config)
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
                for: [Goal.self, CompletionEvent.self, UserProfile.self, DailyWin.self,
                      ChallengeTemplate.self, UserChallenge.self, CheckIn.self,
                      TransformationPhoto.self, SpendingFreezeEntry.self, NutritionEntry.self]
            ) {
                let ckContainer = NSPersistentCloudKitContainer(
                    name: "VitaminG",
                    managedObjectModel: mom
                )
                ckContainer.persistentStoreDescriptions = [desc]
                ckContainer.loadPersistentStores { _, error in
                    if let error { VGLog.cloudKit.error("Schema init load error: \(error.localizedDescription, privacy: .public)") }
                }
                try ckContainer.initializeCloudKitSchema()
                // Remove store to avoid double-open with SwiftData
                if let store = ckContainer.persistentStoreCoordinator.persistentStores.first {
                    try ckContainer.persistentStoreCoordinator.remove(store)
                }
                VGLog.cloudKit.debug("initializeCloudKitSchema completed successfully")
            }
        } catch {
            VGLog.cloudKit.error("initializeCloudKitSchema error: \(error.localizedDescription, privacy: .public)")
            // Non-fatal in DEBUG — log and continue
        }
    }
}
#endif
