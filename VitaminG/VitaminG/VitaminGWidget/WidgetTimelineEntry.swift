import WidgetKit

/// Timeline entry holding pre-computed widget display data.
/// Used by both GoalSummaryWidget and StreakWidget timeline providers.
struct GoalEntry: TimelineEntry {
    let date: Date
    let displayData: WidgetDisplayData
}
