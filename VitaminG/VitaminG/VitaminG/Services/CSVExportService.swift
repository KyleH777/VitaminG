import Foundation

// MARK: - CSVExportService

/// Pure struct service — no SwiftUI or SwiftData dependency.
/// Builds an in-memory CSV string for export via ShareLink.
/// Columns: goal_name, date, tier, is_frozen.
/// Date format: ISO 8601 YYYY-MM-DD (D-11).
///
/// Design constraints (mirrors ConsistencyEngine pattern):
/// - Pure functions: no side effects, no SwiftUI/SwiftData dependency
/// - All static methods — no instantiation required
/// - RFC 4180 escaping for goal_name and tier fields (T-26-01)
struct CSVExportService {

    // MARK: - Private Constants

    private static let header = "goal_name,date,tier,is_frozen"

    // MARK: - buildGlobalCSV

    /// Builds a CSV string for all completion events across all goals.
    ///
    /// - Parameters:
    ///   - events: All CompletionEvent records. Events with nil completedAt are skipped.
    ///   - goals: All Goal records. Unused directly; goal data is read from event.goal.
    ///   - frozenDates: Dates on which streak freezes were active. Events whose
    ///                  calendar day matches a frozen date receive "true" in is_frozen column.
    /// - Returns: A CSV string. First line is always the header row. Rows are sorted by
    ///            completedAt ascending. Empty input returns header only (no trailing newline).
    static func buildGlobalCSV(events: [CompletionEvent], goals: [Goal], frozenDates: [Date]) -> String {
        return buildRows(events: events, frozenDates: frozenDates)
    }

    // MARK: - buildGoalCSV

    /// Builds a CSV string for completion events belonging to a single goal.
    ///
    /// - Parameters:
    ///   - goal: The goal whose events should be exported.
    ///   - events: All CompletionEvent records. Filtered to those whose goal matches.
    ///   - frozenDates: Dates on which streak freezes were active.
    /// - Returns: A CSV string. First line is always the header row. Rows are sorted by
    ///            completedAt ascending.
    static func buildGoalCSV(goal: Goal, events: [CompletionEvent], frozenDates: [Date]) -> String {
        let filtered = events.filter { $0.goal === goal }
        return buildRows(events: filtered, frozenDates: frozenDates)
    }

    // MARK: - Private Helpers

    /// Shared row-building logic used by both public methods.
    private static func buildRows(events: [CompletionEvent], frozenDates: [Date]) -> String {
        let cal = Calendar.current

        // Build a Set of start-of-day dates for O(1) frozen-day lookup.
        let frozenDaySet: Set<Date> = Set(frozenDates.map { cal.startOfDay(for: $0) })

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        // Filter out events with nil completedAt, then sort ascending.
        let withDate = events.filter { $0.completedAt != nil }
        let sorted = withDate.sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }

        var lines: [String] = [header]

        for event in sorted {
            guard let completedAt = event.completedAt else { continue }

            let goalName = (event.goal?.title ?? "Unknown").csvEscaped
            let dateString = dateFormatter.string(from: completedAt)
            let tier = (event.tierRawValue ?? "unknown").csvEscaped
            let eventDay = cal.startOfDay(for: completedAt)
            let isFrozen = frozenDaySet.contains(eventDay) ? "true" : "false"

            lines.append("\(goalName),\(dateString),\(tier),\(isFrozen)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - String RFC 4180 CSV Escaping

private extension String {
    /// Wraps the string in double-quotes and escapes any embedded double-quotes
    /// per RFC 4180 (each " becomes "").
    /// Apply to any field that may contain commas, quotes, or newlines.
    var csvEscaped: String {
        let escaped = replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
