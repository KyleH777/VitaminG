// Phase 18 Wave 0 — RED tests. Will go GREEN as Plans 02 & 05 land implementations.
// Tests GOAL2-05: day grid filled/empty cell logic, Monday-first weekday offset, month bounds.
// NOTE: GoalDayGridCalendar.daysInMonth and completedDays helper are intentionally
// forward-referenced. Plan 05 adds these. This file will FAIL TO COMPILE until Plan 05 lands.

import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class Phase18GoalDayGridTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    // MARK: - Helpers

    /// Returns a Date for the given year/month/day using the current calendar.
    private func makeDate(year: Int, month: Int, day: Int, calendar: Calendar = .current) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }

    // MARK: - GOAL2-05: Monday-first weekday padding (Pitfall 5)

    /// GOAL2-05 Pitfall 5: The day grid uses Monday-first weekday ordering.
    /// May 2026 starts on a Friday (weekday 5 in Monday-first: Mon=1, Fri=5).
    /// So the first 4 entries [0...3] must be nil padding (Mon, Tue, Wed, Thu),
    /// and index 4 must be 2026-05-01 (Friday).
    /// RED: GoalDayGridCalendar.daysInMonth is not yet defined — Plan 05 adds it.
    func test_daysInMonth_paddsLeadingForMondayStart() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2  // Monday = 2 in Gregorian Calendar.weekday
        let may2026 = makeDate(year: 2026, month: 5, day: 1, calendar: cal)

        // RED: GoalDayGridCalendar is not yet defined — Plan 05 adds this helper
        let days = GoalDayGridCalendar.daysInMonth(for: may2026, calendar: cal)

        // May 1, 2026 is a Friday. In Mon-first grid: Mon=pad, Tue=pad, Wed=pad, Thu=pad, Fri=May 1
        XCTAssertNil(days[0], "GOAL2-05 Mon: index 0 (Mon) must be nil padding before May 1")
        XCTAssertNil(days[1], "GOAL2-05 Tue: index 1 (Tue) must be nil padding before May 1")
        XCTAssertNil(days[2], "GOAL2-05 Wed: index 2 (Wed) must be nil padding before May 1")
        XCTAssertNil(days[3], "GOAL2-05 Thu: index 3 (Thu) must be nil padding before May 1")
        XCTAssertNotNil(days[4], "GOAL2-05 Fri: index 4 (Fri) must be May 1, 2026")

        if let firstDay = days[4] {
            let dayNumber = cal.component(.day, from: firstDay)
            XCTAssertEqual(dayNumber, 1, "GOAL2-05: index 4 must be the 1st of the month")
        }
    }

    // MARK: - GOAL2-05: All days of month included

    /// GOAL2-05: For a 31-day month (e.g., January 2026), the total non-nil entries must be 31.
    /// RED: GoalDayGridCalendar.daysInMonth is not yet defined — Plan 05 adds it.
    func test_daysInMonth_includesAllDaysOfMonth() {
        let jan2026 = makeDate(year: 2026, month: 1, day: 1)

        // RED: GoalDayGridCalendar is not yet defined — Plan 05 adds this helper
        let days = GoalDayGridCalendar.daysInMonth(for: jan2026, calendar: .current)

        let nonNilCount = days.compactMap { $0 }.count
        XCTAssertEqual(nonNilCount, 31, "GOAL2-05: January has 31 days — all must appear as non-nil entries")
    }

    // MARK: - GOAL2-05: No days from following month

    /// GOAL2-05: The last non-nil entry must belong to the displayed month, not the next.
    /// RED: GoalDayGridCalendar.daysInMonth is not yet defined — Plan 05 adds it.
    func test_daysInMonth_doesNotIncludeFollowingMonth() {
        let apr2026 = makeDate(year: 2026, month: 4, day: 1)
        let cal = Calendar.current

        // RED: GoalDayGridCalendar is not yet defined — Plan 05 adds this helper
        let days = GoalDayGridCalendar.daysInMonth(for: apr2026, calendar: cal)

        let nonNilDays = days.compactMap { $0 }
        guard let lastDay = nonNilDays.last else {
            XCTFail("Expected non-nil days in April 2026")
            return
        }

        let lastDayMonth = cal.component(.month, from: lastDay)
        let displayedMonth = cal.component(.month, from: apr2026)
        XCTAssertEqual(lastDayMonth, displayedMonth,
            "GOAL2-05: Last non-nil entry must belong to the displayed month (April), not May")
    }

    // MARK: - GOAL2-05: completedDays filters by goal ID

    /// GOAL2-05: Per-goal completedDays Set must contain only events whose goal matches the
    /// target goal. Events from other goals must be excluded.
    /// Uses Calendar.startOfDay per RESEARCH.md Pattern 4.
    /// RED: GoalDayGridCalendar.completedDays is not yet defined — Plan 05 adds it.
    func test_completedDaysSet_filtersByGoalId() throws {
        // Create two goals
        let goalA = Goal(title: "Goal A", tier: .immediate)
        let goalB = Goal(title: "Goal B", tier: .immediate)
        context.insert(goalA)
        context.insert(goalB)
        try context.save()

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        // Events for goalA
        let eventA1 = CompletionEvent(goal: goalA)
        eventA1.completedAt = today
        context.insert(eventA1)

        let eventA2 = CompletionEvent(goal: goalA)
        eventA2.completedAt = yesterday
        context.insert(eventA2)

        // Event for goalB (different goal)
        let eventB1 = CompletionEvent(goal: goalB)
        eventB1.completedAt = today
        context.insert(eventB1)

        let allEvents = [eventA1, eventA2, eventB1]

        // RED: GoalDayGridCalendar.completedDays is not yet defined — Plan 05 adds this
        let completedSet = GoalDayGridCalendar.completedDays(for: goalA, from: allEvents, calendar: cal)

        XCTAssertEqual(completedSet.count, 2,
            "GOAL2-05: completedDays for goalA must contain 2 entries (today + yesterday)")
        XCTAssertTrue(completedSet.contains(today),
            "GOAL2-05: today must be in goalA's completedDays set")
        XCTAssertTrue(completedSet.contains(yesterday),
            "GOAL2-05: yesterday must be in goalA's completedDays set")
    }

    // MARK: - GOAL2-05: Forward navigation gate — cannot advance past current month

    /// GOAL2-05 (D-10): Forward navigation must be disabled when the displayed month
    /// equals the current calendar month. Users can't navigate to future months.
    /// RED: GoalDayGridCalendar.canNavigateForward is not yet defined — Plan 05 adds it.
    func test_canNavigateForward_falseWhenAlreadyAtCurrentMonth() {
        let cal = Calendar.current
        let currentMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!

        // RED: GoalDayGridCalendar.canNavigateForward is not yet defined — Plan 05 adds it
        let canForward = GoalDayGridCalendar.canNavigateForward(
            displayedMonth: currentMonthStart,
            calendar: cal
        )

        XCTAssertFalse(canForward,
            "GOAL2-05 D-10: canNavigateForward must return false when displayedMonth == current month")
    }
}
