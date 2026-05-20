import Foundation

struct GoalInput {
    var title: String
    var tier: GoalTier
    var category: GoalCategory
    var frequency: GoalFrequency
    var reminderTime: Date?
    var isPrivate: Bool
    var startDate: Date?
    /// Optional goal duration in days (e.g. 30-day challenge). nil means open-ended.
    /// Added for GOAL2-01 — Plan 03 Step3DetailsScreen writes this via the wizard.
    var durationDays: Int? = nil
}
