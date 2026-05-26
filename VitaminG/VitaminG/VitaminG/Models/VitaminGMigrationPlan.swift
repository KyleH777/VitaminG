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
/// - V4 → V5: lightweight (added TransformationPhoto, SpendingFreezeEntry, NutritionEntry + 4 optional fields — purely additive)
/// - V5 → V6: lightweight (added category, frequency, reminderTime, startDate to Goal — all optional, purely additive)
/// - V6 → V7: lightweight (added GoalIdea, MoodEntry — new models, purely additive)
/// - V7 → V8: lightweight (added UserProfile.username — optional, nil default — UIADD-07)
/// - V8 → V9: lightweight (added UserProfile.motto, Goal.cloudKitPublicGoalRecordID — optional, nil defaults — Phase 22 D-07, D-10)
/// - V9 → V10: lightweight (added Goal.streakMilestonesShownJSON, Goal.completionCelebrationShown — optional, nil defaults — Phase 23 MILE-04)
///
/// Source: developer.apple.com/documentation/swiftdata/modelcontainer/init(for:migrationplan:configurations:)
enum VitaminGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self,
         SchemaV5.self, SchemaV6.self, SchemaV7.self, SchemaV8.self, SchemaV9.self,
         SchemaV10.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4,
         migrateV4toV5, migrateV5toV6, migrateV6toV7, migrateV7toV8, migrateV8toV9,
         migrateV9toV10]
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

    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )

    static let migrateV5toV6 = MigrationStage.lightweight(
        fromVersion: SchemaV5.self,
        toVersion: SchemaV6.self
    )

    static let migrateV6toV7 = MigrationStage.lightweight(
        fromVersion: SchemaV6.self,
        toVersion: SchemaV7.self
    )

    static let migrateV7toV8 = MigrationStage.lightweight(
        fromVersion: SchemaV7.self,
        toVersion: SchemaV8.self
    )

    static let migrateV8toV9 = MigrationStage.lightweight(
        fromVersion: SchemaV8.self,
        toVersion: SchemaV9.self
    )

    static let migrateV9toV10 = MigrationStage.lightweight(
        fromVersion: SchemaV9.self,
        toVersion: SchemaV10.self
    )
}
