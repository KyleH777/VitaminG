import XCTest
import SwiftData
@testable import VitaminG

// Phase 26, Plan 02 — GREEN implementations replacing RED stubs from Plan 01.
// Tests cover ANLT-02 (bucket computation) and ANLT-03 (heatmap data, all goals, start date).

@MainActor
final class Phase26AnalyticsViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var viewModel: AnalyticsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        viewModel = AnalyticsViewModel()
    }

    override func tearDown() async throws {
        container = nil
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Creates a fixed Monday in ISO week 2 of 2025 (2025-01-06).
    private var monday2025w02: Date {
        // 2025-01-06 00:00:00 UTC in Gregorian calendar
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 1
        comps.day = 6
        comps.hour = 12
        return Calendar.current.date(from: comps)!
    }

    /// Creates a CompletionEvent for a goal with completedAt = base + dayOffset days.
    private func makeEvent(goal: Goal, dayOffset: Int, base: Date) -> CompletionEvent {
        let context = ModelContext(container)
        context.insert(goal)
        let event = CompletionEvent(goal: goal)
        event.completedAt = Calendar.current.date(byAdding: .day, value: dayOffset, to: base)
        context.insert(event)
        return event
    }

    // MARK: - testWeeklyBuckets

    /// 3 events on Mon, Tue, Wed of the same ISO week → 1 bucket with rate 3/7.
    /// Then add 1 event in the following week → 2 buckets total.
    func testWeeklyBuckets() throws {
        let context = ModelContext(container)
        let goal = Goal(title: "Weekly Goal")
        context.insert(goal)

        let base = monday2025w02  // Monday of week 2-2025

        // Events on Mon, Tue, Wed in the same week
        let e1 = CompletionEvent(goal: goal)
        e1.completedAt = base                                                     // Mon
        let e2 = CompletionEvent(goal: goal)
        e2.completedAt = Calendar.current.date(byAdding: .day, value: 1, to: base)  // Tue
        let e3 = CompletionEvent(goal: goal)
        e3.completedAt = Calendar.current.date(byAdding: .day, value: 2, to: base)  // Wed

        context.insert(e1)
        context.insert(e2)
        context.insert(e3)

        // Single week: 3 unique days → rate = 3/7
        viewModel.refresh(events: [e1, e2, e3], goals: [goal], frozenDates: [])

        XCTAssertEqual(viewModel.weeklyBuckets.count, 1, "3 events in the same week → 1 bucket")
        XCTAssertEqual(
            viewModel.weeklyBuckets[0].completionRate,
            3.0 / 7.0,
            accuracy: 0.001,
            "completionRate for 3 unique days in a 7-day week should be 3/7"
        )

        // Add 1 event in the next week (Mon + 7 days)
        let e4 = CompletionEvent(goal: goal)
        e4.completedAt = Calendar.current.date(byAdding: .day, value: 7, to: base)
        context.insert(e4)

        viewModel.refresh(events: [e1, e2, e3, e4], goals: [goal], frozenDates: [])

        XCTAssertEqual(viewModel.weeklyBuckets.count, 2, "Events in two separate weeks → 2 buckets")
    }

    // MARK: - testMonthlyBuckets

    /// Events in January 2025 and February 2025 → 2 buckets, each with completionRate > 0.
    func testMonthlyBuckets() throws {
        let context = ModelContext(container)
        let goal = Goal(title: "Monthly Goal")
        context.insert(goal)

        // January 15, 2025
        var janComps = DateComponents()
        janComps.year = 2025
        janComps.month = 1
        janComps.day = 15
        janComps.hour = 10
        let janDate = Calendar.current.date(from: janComps)!

        // February 10, 2025
        var febComps = DateComponents()
        febComps.year = 2025
        febComps.month = 2
        febComps.day = 10
        febComps.hour = 10
        let febDate = Calendar.current.date(from: febComps)!

        let e1 = CompletionEvent(goal: goal)
        e1.completedAt = janDate
        context.insert(e1)

        let e2 = CompletionEvent(goal: goal)
        e2.completedAt = febDate
        context.insert(e2)

        viewModel.refresh(events: [e1, e2], goals: [goal], frozenDates: [])

        XCTAssertEqual(viewModel.monthlyBuckets.count, 2, "Events in January and February → 2 buckets")

        let sorted = viewModel.monthlyBuckets.sorted { $0.periodStart < $1.periodStart }
        XCTAssertGreaterThan(sorted[0].completionRate, 0, "January bucket should have completionRate > 0")
        XCTAssertGreaterThan(sorted[1].completionRate, 0, "February bucket should have completionRate > 0")

        // January has 31 days, 1 unique day → rate = 1/31
        XCTAssertEqual(sorted[0].completionRate, 1.0 / 31.0, accuracy: 0.001, "January: 1/31")
        // February 2025 has 28 days → rate = 1/28
        XCTAssertEqual(sorted[1].completionRate, 1.0 / 28.0, accuracy: 0.001, "February: 1/28")
    }

    // MARK: - testCompletionRateFormula

    /// 2 events on Monday and Wednesday of the same week (2 unique days, no duplicates)
    /// → completionRate == 2/7 exactly (Double division, not integer).
    ///
    /// Also verifies that two events on the SAME day count as only 1 unique day.
    func testCompletionRateFormula() throws {
        let context = ModelContext(container)
        let goal = Goal(title: "Rate Formula Goal")
        context.insert(goal)

        let base = monday2025w02  // Monday

        // Event on Monday and Wednesday (2 unique days)
        let e1 = CompletionEvent(goal: goal)
        e1.completedAt = base                                                       // Mon
        let e2 = CompletionEvent(goal: goal)
        e2.completedAt = Calendar.current.date(byAdding: .day, value: 2, to: base) // Wed

        context.insert(e1)
        context.insert(e2)

        viewModel.refresh(events: [e1, e2], goals: [goal], frozenDates: [])

        XCTAssertEqual(viewModel.weeklyBuckets.count, 1)
        XCTAssertEqual(
            viewModel.weeklyBuckets[0].completionRate,
            2.0 / 7.0,
            accuracy: 0.001,
            "2 unique days in a 7-day week → rate = 2/7"
        )

        // Add a DUPLICATE event on Monday (same day as e1) — should NOT increase rate
        let e3 = CompletionEvent(goal: goal)
        e3.completedAt = Calendar.current.startOfDay(for: base) // Same calendar day as e1
        context.insert(e3)

        viewModel.refresh(events: [e1, e2, e3], goals: [goal], frozenDates: [])

        XCTAssertEqual(viewModel.weeklyBuckets.count, 1)
        XCTAssertEqual(
            viewModel.weeklyBuckets[0].completionRate,
            2.0 / 7.0,
            accuracy: 0.001,
            "Same-day duplicate event must not increase unique-day count; rate still 2/7"
        )
    }

    // MARK: - testHeatmapStartDateFallback

    /// Goal with nil creationDate + 1 event 10 days ago → heatmapStartDate falls back to event date.
    /// Goal with nil creationDate + no events → heatmapStartDate falls back to 90 days ago.
    func testHeatmapStartDateFallback() throws {
        let context = ModelContext(container)

        // Create goal; then override creationDate to nil (init sets it to Date())
        let goal = Goal(title: "Heatmap Fallback Goal")
        context.insert(goal)
        goal.creationDate = nil  // Force nil to test fallback chain

        // Create event 10 days before today
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let event = CompletionEvent(goal: goal)
        event.completedAt = tenDaysAgo
        context.insert(event)

        viewModel.refresh(events: [event], goals: [goal], frozenDates: [])

        // heatmapDataByGoal should have data for this goal
        let goalKey = goal.id.uuidString
        XCTAssertNotNil(viewModel.heatmapDataByGoal[goalKey], "heatmapDataByGoal must have entry for goal")

        // heatmapStartDate should fall back to the event's completedAt date (not creationDate)
        let startDate = viewModel.heatmapStartDate(for: goal)
        let startOfEventDay = Calendar.current.startOfDay(for: tenDaysAgo)
        let startOfHeatmapStartDate = Calendar.current.startOfDay(for: startDate)

        XCTAssertEqual(
            startOfHeatmapStartDate,
            startOfEventDay,
            "With nil creationDate, heatmapStartDate must fall back to earliest event date"
        )

        // Verify 90-day fallback: goal with no events and nil creationDate
        let emptyGoal = Goal(title: "Empty Goal")
        context.insert(emptyGoal)
        emptyGoal.creationDate = nil

        viewModel.refresh(events: [], goals: [emptyGoal], frozenDates: [])

        let fallbackStart = viewModel.heatmapStartDate(for: emptyGoal)
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!

        // Allow a 1-second tolerance for test execution time
        XCTAssertEqual(
            fallbackStart.timeIntervalSinceReferenceDate,
            ninetyDaysAgo.timeIntervalSinceReferenceDate,
            accuracy: 2.0,
            "With nil creationDate and no events, heatmapStartDate must fall back to 90 days ago"
        )
    }

    // MARK: - testAllGoalsIncluded

    /// 2 active goals + 1 completed goal → allGoals.count == 3 after refresh.
    func testAllGoalsIncluded() throws {
        let context = ModelContext(container)

        let activeGoal1 = Goal(title: "Active Goal 1", tier: .immediate)
        let activeGoal2 = Goal(title: "Active Goal 2", tier: .shortTerm)
        let completedGoal = Goal(title: "Completed Goal", tier: .longTerm)

        // Mark the third goal as completed
        completedGoal.isCompleted = true

        context.insert(activeGoal1)
        context.insert(activeGoal2)
        context.insert(completedGoal)

        // Create one event for the active goal to verify goals without events are also included
        let event = CompletionEvent(goal: activeGoal1)
        event.completedAt = Date()
        context.insert(event)

        viewModel.refresh(
            events: [event],
            goals: [activeGoal1, activeGoal2, completedGoal],
            frozenDates: []
        )

        XCTAssertEqual(viewModel.allGoals.count, 3, "allGoals must include active and completed goals (D-08)")

        let ids = Set(viewModel.allGoals.map { $0.id })
        XCTAssertTrue(ids.contains(activeGoal1.id), "allGoals must include activeGoal1")
        XCTAssertTrue(ids.contains(activeGoal2.id), "allGoals must include activeGoal2 (no events)")
        XCTAssertTrue(ids.contains(completedGoal.id), "allGoals must include completedGoal")
    }
}
