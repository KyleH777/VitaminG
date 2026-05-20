// Phase 18 Wave 0 — RED tests. Will go GREEN as Plan 02 lands implementation.
// Tests HOME-01 (overall app streak uses StreakEngine) and GOAL2-05 (flame threshold at 3 consecutive days).

import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class Phase18StreakEngineTests: XCTestCase {

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

    private func makeEvent(dayOffset: Int, goal: Goal? = nil) -> CompletionEvent {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let date = cal.date(byAdding: .day, value: dayOffset, to: today)!
        let targetGoal: Goal
        if let g = goal {
            targetGoal = g
        } else {
            targetGoal = Goal(title: "Test Goal", tier: .immediate)
            context.insert(targetGoal)
        }
        let event = CompletionEvent(goal: targetGoal)
        event.completedAt = date
        event.tierRawValue = GoalTier.immediate.rawValue
        context.insert(event)
        return event
    }

    // MARK: - HOME-01: Overall app streak uses StreakEngine not max event count

    /// HOME-01: Given Goal A with 47 sporadic non-consecutive events and Goal B with 3 consecutive
    /// recent events, `StreakEngine.currentStreak(from: allEvents)` must return 3 (the consecutive
    /// day count), NOT 47 (the raw event count). Tests the streak source fix.
    func test_overallAppStreak_usesStreakEngineNotMaxCount() {
        // Goal A: 47 sporadic events spread across non-consecutive days over the past 90 days
        // (every other day so there's no consecutive run)
        let goalA = Goal(title: "Sporadic Goal A", tier: .immediate)
        context.insert(goalA)
        var allEvents: [CompletionEvent] = []
        // Create 47 events on alternating days starting from -94 days ago (every 2 days = no streak)
        for i in 0..<47 {
            let offset = -(i * 2 + 5) // starts 5 days ago, going back in steps of 2
            let event = makeEvent(dayOffset: offset, goal: goalA)
            allEvents.append(event)
        }

        // Goal B: 3 consecutive recent events ending today
        let goalB = Goal(title: "Consistent Goal B", tier: .immediate)
        context.insert(goalB)
        for offset in [0, -1, -2] {
            let event = makeEvent(dayOffset: offset, goal: goalB)
            allEvents.append(event)
        }

        let streak = StreakEngine.currentStreak(from: allEvents)

        // The streak must be the consecutive-day count (3), NOT the event count (47 or 50)
        XCTAssertEqual(streak, 3,
            "HOME-01: StreakEngine must return consecutive days (3), not event count (\(allEvents.count))")
        XCTAssertNotEqual(streak, allEvents.count,
            "HOME-01: Streak must NOT equal the total event count — that would be the broken pre-fix behavior")
    }

    // MARK: - GOAL2-05: Flame display gating

    /// GOAL2-05: Events from 5 days ago through 2 days ago (gap — no event today or yesterday)
    /// should return streak of 0. Tests that flame is gated off when streak is broken.
    func test_perGoalStreak_returnsZeroForFutureGap() {
        let goal = Goal(title: "Gap Goal", tier: .immediate)
        context.insert(goal)

        // Events from 5 days ago to 2 days ago — no event today or yesterday
        var events: [CompletionEvent] = []
        for offset in [-5, -4, -3, -2] {
            events.append(makeEvent(dayOffset: offset, goal: goal))
        }

        let streak = StreakEngine.currentStreak(from: events)

        XCTAssertEqual(streak, 0,
            "GOAL2-05: No event today or yesterday — streak should be 0 (flame must NOT show)")
    }

    /// GOAL2-05: Three consecutive events ending today should return streak >= 3.
    /// Flame threshold is 3 — test confirms the threshold condition is met.
    func test_perGoalStreak_returnsAtLeast3_whenThreeConsecutiveDaysEndingToday() {
        let goal = Goal(title: "Streak Goal", tier: .immediate)
        context.insert(goal)

        var events: [CompletionEvent] = []
        for offset in [0, -1, -2] {
            events.append(makeEvent(dayOffset: offset, goal: goal))
        }

        let streak = StreakEngine.currentStreak(from: events)

        XCTAssertGreaterThanOrEqual(streak, 3,
            "GOAL2-05: Three consecutive days ending today must produce streak >= 3 (flame threshold met)")
    }

    /// GOAL2-05: Only two consecutive events (today + yesterday) must return a streak < 3.
    /// Flame must NOT display when streak is below the threshold of 3.
    func test_perGoalStreak_returnsLessThan3_whenOnlyTwoConsecutiveDays() {
        let goal = Goal(title: "Two Day Goal", tier: .immediate)
        context.insert(goal)

        var events: [CompletionEvent] = []
        for offset in [0, -1] {
            events.append(makeEvent(dayOffset: offset, goal: goal))
        }

        let streak = StreakEngine.currentStreak(from: events)

        XCTAssertLessThan(streak, 3,
            "GOAL2-05: Only two consecutive days — streak must be < 3 (flame must NOT show at threshold)")
        XCTAssertEqual(streak, 2,
            "GOAL2-05: Two consecutive days should return exactly 2")
    }
}
