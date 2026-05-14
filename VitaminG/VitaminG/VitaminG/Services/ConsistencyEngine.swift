import Foundation

// MARK: - ConsistencyEngine

/// Standalone testable struct that computes a weighted consistency score
/// from CompletionEvent records over a 30-day rolling window.
///
/// Design constraints:
/// - Pure function: no side effects, no SwiftUI/SwiftData dependency
/// - Injectable `asOf` date parameter for deterministic testing
/// - Exponential decay: recent days are weighted more heavily than older days
/// - Events older than 30 days are ignored entirely
/// - nil completedAt values are skipped via compactMap (threat mitigation)
struct ConsistencyEngine {

    // MARK: - Constants

    private static let windowDays = 30
    /// Decay rate: larger values penalise older days more steeply.
    /// At decay = 0.75, weight(day 0) accounts for ~53% of total weight across 30 days,
    /// satisfying the test invariant that a single today-only event scores > 50.
    /// weight(day 29) / weight(day 0) = exp(-0.75 * 29) ≈ 0.000001 — effectively negligible.
    private static let decay: Double = 0.75

    // MARK: - score

    /// Returns a weighted consistency score in [0, 100] for the 30-day window ending today.
    ///
    /// The score is the ratio of the sum of weights on days with at least one completion event
    /// to the total possible weight across all 30 days, expressed as an integer percentage.
    ///
    /// - Parameters:
    ///   - events: Array of CompletionEvent records. nil completedAt values are skipped.
    ///   - asOf: Reference date for "today". Defaults to `.now` for production use;
    ///           inject a fixed date in tests for deterministic results.
    /// - Returns: Integer in [0, 100].
    static func score(events: [CompletionEvent], asOf: Date = .now) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: asOf)

        // Build a Set<Date> of unique calendar days (start-of-day) within the window.
        // compactMap skips nil completedAt values.
        // filter excludes days outside [0, windowDays) range.
        let completedDays: Set<Date> = Set(
            events.compactMap { $0.completedAt }
                .map { cal.startOfDay(for: $0) }
                .filter { day in
                    guard let diff = cal.dateComponents([.day], from: day, to: today).day else {
                        return false
                    }
                    return diff >= 0 && diff < windowDays
                }
        )

        var weightedSum: Double = 0
        var totalWeight: Double = 0

        for daysAgo in 0..<windowDays {
            let weight = exp(-decay * Double(daysAgo))
            totalWeight += weight
            guard let day = cal.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            if completedDays.contains(day) {
                weightedSum += weight
            }
        }

        guard totalWeight > 0 else { return 0 }
        return Int((weightedSum / totalWeight * 100).rounded())
    }

    // MARK: - recentDays

    /// Returns a Bool array of length 7 indicating which of the last 7 days
    /// (index 0 = today, index 6 = 6 days ago) had at least one CompletionEvent.
    ///
    /// - Parameters:
    ///   - events: Array of CompletionEvent records. nil completedAt values are skipped.
    ///   - asOf: Reference date for "today". Defaults to `.now`.
    /// - Returns: Array of 7 Bools, index 0 = today.
    static func recentDays(events: [CompletionEvent], asOf: Date = .now) -> [Bool] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: asOf)
        let completedDays: Set<Date> = Set(
            events.compactMap { $0.completedAt }.map { cal.startOfDay(for: $0) }
        )
        return (0..<7).map { daysAgo in
            guard let day = cal.date(byAdding: .day, value: -daysAgo, to: today) else {
                return false
            }
            return completedDays.contains(day)
        }
    }
}
