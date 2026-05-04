import XCTest
import SwiftData
@testable import VitaminG

/// Wave 0 RED-phase scaffolding for ProgressViewModel.
///
/// All test methods skip in Wave 0 (ProgressViewModel does not yet exist).
/// Wave 1 plan 02 implements ProgressViewModel and replaces every XCTSkipIf+XCTFail
/// with real assertions against the shape:
///   - ringProgress(for:events:) -> Double
///   - momentumScore(for:events:) -> Double
///   - chartData(for:events:) -> [DayCount]
///   - milestoneJustCrossed(count:firedSet:goalID:) -> Int?
///
/// Coverage map (per .planning/phases/12-goal-progress-visualization/12-VALIDATION.md):
///   PROG-01: tests 1–4
///   PROG-02: tests 5–6
///   PROG-03: tests 7–9
///   PROG-04: tests 10–11
@MainActor
final class ProgressViewModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - Helpers

    /// Creates a CompletionEvent on a fresh Goal at today + dayOffset.
    private func makeEvent(daysAgo: Int, tier: GoalTier = .immediate) -> CompletionEvent {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
        let goal = Goal(title: "Test Goal", tier: tier)
        context.insert(goal)
        let event = CompletionEvent(goal: goal)
        event.completedAt = date
        event.tierRawValue = tier.rawValue
        context.insert(event)
        return event
    }

    /// Creates a CompletionEvent on the supplied Goal at today + dayOffset.
    private func makeEvent(daysAgo: Int, goal: Goal, tier: GoalTier = .immediate) -> CompletionEvent {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
        let event = CompletionEvent(goal: goal)
        event.completedAt = date
        event.tierRawValue = tier.rawValue
        context.insert(event)
        return event
    }

    // MARK: - PROG-01: ringProgress

    func testRingProgressZeroEvents() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: ringProgress returns 0.0 for goal with no events")
    }

    func testRingProgressPartial() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: 3 events in last 7 days returns 3.0/7.0 (accuracy 0.001)")
    }

    func testRingProgressFullWeek() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: 8 events in last 7 days returns 1.0 (clamped)")
    }

    func testRingProgressCompletedGoalAlwaysFull() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: goal.completed=true returns 1.0 even with 0 events (per D-02)")
    }

    // MARK: - PROG-02: chartData

    func testChartDataReturns30Days() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: chartData returns exactly 30 DayCount items, oldest-first")
    }

    func testChartDataFiltersToGoal() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: events on Goal A excluded from chartData(for: Goal B)")
    }

    // MARK: - PROG-03: milestoneJustCrossed

    func testMilestoneJustCrossedAtThreshold() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: count=5/10/25/50 with empty firedSet returns the matching threshold")
    }

    func testMilestoneJustCrossedAlreadyFired() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: count=5 with firedSet containing \"{goalID}-5\" returns nil")
    }

    func testMilestoneJustCrossedNoMatch() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: count=4, count=11, count=99 all return nil")
    }

    // MARK: - PROG-04: momentumScore

    func testMomentumScoreZeroEvents() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: momentumScore returns 0.0 with no events")
    }

    func testMomentumScoreExcludesOldEvents() throws {
        try XCTSkipIf(true, "Wave 1 will implement ProgressViewModel")
        XCTFail("Wave 1 must verify: 2 events at daysAgo=10 + 3 events at daysAgo=2 returns 3.0/7.0 (accuracy 0.001)")
    }
}
