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
    /// The highest-priority non-completed goal title (Immediate > ShortTerm > LongTerm > LifeGoal).
    /// nil when all goals are completed or no goals exist.
    let activeGoalTitle: String?
    /// Progress ratio for the active goal (0.0–1.0, clamped). nil when goal.durationDays is nil or 0.
    let activeGoalProgress: Double?

    /// Placeholder data for widget gallery (getSnapshot / placeholder).
    /// Uses sample goal titles so the widget gallery preview looks realistic.
    static let placeholder = WidgetDisplayData(
        tierRows: [
            TierRow(tier: .immediate, topGoalTitle: "Meditate for 10 minutes"),
            TierRow(tier: .shortTerm, topGoalTitle: "Read 12 books this quarter"),
            TierRow(tier: .longTerm, topGoalTitle: "Run a half marathon"),
            TierRow(tier: .lifeGoal, topGoalTitle: "Write a novel"),
        ],
        globalStreak: 7,
        activeGoalTitle: "Meditate for 10 minutes",
        activeGoalProgress: 0.43
    )

    /// Empty fallback for error states — all tiers nil, streak 0.
    static let empty = WidgetDisplayData(
        tierRows: GoalTier.ordered.map { TierRow(tier: $0, topGoalTitle: nil) },
        globalStreak: 0,
        activeGoalTitle: nil,
        activeGoalProgress: nil
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

        // D-03: Active goal = highest-priority non-completed goal (Immediate > ShortTerm > LongTerm > LifeGoal).
        // Within a tier, earliest creationDate wins.
        let activeGoal = GoalTier.ordered.compactMap { tier in
            goals
                .filter { $0.tier == tier && !$0.isCompleted }
                .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
                .first
        }.first

        let activeGoalTitle = activeGoal?.title

        // D-04: Progress = completionEvents.count / durationDays (clamped 0.0–1.0).
        // nil when durationDays is nil or 0 (no progress bar rendered).
        let activeGoalProgress: Double? = {
            guard let goal = activeGoal,
                  let duration = goal.durationDays,
                  duration > 0 else { return nil }
            let count = Double(goal.completionEvents?.count ?? 0)
            return min(1.0, count / Double(duration))
        }()

        return WidgetDisplayData(
            tierRows: tierRows,
            globalStreak: globalStreak,
            activeGoalTitle: activeGoalTitle,
            activeGoalProgress: activeGoalProgress
        )
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
