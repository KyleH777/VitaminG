import SwiftData
import Observation
import Foundation

// MARK: - Supporting Types

/// A single data point for a weekly or monthly chart bar.
struct BucketItem: Identifiable {
    let id = UUID()
    /// The first calendar day of the week or month this bucket represents.
    let periodStart: Date
    /// Completion rate in [0.0, 1.0] — unique days with any event divided by total days in period.
    let completionRate: Double
}

/// Selects the time granularity for the analytics chart.
enum ChartGranularity: String, Hashable {
    case weekly
    case monthly
}

// MARK: - AnalyticsViewModel

/// Observable ViewModel that computes weekly/monthly completion-rate buckets and
/// per-goal heatmap data from CompletionEvent and Goal records.
///
/// ANLT-02: Weekly and monthly bucket computation with unique-day formula (D-05).
/// ANLT-03: Per-goal heatmap data, all goals, and heatmap start-date fallback chain.
@MainActor
@Observable
final class AnalyticsViewModel {

    // MARK: - Published State

    /// Sorted ascending: one BucketItem per ISO week that has events.
    var weeklyBuckets: [BucketItem] = []

    /// Sorted ascending: one BucketItem per calendar month that has events.
    var monthlyBuckets: [BucketItem] = []

    /// Heatmap data keyed by goal.id.uuidString → [startOfDay: count].
    /// Sentinel -1 marks frozen days with no real check-in (same convention as StatsViewModel).
    var heatmapDataByGoal: [String: [Date: Int]] = [:]

    /// All goals provided to the last refresh call (active and completed — D-08).
    var allGoals: [Goal] = []

    // MARK: - Refresh

    /// Recomputes all analytics state from raw SwiftData arrays.
    /// Call from AnalyticsView.onAppear and .onChange of events/goals.
    ///
    /// - Parameters:
    ///   - events: All CompletionEvent records to include in computation.
    ///   - goals: All Goal records (active and completed).
    ///   - frozenDates: Streak-freeze dates; these appear as sentinel -1 in heatmap data.
    func refresh(events: [CompletionEvent], goals: [Goal], frozenDates: [Date] = []) {
        allGoals = goals
        weeklyBuckets = buildWeeklyBuckets(events: events)
        monthlyBuckets = buildMonthlyBuckets(events: events)

        var byGoal: [String: [Date: Int]] = [:]
        for goal in goals {
            byGoal[goal.id.uuidString] = buildGoalHeatmapData(
                goal: goal,
                events: events,
                frozenDates: frozenDates
            )
        }
        heatmapDataByGoal = byGoal
    }

    // MARK: - Heatmap Start Date

    /// Returns the earliest date to use as the start of a goal's heatmap.
    ///
    /// Fallback chain (D-05 / ANLT-03):
    ///   1. goal.creationDate (if non-nil)
    ///   2. earliest completedAt among the goal's CompletionEvents (if any)
    ///   3. 90 days before today
    func heatmapStartDate(for goal: Goal) -> Date {
        if let creation = goal.creationDate {
            return creation
        }
        if let earliest = goal.completionEvents?
            .compactMap({ $0.completedAt })
            .min() {
            return earliest
        }
        return Calendar.current.date(byAdding: .day, value: -90, to: Date())!
    }

    // MARK: - Weekly Bucket Builder

    /// Groups events by ISO week and computes completionRate = unique days / 7.0.
    private func buildWeeklyBuckets(events: [CompletionEvent]) -> [BucketItem] {
        let cal = Calendar.current
        // [weekStart: Set<startOfDay>]
        var uniqueDaysPerWeek: [Date: Set<Date>] = [:]

        for event in events {
            guard let completedAt = event.completedAt else { continue }
            guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: completedAt) else { continue }
            let weekStart = weekInterval.start
            let dayStart = cal.startOfDay(for: completedAt)
            uniqueDaysPerWeek[weekStart, default: []].insert(dayStart)
        }

        return uniqueDaysPerWeek
            .sorted { $0.key < $1.key }
            .map { weekStart, uniqueDays in
                BucketItem(
                    periodStart: weekStart,
                    completionRate: Double(uniqueDays.count) / 7.0
                )
            }
    }

    // MARK: - Monthly Bucket Builder

    /// Groups events by calendar month and computes completionRate = unique days / daysInMonth.
    private func buildMonthlyBuckets(events: [CompletionEvent]) -> [BucketItem] {
        let cal = Calendar.current
        // [monthStart: Set<startOfDay>]
        var uniqueDaysPerMonth: [Date: Set<Date>] = [:]

        for event in events {
            guard let completedAt = event.completedAt else { continue }
            guard let monthInterval = cal.dateInterval(of: .month, for: completedAt) else { continue }
            let monthStart = monthInterval.start
            let dayStart = cal.startOfDay(for: completedAt)
            uniqueDaysPerMonth[monthStart, default: []].insert(dayStart)
        }

        return uniqueDaysPerMonth
            .sorted { $0.key < $1.key }
            .map { monthStart, uniqueDays in
                let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
                return BucketItem(
                    periodStart: monthStart,
                    completionRate: Double(uniqueDays.count) / Double(daysInMonth)
                )
            }
    }

    // MARK: - Per-Goal Heatmap Builder

    /// Builds a [startOfDay: count] dictionary for a single goal's completion events.
    /// Sentinel -1 marks frozen dates with no real check-in (same convention as StatsViewModel).
    private func buildGoalHeatmapData(
        goal: Goal,
        events: [CompletionEvent],
        frozenDates: [Date]
    ) -> [Date: Int] {
        let cal = Calendar.current
        let goalEvents = events.filter { $0.goal?.id == goal.id }

        var dict: [Date: Int] = [:]
        for event in goalEvents {
            guard let date = event.completedAt else { continue }
            let day = cal.startOfDay(for: date)
            dict[day, default: 0] += 1
        }
        for frozen in frozenDates {
            let day = cal.startOfDay(for: frozen)
            if dict[day] == nil {
                dict[day] = -1
            }
        }
        return dict
    }
}
