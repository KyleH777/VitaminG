// SchemaV9: adds UserProfile.motto (String?, nil default) and Goal.cloudKitPublicGoalRecordID (String?, nil default)
// — lightweight migration from V8. Phase 22 D-07, D-10.
import SwiftData
import Foundation

enum SchemaV9: VersionedSchema {
    static var versionIdentifier = Schema.Version(9, 0, 0)
    static var models: [any PersistentModel.Type] = [
        SchemaV9.Goal.self,
        SchemaV2.CompletionEvent.self,
        SchemaV9.UserProfile.self,
        SchemaV3.DailyWin.self,
        SchemaV4.ChallengeTemplate.self,
        SchemaV4.UserChallenge.self,
        SchemaV4.CheckIn.self,
        SchemaV5.TransformationPhoto.self,
        SchemaV5.SpendingFreezeEntry.self,
        SchemaV5.NutritionEntry.self,
        SchemaV7.GoalIdea.self,
        SchemaV7.MoodEntry.self
    ]

    // MARK: - UserProfile (V9 — adds motto)

    /// CloudKit-compatible SwiftData model for a user profile.
    /// All properties are optional or have defaults for CloudKit sync compatibility.
    /// motto added in V9 — optional with nil default, qualifies for lightweight migration.
    @Model final class UserProfile {
        var id: UUID = UUID()
        var displayName: String?
        var avatarColorHex: String?
        var isPublic: Bool = false
        var cloudKitPublicRecordID: String?
        var photoData: Data?
        // Added V8 — UIADD-07
        var username: String?
        // Added V9 — Phase 22 D-07
        /// Short bio/motto shown on public profile. Optional with nil default — lightweight migration safe.
        var motto: String? = nil

        init() { self.id = UUID(); self.isPublic = false }
    }

    // MARK: - Goal (V9 — adds cloudKitPublicGoalRecordID)

    /// CloudKit-compatible SwiftData model for a user goal.
    /// All properties are optional or have defaults for CloudKit sync compatibility.
    /// cloudKitPublicGoalRecordID added in V9 — optional with nil default, qualifies for lightweight migration.
    @Model final class Goal {
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
        // Fields from V6
        /// User-defined category label for the goal (e.g. "Health", "Career").
        var category: String?
        /// Recurrence descriptor (e.g. "Daily", "Weekly"). nil means no recurrence.
        var frequency: String?
        /// Optional per-goal reminder time. nil means no goal-specific reminder.
        var reminderTime: Date?
        /// Goal start date for scheduling and progress tracking.
        var startDate: Date?
        /// Optional goal duration in days (e.g. 30-day challenge). nil means open-ended.
        var durationDays: Int?

        @Relationship(deleteRule: .cascade, inverse: \SchemaV2.CompletionEvent.goal)
        var completionEvents: [SchemaV2.CompletionEvent]?

        // Added V9 — Phase 22 D-10
        /// CloudKit record name for the corresponding PublicGoal record in the public DB.
        /// nil until the goal has been written to CloudKit (backfill sets this on first Phase 22 launch).
        /// Optional with nil default — lightweight migration safe.
        var cloudKitPublicGoalRecordID: String? = nil

        init(
            title: String,
            goalDescription: String = "",
            tier: GoalTier = .immediate,
            associatedInspiration: String = "",
            durationDays: Int? = nil
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
            self.durationDays = durationDays
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
