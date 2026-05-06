import Foundation

// MARK: - ChallengeStreakEngine

/// Pure, dependency-free struct for computing challenge streaks from an array of check-in dates.
///
/// Design constraints (CHAL-05):
/// - Calendar.current arithmetic used throughout — no raw TimeInterval — for DST safety.
/// - A Set<Date> of start-of-day values provides O(1) day lookup.
/// - nil dates in the check-in array are skipped via compactMap (T-13-06 threat mitigation).
/// - No SwiftData/SwiftUI imports — engine is fully unit-testable in isolation.
/// - Injectable Calendar parameter supports time-zone tests without relying on .current.
struct ChallengeStreakEngine {

    // MARK: - currentStreak

    /// Current streak: consecutive days ending at today (or yesterday if no check-in today,
    /// since the day isn't over yet — mirrors the pattern in StreakEngine.swift).
    ///
    /// - Parameters:
    ///   - checkInDates: Raw Date values from CheckIn records. Duplicates on the same calendar
    ///                   day are collapsed to one via Set<Date> dedup.
    ///   - calendar: Injectable Calendar for testability (DST-safe). Defaults to `.current`.
    /// - Returns: Number of consecutive days in the current streak.
    static func currentStreak(
        from checkInDates: [Date],
        calendar: Calendar = .current
    ) -> Int {
        // Step 1: Build a Set<Date> of unique calendar start-of-day values.
        // compactMap-based construction handles nil dates defensively.
        let days: Set<Date> = Set(
            checkInDates.compactMap { calendar.startOfDay(for: $0) }
        )
        guard !days.isEmpty else { return 0 }

        // Step 2: Determine start candidate.
        // If today has a check-in, start from today; otherwise start from yesterday
        // (the day is still in progress — streak preservation per StreakEngine pattern).
        let today = calendar.startOfDay(for: Date())
        var candidate: Date
        if days.contains(today) {
            candidate = today
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                return 0
            }
            // If yesterday is also not present, streak is 0 (gap > 1 day).
            candidate = yesterday
        }

        // Step 3: Walk backward while consecutive days are present.
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

    // MARK: - longestStreak

    /// Longest streak across the full check-in history.
    ///
    /// Sorts all unique calendar days in ascending order, then walks the sequence counting
    /// consecutive runs. O(n log n) on unique-day count — bounded to 90 for any one challenge.
    ///
    /// - Parameters:
    ///   - checkInDates: Raw Date values from CheckIn records.
    ///   - calendar: Injectable Calendar for testability. Defaults to `.current`.
    /// - Returns: Length of the longest consecutive-day run in the full history.
    static func longestStreak(
        from checkInDates: [Date],
        calendar: Calendar = .current
    ) -> Int {
        let sorted = Set(checkInDates.compactMap { calendar.startOfDay(for: $0) }).sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            guard let expectedNext = calendar.date(byAdding: .day, value: 1, to: sorted[i - 1]) else {
                continue
            }
            if sorted[i] == expectedNext {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }
}
