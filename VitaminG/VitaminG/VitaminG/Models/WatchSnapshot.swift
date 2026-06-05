import Foundation
#if os(iOS)
import SwiftData
#endif

// MARK: - WatchSnapshot

/// Codable snapshot of the user's current goal/streak state for WCSession delivery.
///
/// Transmitted as `Data` in the `[String: Any]` applicationContext dictionary:
/// `try? JSONEncoder().encode(snapshot)` → `Data` → `["snapshot": data]`
///
/// Design constraints (WATCH-02):
/// - `activeGoalProgress` is `Double` (non-optional) — Watch progress ring requires a concrete
///   Double value; nil from WidgetDataProvider is coerced to 0.0 (CONTEXT.md D-01)
/// - All fields must be property-list compatible types when encoded as Data in WCSession context
/// - `activeGoalId` uses `UUID.uuidString` (String) so it is property-list safe
/// - Conforms to Equatable for round-trip test assertions
struct WatchSnapshot: Codable, Equatable {

    // MARK: - Fields

    /// Title of the highest-priority non-completed goal. nil when no active goal exists.
    let activeGoalTitle: String?

    /// Progress ratio for the active goal (0.0–1.0). 0.0 when no duration is set (D-01).
    let activeGoalProgress: Double

    /// Global streak across all goals (CompletionEvent-based, calendar-day deduped).
    let globalStreak: Int

    /// True when the active goal has a CompletionEvent on the current calendar day.
    let hasCheckedInToday: Bool

    /// UUID string of the active goal. nil when no active goal exists.
    /// Used by Watch→iPhone check-in relay to identify which goal to check in.
    let activeGoalId: String?

    // MARK: - Placeholder

    /// Placeholder data for widget gallery / complication preview.
    /// Uses realistic sample data so the Watch face gallery looks meaningful.
    static let placeholder = WatchSnapshot(
        activeGoalTitle: "Morning run",
        activeGoalProgress: 0.72,
        globalStreak: 7,
        hasCheckedInToday: false,
        activeGoalId: nil
    )

    // MARK: - Build

    #if os(iOS)
    /// Builds a WatchSnapshot from fetched Goal and CompletionEvent arrays.
    ///
    /// Delegates active goal selection, progress, and streak computation to
    /// `WidgetDataProvider.build()` to guarantee identical output on iPhone and Watch.
    ///
    /// - Parameters:
    ///   - goals: All Goal records (active + completed)
    ///   - events: All CompletionEvent records (for streak computation)
    ///   - calendar: Injectable calendar for testability (DST-safe)
    /// - Returns: WatchSnapshot with fields mirroring the active goal state
    static func build(
        goals: [Goal],
        events: [CompletionEvent],
        calendar: Calendar = .current
    ) -> WatchSnapshot {
        // Delegate to WidgetDataProvider for active goal selection, progress, and streak.
        // This guarantees WatchSnapshot.activeGoalTitle/Progress/globalStreak == WidgetDisplayData.
        let displayData = WidgetDataProvider.build(goals: goals, events: events, calendar: calendar)

        // Resolve the active goal using the same GoalTier.ordered priority + earliest-creationDate
        // selection as WidgetDataProvider.build() (must match — cannot re-derive differently).
        let activeGoal: Goal? = GoalTier.ordered.compactMap { tier in
            goals
                .filter { $0.tier == tier && !$0.isCompleted }
                .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
                .first
        }.first

        // hasCheckedInToday: true when the active goal has any CompletionEvent on today's calendar day.
        let hasCheckedInToday: Bool = {
            guard let goal = activeGoal else { return false }
            return goal.completionEvents?.contains {
                calendar.isDateInToday($0.completedAt ?? .distantPast)
            } ?? false
        }()

        // D-01: coerce nil activeGoalProgress to 0.0 (ring requires a concrete Double)
        return WatchSnapshot(
            activeGoalTitle: displayData.activeGoalTitle,
            activeGoalProgress: displayData.activeGoalProgress ?? 0.0,
            globalStreak: displayData.globalStreak,
            hasCheckedInToday: hasCheckedInToday,
            activeGoalId: activeGoal?.id.uuidString
        )
    }
    #endif
}
