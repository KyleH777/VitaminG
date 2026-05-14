import SwiftData
import Foundation

// MARK: - SchemaV6
//
// Version 6 of the Vitamin G data schema.
// Adds 4 optional fields to Goal (Phase 16 — Platform Features):
//   - category: String?         — user-defined goal category label
//   - frequency: String?        — recurrence descriptor (e.g. "Daily", "Weekly")
//   - reminderTime: Date?       — optional per-goal reminder time
//   - startDate: Date?          — goal start date for scheduling/tracking
//
// CRITICAL: All new properties are optional — CloudKit sync compatibility (CLAUDE.md).
// Do not add @Attribute(.unique) — CloudKit does not support atomic uniqueness.
// Lightweight migration from V5 — purely additive new fields with nil defaults.

enum SchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV6.Goal.self,
         SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self,
         SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self,
         SchemaV5.TransformationPhoto.self,
         SchemaV5.SpendingFreezeEntry.self,
         SchemaV5.NutritionEntry.self]
    }

    // MARK: - Goal (V6 — adds category, frequency, reminderTime, startDate)

    /// CloudKit-compatible SwiftData model for a user goal.
    /// All properties are optional or have defaults for CloudKit sync compatibility.
    /// category, frequency, reminderTime, startDate added in V6 — all optional, qualifies for lightweight migration.
    @Model
    final class Goal {
        var id: UUID = UUID()
        var title: String?
        /// Use goalDescription, NOT description — 'description' shadows NSObject.description.
        var goalDescription: String?
        /// Raw value of GoalTier stored as String for CloudKit compatibility.
        var tierRawValue: String?
        var isCompleted: Bool = false
        var creationDate: Date?
        var associatedInspiration: String?
        /// Per-goal privacy toggle. Default false — all goals are private by default.
        var isPublic: Bool = false
        // New in V6
        /// User-defined category label for the goal (e.g. "Health", "Career").
        var category: String?
        /// Recurrence descriptor (e.g. "Daily", "Weekly"). nil means no recurrence.
        var frequency: String?
        /// Optional per-goal reminder time. nil means no goal-specific reminder.
        var reminderTime: Date?
        /// Goal start date for scheduling and progress tracking.
        var startDate: Date?

        @Relationship(deleteRule: .cascade, inverse: \SchemaV2.CompletionEvent.goal)
        var completionEvents: [SchemaV2.CompletionEvent]?

        init(
            title: String,
            goalDescription: String = "",
            tier: GoalTier = .immediate,
            associatedInspiration: String = ""
        ) {
            self.id = UUID()
            self.title = title
            self.goalDescription = goalDescription
            self.tierRawValue = tier.rawValue
            self.isCompleted = false
            self.creationDate = Date()
            self.associatedInspiration = associatedInspiration
            self.completionEvents = []
            self.isPublic = false
        }

        /// Computed accessor for the GoalTier enum.
        var tier: GoalTier {
            get { GoalTier(rawValue: tierRawValue ?? "") ?? .immediate }
            set { tierRawValue = newValue.rawValue }
        }

        /// Computed accessor for completion state (mirrors isCompleted).
        var completed: Bool {
            get { isCompleted }
            set { isCompleted = newValue }
        }
    }
}
