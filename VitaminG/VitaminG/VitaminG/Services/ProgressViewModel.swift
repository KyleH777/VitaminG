import Foundation

// MARK: - ProgressViewModel

/// Standalone testable struct that computes per-goal progress, momentum, chart data,
/// and milestone-threshold crossings from CompletionEvent records.
///
/// Design constraints (PROG-01 through PROG-05, D-15, D-16):
/// - Pure struct, no SwiftData / SwiftUI imports — unit-testable in isolation
/// - All Goal / CompletionEvent values are passed as plain Swift values
/// - 7-day window via Calendar.current.startOfDay (D-04, D-05) — DST-safe
/// - PROG-05: no new model — derives entirely from existing CompletionEvent records
struct ProgressViewModel {

    // MARK: - DayCount

    /// One calendar day's completion count for a single goal (PROG-02 chart data).
    struct DayCount: Identifiable {
        let id = UUID()
        let date: Date            // Calendar.current.startOfDay value
        let count: Int
    }

    // MARK: - Milestone Thresholds

    /// PROG-03 / D-11 — cumulative-completion thresholds at which a celebration fires.
    static let milestoneThresholds: [Int] = [5, 10, 25, 50]

    // MARK: - Ring Progress (PROG-01, D-02)

    /// Ring fill = completions in last 7 calendar days / 7.0, clamped 0–1.
    /// A completed goal (`goal.completed == true`) returns 1.0 immediately (D-02).
    func ringProgress(
        for goal: Goal,
        events: [CompletionEvent],
        calendar: Calendar = .current
    ) -> Double {
        if goal.completed { return 1.0 }
        let count = countInLast7Days(for: goal, events: events, calendar: calendar)
        return min(Double(count) / 7.0, 1.0)
    }

    // MARK: - Momentum Score (PROG-04, D-04)

    /// Momentum = completions in last 7 calendar days / 7.0, clamped 0–1.
    /// Unlike ringProgress, momentum does NOT apply the isCompleted override —
    /// momentum reflects actual recent activity even on completed goals (RESEARCH.md A1).
    func momentumScore(
        for goal: Goal,
        events: [CompletionEvent],
        calendar: Calendar = .current
    ) -> Double {
        let count = countInLast7Days(for: goal, events: events, calendar: calendar)
        return min(Double(count) / 7.0, 1.0)
    }

    // MARK: - Chart Data (PROG-02, D-08)

    /// 30-day [DayCount] series, oldest-first. Days with zero completions are present
    /// with count 0 so the chart x-axis spans the full window.
    func chartData(
        for goal: Goal,
        events: [CompletionEvent],
        calendar: Calendar = .current
    ) -> [DayCount] {
        let today = calendar.startOfDay(for: Date())
        let goalEvents = events.filter { $0.goal?.id == goal.id }
        var dict: [Date: Int] = [:]
        for event in goalEvents {
            guard let date = event.completedAt else { continue }
            let day = calendar.startOfDay(for: date)
            dict[day, default: 0] += 1
        }
        // Build oldest-first: offset 29 (29 days ago) … offset 0 (today).
        return (0..<30).compactMap { offset -> DayCount? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            return DayCount(date: day, count: dict[day] ?? 0)
        }.reversed()
    }

    // MARK: - Milestone Detection (PROG-03, D-11, D-13)

    /// Returns the threshold that was just crossed, or nil if no threshold matches
    /// or the threshold has already been fired this session.
    /// `firedSet` keys: "\(goalID.uuidString)-\(threshold)".
    func milestoneJustCrossed(
        count: Int,
        firedSet: Set<String>,
        goalID: UUID
    ) -> Int? {
        for threshold in Self.milestoneThresholds {
            let key = "\(goalID.uuidString)-\(threshold)"
            if count == threshold && !firedSet.contains(key) {
                return threshold
            }
        }
        return nil
    }

    // MARK: - Private Helpers

    /// Count of completions for `goal` in the last 7 calendar days
    /// (today + 6 prior days, per D-05). DST-safe via calendar.startOfDay.
    private func countInLast7Days(
        for goal: Goal,
        events: [CompletionEvent],
        calendar: Calendar
    ) -> Int {
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            return 0
        }
        let goalEvents = events.filter { $0.goal?.id == goal.id }
        return goalEvents
            .compactMap { $0.completedAt }
            .map { calendar.startOfDay(for: $0) }
            .filter { $0 >= windowStart && $0 <= today }
            .count
    }
}
