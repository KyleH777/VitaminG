import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class StreakEngineTests: XCTestCase {
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

    /// Creates a CompletionEvent with completedAt = today + dayOffset.
    private func makeEvent(dayOffset: Int, tier: GoalTier = .immediate) -> CompletionEvent {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let date = cal.date(byAdding: .day, value: dayOffset, to: today)!
        let goal = Goal(title: "Test Goal", tier: tier)
        context.insert(goal)
        let event = CompletionEvent(goal: goal)
        event.completedAt = date
        event.tierRawValue = tier.rawValue
        context.insert(event)
        return event
    }

    // MARK: - Test 1: Empty events returns zero streak

    func test_emptyEvents_returnsZeroStreak() {
        let streak = StreakEngine.currentStreak(from: [], tier: nil)
        XCTAssertEqual(streak, 0, "Empty events should return 0 streak")
    }

    // MARK: - Test 2: Single event today returns streak of 1

    func test_singleEventToday_returnsOneStreak() {
        let event = makeEvent(dayOffset: 0)
        let streak = StreakEngine.currentStreak(from: [event], tier: nil)
        XCTAssertEqual(streak, 1, "One event today should return streak of 1")
    }

    // MARK: - Test 3: Consecutive days returns correct streak count

    func test_consecutiveDays_returnsCorrectStreak() {
        let e1 = makeEvent(dayOffset: 0)   // today
        let e2 = makeEvent(dayOffset: -1)  // yesterday
        let e3 = makeEvent(dayOffset: -2)  // day before
        let streak = StreakEngine.currentStreak(from: [e1, e2, e3], tier: nil)
        XCTAssertEqual(streak, 3, "Three consecutive days should return streak of 3")
    }

    // MARK: - Test 4: Gap breaks streak

    func test_gapBreaksStreak() {
        let e1 = makeEvent(dayOffset: 0)   // today
        let e2 = makeEvent(dayOffset: -3)  // 3 days ago — gap
        let streak = StreakEngine.currentStreak(from: [e1, e2], tier: nil)
        XCTAssertEqual(streak, 1, "Gap of 2 days should break streak — only today counts")
    }

    // MARK: - Test 5: Per-tier streak filters correctly

    func test_perTierStreak_filtersCorrectly() {
        let e1 = makeEvent(dayOffset: 0, tier: .immediate)   // today, immediate
        let e2 = makeEvent(dayOffset: -1, tier: .immediate)  // yesterday, immediate
        let e3 = makeEvent(dayOffset: -2, tier: .longTerm)   // day before, longTerm

        // .immediate streak should be 2 (today + yesterday only)
        let immediateStreak = StreakEngine.currentStreak(from: [e1, e2, e3], tier: .immediate)
        XCTAssertEqual(immediateStreak, 2, "Immediate tier streak should be 2 (only immediate events)")

        // .longTerm streak should be 1 (day before, but today and yesterday have no longTerm)
        // Since today is not in the set, walk back to yesterday — no longTerm. Walk back to day before — found.
        // Actually: today has no .longTerm, so candidate = yesterday; yesterday has no .longTerm, streak stays 0
        // Wait: the algorithm steps to yesterday if today is empty, then counts from there.
        // Yesterday has no .longTerm event, so streak is 0... unless day-2 is consecutive from yesterday.
        // But yesterday is also not in set, so streak = 0.
        let longTermStreak = StreakEngine.currentStreak(from: [e1, e2, e3], tier: .longTerm)
        XCTAssertEqual(longTermStreak, 0, "LongTerm streak should be 0 since yesterday has no longTerm event to anchor from")
    }

    // MARK: - Test 6: Global streak ignores tier

    func test_globalStreak_ignoresTier() {
        let e1 = makeEvent(dayOffset: 0, tier: .immediate)   // today
        let e2 = makeEvent(dayOffset: -1, tier: .shortTerm)  // yesterday, different tier
        let e3 = makeEvent(dayOffset: -2, tier: .longTerm)   // day before, different tier

        let streak = StreakEngine.currentStreak(from: [e1, e2, e3], tier: nil)
        XCTAssertEqual(streak, 3, "Global streak should count all tiers across consecutive days")
    }

    // MARK: - Test 7: Multiple same-day events count as one day

    func test_multipleSameDayEvents_countAsOneDay() {
        let e1 = makeEvent(dayOffset: 0)
        let e2 = makeEvent(dayOffset: 0)
        let e3 = makeEvent(dayOffset: 0)

        let streak = StreakEngine.currentStreak(from: [e1, e2, e3], tier: nil)
        XCTAssertEqual(streak, 1, "Three events on same day should count as one day (streak = 1)")
    }

    // MARK: - Test 8: Nil completedAt events are skipped

    func test_nilCompletedAt_skipped() {
        let e1 = makeEvent(dayOffset: 0)
        // Create event with nil completedAt
        let goal = Goal(title: "No Date Goal", tier: .immediate)
        context.insert(goal)
        let nilEvent = CompletionEvent(goal: goal)
        nilEvent.completedAt = nil
        context.insert(nilEvent)

        let streak = StreakEngine.currentStreak(from: [e1, nilEvent], tier: nil)
        XCTAssertEqual(streak, 1, "Events with nil completedAt should be ignored; today's event gives streak of 1")
    }

    // MARK: - Test 9: DST-safe — uses Calendar.startOfDay

    func test_dstSafe_usesCalendarStartOfDay() {
        // Inject a Calendar with a specific timezone known for DST transitions
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!

        // Create events representing consecutive days in this timezone
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        let goal1 = Goal(title: "Goal DST 1", tier: .immediate)
        let goal2 = Goal(title: "Goal DST 2", tier: .immediate)
        context.insert(goal1)
        context.insert(goal2)

        let e1 = CompletionEvent(goal: goal1)
        e1.completedAt = today
        e1.tierRawValue = GoalTier.immediate.rawValue
        context.insert(e1)

        let e2 = CompletionEvent(goal: goal2)
        e2.completedAt = yesterday
        e2.tierRawValue = GoalTier.immediate.rawValue
        context.insert(e2)

        let streak = StreakEngine.currentStreak(from: [e1, e2], tier: nil, calendar: cal)
        XCTAssertEqual(streak, 2, "DST-safe calendar injection should return streak of 2 for today + yesterday")
    }

    // MARK: - Test 10: Completion rate per tier

    func test_completionRate_perTier() {
        // 3 immediate goals, 2 have completion events
        let g1 = Goal(title: "Goal A", tier: .immediate)
        let g2 = Goal(title: "Goal B", tier: .immediate)
        let g3 = Goal(title: "Goal C", tier: .immediate)
        context.insert(g1)
        context.insert(g2)
        context.insert(g3)

        let e1 = CompletionEvent(goal: g1)
        e1.completedAt = Date()
        context.insert(e1)
        let e2 = CompletionEvent(goal: g2)
        e2.completedAt = Date()
        context.insert(e2)
        // g3 has no completion event

        let rate = StreakEngine.completionRate(events: [e1, e2], totalGoals: 3, tier: nil)
        XCTAssertEqual(rate, 2.0 / 3.0, accuracy: 0.001, "Completion rate should be 2/3")
    }

    // MARK: - Test 12: bestStreak returns longest consecutive run

    func test_bestStreak_returnsLongestConsecutiveRun() {
        let cal = Calendar.current
        var events: [CompletionEvent] = []
        let stubGoal = Goal(title: "Streak Goal", tier: .immediate)
        context.insert(stubGoal)
        for day in [1, 2, 3, 7, 8, 9, 10] {
            var comps = DateComponents()
            comps.year = 2026; comps.month = 1; comps.day = day
            let e = CompletionEvent(goal: stubGoal)
            e.completedAt = cal.date(from: comps)
            context.insert(e)
            events.append(e)
        }
        let best = StreakEngine.bestStreak(events: events)
        XCTAssertEqual(best, 4)
    }

    // MARK: - Test 13: bestStreak with empty events returns zero

    func test_bestStreak_emptyEvents_returnsZero() {
        XCTAssertEqual(StreakEngine.bestStreak(events: []), 0)
    }

    // MARK: - Test 11: Today with no completion — yesterday's streak is alive

    func test_todayWithNoCompletion_yesterdayStreakAlive() {
        let e1 = makeEvent(dayOffset: -1)  // yesterday
        let e2 = makeEvent(dayOffset: -2)  // day before

        // No event today — but streak should reflect yesterday's chain (day isn't over)
        let streak = StreakEngine.currentStreak(from: [e1, e2], tier: nil)
        XCTAssertEqual(streak, 2, "No event today, but yesterday + day-before consecutive = streak of 2 (day isn't over)")
    }
}
