import XCTest
import SwiftData
@testable import VitaminG

/// Wave 1 GREEN-phase tests for ProgressViewModel.
///
/// All 11 test methods use real assertions against ProgressViewModel.
/// XCTSkipIf stubs from Wave 0 (plan 01) have been replaced.
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
        let goal = Goal(title: "Empty", tier: .immediate)
        context.insert(goal)
        let vm = ProgressViewModel()
        let progress = vm.ringProgress(for: goal, events: [])
        XCTAssertEqual(progress, 0.0, accuracy: 0.001, "0 events should yield 0.0 ring progress")
    }

    func testRingProgressPartial() throws {
        let goal = Goal(title: "Partial", tier: .immediate)
        context.insert(goal)
        let e1 = makeEvent(daysAgo: 0, goal: goal)
        let e2 = makeEvent(daysAgo: 2, goal: goal)
        let e3 = makeEvent(daysAgo: 5, goal: goal)
        let vm = ProgressViewModel()
        let progress = vm.ringProgress(for: goal, events: [e1, e2, e3])
        XCTAssertEqual(progress, 3.0 / 7.0, accuracy: 0.001, "3 events in 7-day window should yield 3/7")
    }

    func testRingProgressFullWeek() throws {
        let goal = Goal(title: "Full", tier: .immediate)
        context.insert(goal)
        var events: [CompletionEvent] = []
        for day in 0...6 {
            events.append(makeEvent(daysAgo: day, goal: goal))
        }
        // Add an 8th event today to trigger the clamp
        events.append(makeEvent(daysAgo: 0, goal: goal))
        let vm = ProgressViewModel()
        let progress = vm.ringProgress(for: goal, events: events)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001, "8 events in 7-day window should clamp to 1.0")
    }

    func testRingProgressCompletedGoalAlwaysFull() throws {
        let goal = Goal(title: "Completed", tier: .immediate)
        goal.completed = true
        context.insert(goal)
        let vm = ProgressViewModel()
        let progress = vm.ringProgress(for: goal, events: [])
        XCTAssertEqual(progress, 1.0, accuracy: 0.001, "Completed goal should return 1.0 even with 0 events (D-02)")
    }

    // MARK: - PROG-02: chartData

    func testChartDataReturns30Days() throws {
        let goal = Goal(title: "Chart", tier: .immediate)
        context.insert(goal)
        let vm = ProgressViewModel()
        let data = vm.chartData(for: goal, events: [])
        XCTAssertEqual(data.count, 30, "chartData must return exactly 30 DayCount items")
        // Oldest-first: data[0].date < data[29].date
        XCTAssertLessThan(data.first!.date, data.last!.date, "Data should be ordered oldest-first")
    }

    func testChartDataFiltersToGoal() throws {
        let goalA = Goal(title: "A", tier: .immediate)
        let goalB = Goal(title: "B", tier: .immediate)
        context.insert(goalA)
        context.insert(goalB)
        let eA = makeEvent(daysAgo: 1, goal: goalA)
        let eB1 = makeEvent(daysAgo: 1, goal: goalB)
        let eB2 = makeEvent(daysAgo: 2, goal: goalB)
        let vm = ProgressViewModel()
        let dataA = vm.chartData(for: goalA, events: [eA, eB1, eB2])
        let totalA = dataA.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalA, 1, "Goal A's chart should reflect only its own 1 event")
        let dataB = vm.chartData(for: goalB, events: [eA, eB1, eB2])
        let totalB = dataB.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalB, 2, "Goal B's chart should reflect only its own 2 events")
    }

    // MARK: - PROG-03: milestoneJustCrossed

    func testMilestoneJustCrossedAtThreshold() throws {
        let id = UUID()
        let vm = ProgressViewModel()
        XCTAssertEqual(vm.milestoneJustCrossed(count: 5, firedSet: [], goalID: id), 5)
        XCTAssertEqual(vm.milestoneJustCrossed(count: 10, firedSet: [], goalID: id), 10)
        XCTAssertEqual(vm.milestoneJustCrossed(count: 25, firedSet: [], goalID: id), 25)
        XCTAssertEqual(vm.milestoneJustCrossed(count: 50, firedSet: [], goalID: id), 50)
    }

    func testMilestoneJustCrossedAlreadyFired() throws {
        let id = UUID()
        let firedKey = "\(id.uuidString)-5"
        let vm = ProgressViewModel()
        XCTAssertNil(vm.milestoneJustCrossed(count: 5, firedSet: [firedKey], goalID: id),
                     "Already-fired threshold must return nil")
    }

    func testMilestoneJustCrossedNoMatch() throws {
        let id = UUID()
        let vm = ProgressViewModel()
        XCTAssertNil(vm.milestoneJustCrossed(count: 4, firedSet: [], goalID: id))
        XCTAssertNil(vm.milestoneJustCrossed(count: 11, firedSet: [], goalID: id))
        XCTAssertNil(vm.milestoneJustCrossed(count: 99, firedSet: [], goalID: id))
    }

    // MARK: - PROG-04: momentumScore

    func testMomentumScoreZeroEvents() throws {
        let goal = Goal(title: "Empty", tier: .immediate)
        context.insert(goal)
        let vm = ProgressViewModel()
        let score = vm.momentumScore(for: goal, events: [])
        XCTAssertEqual(score, 0.0, accuracy: 0.001, "0 events should yield 0.0 momentum")
    }

    func testMomentumScoreExcludesOldEvents() throws {
        let goal = Goal(title: "Mixed", tier: .immediate)
        context.insert(goal)
        let oldA = makeEvent(daysAgo: 10, goal: goal)
        let oldB = makeEvent(daysAgo: 12, goal: goal)
        let recent1 = makeEvent(daysAgo: 1, goal: goal)
        let recent2 = makeEvent(daysAgo: 2, goal: goal)
        let recent3 = makeEvent(daysAgo: 3, goal: goal)
        let vm = ProgressViewModel()
        let score = vm.momentumScore(for: goal, events: [oldA, oldB, recent1, recent2, recent3])
        XCTAssertEqual(score, 3.0 / 7.0, accuracy: 0.001, "Only the 3 recent events count; old ones excluded")
    }
}
