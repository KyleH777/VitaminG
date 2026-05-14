import SwiftData
import Observation
import Foundation

// MARK: - StatsViewModel

/// Observable ViewModel that computes streak values, completion rates, and heatmap data
/// from CompletionEvent and Goal records via StreakEngine.
///
/// STATS-04: Shows per-tier streaks, global streak, per-tier completion rates, and goal counts.
/// T-03-05: buildHeatmapData guards nil completedAt with `guard let`.
/// T-03-06: Data pre-built as [Date: Int] dictionary for O(1) per cell lookup in HeatmapView.
@MainActor
@Observable
final class StatsViewModel {

    // MARK: - Published State

    var globalStreak: Int = 0
    var tierStreaks: [GoalTier: Int] = [:]
    var tierCompletionRates: [GoalTier: Double] = [:]
    var tierGoalCounts: [GoalTier: Int] = [:]

    /// Pre-built heatmap dictionary keyed by Calendar.startOfDay for O(1) per-cell lookup.
    var heatmapData: [Date: Int] = [:]

    /// Weighted consistency score in [0, 100] over the last 30 days.
    var consistencyScore: Int = 0
    /// Bool array of length 7: index 0 = today, index 6 = 6 days ago.
    var recentDaysActivity: [Bool] = Array(repeating: false, count: 7)

    // MARK: - Refresh

    /// Recomputes all stats from raw SwiftData arrays.
    /// Call from StatsView.onAppear and .onChange of events/goals.
    func refresh(events: [CompletionEvent], goals: [Goal]) {
        globalStreak = StreakEngine.currentStreak(from: events)
        consistencyScore = ConsistencyEngine.score(events: events)
        recentDaysActivity = ConsistencyEngine.recentDays(events: events)

        for tier in GoalTier.ordered {
            tierStreaks[tier] = StreakEngine.currentStreak(from: events, tier: tier)

            let tierGoals = goals.filter { $0.tier == tier }
            tierCompletionRates[tier] = StreakEngine.completionRate(
                events: events,
                totalGoals: tierGoals.count,
                tier: tier
            )
            tierGoalCounts[tier] = tierGoals.count
        }

        heatmapData = buildHeatmapData(from: events)
    }

    // MARK: - Heatmap Data Builder

    /// Builds a [startOfDay: count] dictionary from completion events.
    /// T-03-05: `guard let` skips nil completedAt values — invalid dates produce empty cells, not crashes.
    private func buildHeatmapData(from events: [CompletionEvent]) -> [Date: Int] {
        var dict: [Date: Int] = [:]
        for event in events {
            guard let date = event.completedAt else { continue }
            let day = Calendar.current.startOfDay(for: date)
            dict[day, default: 0] += 1
        }
        return dict
    }
}
