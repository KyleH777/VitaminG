import XCTest
import SwiftData
@testable import VitaminG

// MARK: - Phase26CSVExportServiceTests
//
// Phase 26, Plan 01 — TDD GREEN tests for ANLT-04 CSV export service.
// All 4 tests verify CSVExportService.buildGlobalCSV behavior: header row,
// RFC 4180 escaping, is_frozen column logic, and date-ascending sort order.

@MainActor
final class Phase26CSVExportServiceTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try ModelContainerFactory.makeContainer(inMemory: true)
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - testCSVHeader

    /// buildGlobalCSV on empty input returns a string whose first line is the header row.
    func testCSVHeader() throws {
        let result = CSVExportService.buildGlobalCSV(events: [], goals: [], frozenDates: [])
        XCTAssertTrue(
            result.hasPrefix("goal_name,date,tier,is_frozen"),
            "First line must be exactly 'goal_name,date,tier,is_frozen' — got: \(result)"
        )
    }

    // MARK: - testCSVEscaping

    /// A goal whose title contains a comma must be RFC 4180 double-quoted in the output row.
    func testCSVEscaping() throws {
        let context = ModelContext(container)
        let goal = Goal(title: "My, Goal", tier: .immediate)
        context.insert(goal)

        let event = CompletionEvent(goal: goal)
        event.completedAt = Date()
        event.tierRawValue = GoalTier.immediate.rawValue
        event.goal = goal
        context.insert(event)

        let result = CSVExportService.buildGlobalCSV(
            events: [event],
            goals: [goal],
            frozenDates: []
        )
        XCTAssertTrue(
            result.contains("\"My, Goal\""),
            "Goal name containing a comma must be RFC 4180 quoted — got: \(result)"
        )
    }

    // MARK: - testIsFrozenColumn

    /// An event whose completedAt calendar day matches a frozenDate must have ",true" in the row;
    /// an event on a non-frozen day must have ",false".
    func testIsFrozenColumn() throws {
        let context = ModelContext(container)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        let goal = Goal(title: "FrozenTest", tier: .immediate)
        context.insert(goal)

        // Frozen event — completedAt is today, which is in frozenDates
        let frozenEvent = CompletionEvent(goal: goal)
        frozenEvent.completedAt = today
        frozenEvent.tierRawValue = GoalTier.immediate.rawValue
        frozenEvent.goal = goal
        context.insert(frozenEvent)

        // Non-frozen event — completedAt is yesterday, not in frozenDates
        let normalEvent = CompletionEvent(goal: goal)
        normalEvent.completedAt = yesterday
        normalEvent.tierRawValue = GoalTier.immediate.rawValue
        normalEvent.goal = goal
        context.insert(normalEvent)

        let result = CSVExportService.buildGlobalCSV(
            events: [frozenEvent, normalEvent],
            goals: [goal],
            frozenDates: [today]
        )

        let lines = result.components(separatedBy: "\n")
        // Lines: [header, sortedFirst(yesterday normal), sortedSecond(today frozen)]
        // Sorted ascending by date: yesterday < today
        let normalLine = lines.first(where: { $0.contains(formatDate(yesterday)) })
        let frozenLine = lines.first(where: { $0.contains(formatDate(today)) })

        XCTAssertNotNil(normalLine, "Should have a line for the non-frozen event")
        XCTAssertNotNil(frozenLine, "Should have a line for the frozen event")
        XCTAssertTrue(
            normalLine?.hasSuffix(",false") ?? false,
            "Non-frozen event row must end with ',false' — got: \(normalLine ?? "nil")"
        )
        XCTAssertTrue(
            frozenLine?.hasSuffix(",true") ?? false,
            "Frozen event row must end with ',true' — got: \(frozenLine ?? "nil")"
        )
    }

    // MARK: - testSortOrder

    /// Two events with completedAt at day+2 and day+0 — the day+0 row must appear
    /// before the day+2 row in the output (date ascending).
    func testSortOrder() throws {
        let context = ModelContext(container)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayPlus0 = today
        let dayPlus2 = cal.date(byAdding: .day, value: 2, to: today)!

        let goal = Goal(title: "SortTest", tier: .immediate)
        context.insert(goal)

        let eventDay2 = CompletionEvent(goal: goal)
        eventDay2.completedAt = dayPlus2
        eventDay2.tierRawValue = GoalTier.immediate.rawValue
        eventDay2.goal = goal
        context.insert(eventDay2)

        let eventDay0 = CompletionEvent(goal: goal)
        eventDay0.completedAt = dayPlus0
        eventDay0.tierRawValue = GoalTier.immediate.rawValue
        eventDay0.goal = goal
        context.insert(eventDay0)

        let result = CSVExportService.buildGlobalCSV(
            events: [eventDay2, eventDay0],
            goals: [goal],
            frozenDates: []
        )

        let lines = result.components(separatedBy: "\n").filter { !$0.isEmpty }
        // lines[0] = header, lines[1] = day+0 row (ascending), lines[2] = day+2 row
        XCTAssertTrue(
            lines.count >= 3,
            "Expected at least 3 lines (header + 2 data rows) — got: \(lines.count)"
        )
        let day0String = formatDate(dayPlus0)
        let day2String = formatDate(dayPlus2)
        XCTAssertTrue(
            lines[1].contains(day0String),
            "Line index 1 (first data row) must be day+0 (\(day0String)) — got: \(lines[1])"
        )
        XCTAssertTrue(
            lines[2].contains(day2String),
            "Line index 2 (second data row) must be day+2 (\(day2String)) — got: \(lines[2])"
        )
    }

    // MARK: - Private Helpers

    private func formatDate(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        return fmt.string(from: date)
    }
}
