// SchemaV10: adds Goal.streakMilestonesShownJSON (String?, nil default) and Goal.completionCelebrationShown (Bool?, nil default)
// — lightweight migration from V9. Phase 23 MILE-04.
import SwiftData
import Foundation

enum SchemaV10: VersionedSchema {
    static var versionIdentifier = Schema.Version(10, 0, 0)
    static var models: [any PersistentModel.Type] = [
        SchemaV10.Goal.self,
        SchemaV2.CompletionEvent.self,
        SchemaV10.UserProfile.self,
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

    // MARK: - UserProfile (V10 — identical to V9, no new fields)

    /// CloudKit-compatible SwiftData model for a user profile.
    /// All properties are optional or have defaults for CloudKit sync compatibility.
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

    // MARK: - Goal (V10 — adds streakMilestonesShownJSON and completionCelebrationShown)

    /// CloudKit-compatible SwiftData model for a user goal.
    /// All properties are optional or have defaults for CloudKit sync compatibility.
    /// streakMilestonesShownJSON and completionCelebrationShown added in V10 — optional with nil defaults, lightweight migration safe.
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

        // Added V10 — Phase 23 MILE-04
        /// JSON-encoded [Int] of milestone thresholds shown for this goal. Belt-and-suspenders alongside StreakMilestoneGate UserDefaults. Optional with nil default — lightweight migration safe.
        var streakMilestonesShownJSON: String? = nil

        /// Whether the MILE-06 "You did it" completion celebration has been shown. Optional with nil default — lightweight migration safe.
        var completionCelebrationShown: Bool? = nil

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
