import SwiftData
import Foundation

// MARK: - VitaminGMigrationPlan

/// Schema migration plan for the Vitamin G data store.
///
/// WR-06: Extracted from SchemaV2.swift into its own file so future schema authors
/// (SchemaV4 and beyond) discover and update the plan in one obvious location,
/// rather than buried inside the V2 file. Keep new versions added to BOTH `schemas`
/// and `stages` below whenever a new SchemaVN is introduced.
///
/// Migration policy:
/// - V1 → V2: lightweight (added Goal.isPublic with default + new UserProfile model)
/// - V2 → V3: lightweight (added new DailyWin model)
/// - V3 → V4: lightweight (added ChallengeTemplate, UserChallenge, CheckIn models — purely additive)
///
/// Source: developer.apple.com/documentation/swiftdata/modelcontainer/init(for:migrationplan:configurations:)
enum VitaminGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )
}
