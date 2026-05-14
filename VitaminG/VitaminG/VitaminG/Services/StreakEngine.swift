import Foundation

// MARK: - StreakEngine

/// Standalone testable struct that computes streak and completion-rate statistics
/// from CompletionEvent records.
///
/// Design constraints (STATS-01 through STATS-06):
/// - All computation derives solely from CompletionEvent records, NOT Goal.isCompleted
/// - Calendar.current arithmetic is used throughout — no raw TimeInterval — for DST safety
/// - A Set<Date> of start-of-day values provides O(1) day lookup
/// - nil completedAt values are skipped via compactMap (T-03-01 threat mitigation)
struct StreakEngine {

    // MARK: - currentStreak

    /// Computes the current streak — consecutive days ending at today (or yesterday if today
    /// has no event yet, since the day isn't over) with at least one CompletionEvent.
    ///
    /// - Parameters:
    ///   - events: Array of CompletionEvent records (STATS-06: sole source of truth)
    ///   - tier: If provided, only count events matching this tier (STATS-01).
    ///           If nil, count all tiers (STATS-02: global streak).
    ///   - frozenDates: Dates that count as completed days regardless of real events
    ///                  (e.g. streak freeze burns). Defaults to `[]` so existing callers
    ///                  are unaffected. Merged into the day set before computation; duplicate
    ///                  dates (same startOfDay) are deduplicated by the Set.
    ///   - calendar: Injectable Calendar for testability (STATS-03: DST-safe).
    ///               Defaults to `.current`.
    /// - Returns: Number of consecutive days in the current streak.
    static func currentStreak(
        from events: [CompletionEvent],
        tier: GoalTier? = nil,
        frozenDates: [Date] = [],
        calendar: Calendar = .current
    ) -> Int {
        // Step 1: Filter by tier if provided; T-03-02 — GoalTier(rawValue:) handles invalid raw values
        let filtered = filteredEvents(events, tier: tier)

        // Step 2: Build a Set<Date> of unique calendar start-of-day values.
        // compactMap skips nil completedAt (T-03-01 threat mitigation).
        // calendar.startOfDay(for:) is DST-safe — no raw 86400s.
        var days: Set<Date> = Set(
            filtered.compactMap { $0.completedAt }.map { calendar.startOfDay(for: $0) }
        )
        // Frozen dates count as completed days; union deduplicates same-day entries.
        for frozen in frozenDates {
            days.insert(calendar.startOfDay(for: frozen))
        }

        guard !days.isEmpty else { return 0 }

        // Step 3: Determine the start candidate.
        let today = calendar.startOfDay(for: Date())

        // If today has no event, walk back to yesterday — the day isn't over yet.
        var candidate: Date
        if days.contains(today) {
            candidate = today
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                return 0
            }
            candidate = yesterday
        }

        // Step 4: Walk backward while consecutive days are found.
        var streak = 0
        while days.contains(candidate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: candidate) else {
                break
            }
            candidate = previous
        }

        return streak
    }

    // MARK: - completionRate

    /// Returns the ratio of unique completed goal IDs to totalGoals for a given tier.
    ///
    /// - Parameters:
    ///   - events: Array of CompletionEvent records.
    ///   - totalGoals: Denominator — total number of goals in the relevant scope.
    ///   - tier: If provided, only count events matching this tier.
    ///           If nil, count all tiers.
    /// - Returns: A Double in [0, 1]. Returns 0 if totalGoals is 0.
    static func completionRate(
        events: [CompletionEvent],
        totalGoals: Int,
        tier: GoalTier? = nil
    ) -> Double {
        guard totalGoals > 0 else { return 0 }

        let filtered = filteredEvents(events, tier: tier)

        // Count unique completed goal IDs
        let uniqueGoalIDs = Set(filtered.compactMap { $0.goal?.id })

        return Double(uniqueGoalIDs.count) / Double(totalGoals)
    }

    // MARK: - bestStreak

    /// Computes the all-time best streak — the longest consecutive run of days
    /// on which at least one CompletionEvent occurred.
    ///
    /// - Parameters:
    ///   - events: Array of CompletionEvent records.
    ///   - tier: If provided, only count events matching this tier.
    ///           If nil, count all tiers.
    ///   - calendar: Injectable Calendar for testability. Defaults to `.current`.
    /// - Returns: Length of the longest consecutive-day run. Returns 0 for empty input.
    static func bestStreak(events: [CompletionEvent], tier: GoalTier? = nil, calendar: Calendar = .current) -> Int {
        let filtered = filteredEvents(events, tier: tier)
        let days = Set(
            filtered.compactMap { $0.completedAt }
                    .map { calendar.startOfDay(for: $0) }
        )
        guard !days.isEmpty else { return 0 }
        var best = 0
        for day in days {
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { continue }
            guard !days.contains(prev) else { continue }
            var run = 1
            var cursor = day
            while true {
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                guard days.contains(next) else { break }
                run += 1
                cursor = next
            }
            best = max(best, run)
        }
        return best
    }

    // MARK: - Private Helpers

    /// Filters events by tier if provided; returns all events if tier is nil.
    /// T-03-02: GoalTier(rawValue:) naturally handles nil or invalid tierRawValue — filter
    /// computes `event.tier` which falls back to `.immediate` for invalid raw values.
    /// Since invalid tier values will never match a specific requested tier, they are safely
    /// excluded from per-tier computations.
    private static func filteredEvents(
        _ events: [CompletionEvent],
        tier: GoalTier?
    ) -> [CompletionEvent] {
        guard let tier else { return events }
        return events.filter { $0.tier == tier }
    }
}
