import Foundation

// MARK: - WidgetDisplayData

/// Pre-computed display data for widget views.
/// Pure value type — no SwiftUI/SwiftData/WidgetKit dependency.
/// Follows StreakEngine/GoalSorter standalone struct pattern.
struct WidgetDisplayData {
    struct TierRow {
        let tier: GoalTier
        let topGoalTitle: String?  // nil = show empty state prompt
    }

    let tierRows: [TierRow]     // Always GoalTier.ordered order (4 elements)
    let globalStreak: Int

    /// Placeholder data for widget gallery (getSnapshot / placeholder).
    /// Uses sample goal titles so the widget gallery preview looks realistic.
    static let placeholder = WidgetDisplayData(
        tierRows: [
            TierRow(tier: .immediate, topGoalTitle: "Meditate for 10 minutes"),
            TierRow(tier: .shortTerm, topGoalTitle: "Read 12 books this quarter"),
            TierRow(tier: .longTerm, topGoalTitle: "Run a half marathon"),
            TierRow(tier: .lifeGoal, topGoalTitle: "Write a novel"),
        ],
        globalStreak: 7
    )

    /// Empty fallback for error states — all tiers nil, streak 0.
    static let empty = WidgetDisplayData(
        tierRows: GoalTier.ordered.map { TierRow(tier: $0, topGoalTitle: nil) },
        globalStreak: 0
    )
}

// MARK: - WidgetDataProvider

/// Builds WidgetDisplayData from raw Goal and CompletionEvent arrays.
/// Pure function — no SwiftData fetch, no SwiftUI rendering.
struct WidgetDataProvider {

    /// Build widget display data from fetched model arrays.
    ///
    /// - Parameters:
    ///   - goals: All Goal records (active + completed)
    ///   - events: All CompletionEvent records (for streak computation)
    ///   - calendar: Injectable calendar for testability (DST-safe per STATS-03)
    /// - Returns: WidgetDisplayData with one TierRow per GoalTier.ordered and globalStreak
    static func build(
        goals: [Goal],
        events: [CompletionEvent],
        calendar: Calendar = .current
    ) -> WidgetDisplayData {
        let globalStreak = StreakEngine.currentStreak(from: events, calendar: calendar)

        let tierRows: [WidgetDisplayData.TierRow] = GoalTier.ordered.map { tier in
            // Filter to active (not completed) goals matching this tier,
            // pick the earliest-created as the "top" goal for the tier row.
            let topTitle = goals
                .filter { $0.tier == tier && !$0.isCompleted }
                .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
                .first?.title
            return WidgetDisplayData.TierRow(tier: tier, topGoalTitle: topTitle)
        }

        return WidgetDisplayData(tierRows: tierRows, globalStreak: globalStreak)
    }
}

// MARK: - WidgetDataProvider + Timeline

extension WidgetDataProvider {
    /// Computes the next morning refresh date aligned with the user's notification time.
    /// If the target time has already passed today, returns tomorrow at that time.
    ///
    /// - Parameters:
    ///   - hour: Notification hour (0-23). Default 8.
    ///   - minute: Notification minute (0-59). Default 0.
    ///   - now: Current date for testability. Default Date().
    ///   - calendar: Calendar for date arithmetic. Default .current.
    /// - Returns: The next occurrence of the target time (today or tomorrow).
    static func nextMorningRefreshDate(
        hour: Int = 8,
        minute: Int = 0,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        let todayTarget = calendar.date(from: components) ?? now
        if todayTarget > now {
            return todayTarget
        } else {
            return calendar.date(byAdding: .day, value: 1, to: todayTarget) ?? todayTarget
        }
    }
}
