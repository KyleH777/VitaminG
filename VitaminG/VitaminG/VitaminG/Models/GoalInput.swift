import Foundation

struct GoalInput {
    var title: String
    var tier: GoalTier
    var category: GoalCategory
    var frequency: GoalFrequency
    var reminderTime: Date?
    var isPrivate: Bool
    var startDate: Date?
}
