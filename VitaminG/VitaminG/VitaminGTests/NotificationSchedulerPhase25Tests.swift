import XCTest
import UserNotifications
import SwiftData
@testable import VitaminG

// MARK: - NotificationSchedulerPhase25Tests
//
// Phase 25 TDD scaffold for NOTIF-01 through NOTIF-04.
// RED scaffold: 6 NOTIF-03 helper tests pass after Task 1; 8 scheduler-side tests
// turn GREEN when Plan 02 adds the new makeContent(activeGoals:currentStreak:) and
// scheduleOneShotStreakAtRisk signatures to NotificationScheduler.

@MainActor
final class NotificationSchedulerPhase25Tests: XCTestCase {

    private var container: ModelContainer!
    private let scheduler = NotificationScheduler.shared

    override func setUp() async throws {
        try await super.setUp()
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        clearAppGroupKeys()
    }

    override func tearDown() async throws {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        clearAppGroupKeys()
        container = nil
        try await super.tearDown()
    }

    // MARK: - Test Isolation Helper

    private func clearAppGroupKeys() {
        let suite = UserDefaults(suiteName: NotificationPreferences.suiteName)
        suite?.removeObject(forKey: NotificationPreferences.checkInHourHistoryKey)
        suite?.removeObject(forKey: NotificationPreferences.nudgeSuggestionDismissedKey)
    }

    // MARK: - NOTIF-01: Tone Selection Tests

    func test_makeContent_celebratoryCopy_whenStreakGe7() throws {
        let context = ModelContext(container)
        let goal = Goal(title: "Goal A", tier: .immediate)
        context.insert(goal)

        let content = scheduler.makeContent(activeGoals: [goal], currentStreak: 7)
        XCTAssertTrue(
            NotificationScheduler.celebratoryCopy.contains { content.body.hasPrefix($0) },
            "streak >= 7 should select from celebratoryCopy bank"
        )
    }

    func test_makeContent_neutralBuildingCopy_whenStreak1To6() throws {
        let context = ModelContext(container)
        let goal = Goal(title: "Goal A", tier: .immediate)
        context.insert(goal)

        let content = scheduler.makeContent(activeGoals: [goal], currentStreak: 3)
        XCTAssertTrue(
            NotificationScheduler.neutralBuildingCopy.contains { content.body.hasPrefix($0) },
            "streak 1..6 should select from neutralBuildingCopy bank"
        )
    }

    func test_makeContent_encouragingCopy_whenStreak0() throws {
        let context = ModelContext(container)
        let goal = Goal(title: "Goal A", tier: .immediate)
        context.insert(goal)

        let content = scheduler.makeContent(activeGoals: [goal], currentStreak: 0)
        XCTAssertTrue(
            NotificationScheduler.encouragingCopy.contains { content.body.hasPrefix($0) },
            "streak 0 should select from encouragingCopy bank"
        )
    }

    // MARK: - NOTIF-02: Goal-Title Injection Tests

    func test_makeContent_twoGoalTitles() throws {
        let context = ModelContext(container)
        let goalA = Goal(title: "Goal A", tier: .immediate)
        let goalB = Goal(title: "Goal B", tier: .shortTerm)
        context.insert(goalA)
        context.insert(goalB)

        let content = scheduler.makeContent(activeGoals: [goalA, goalB], currentStreak: 3)
        XCTAssertTrue(content.body.contains("\nGoal A"), "Body should contain Goal A after tone message newline")
        XCTAssertTrue(content.body.contains("\nGoal B"), "Body should contain Goal B as second goal title")
    }

    func test_makeContent_singleGoal() throws {
        let context = ModelContext(container)
        let goalA = Goal(title: "Goal A", tier: .immediate)
        context.insert(goalA)

        let content = scheduler.makeContent(activeGoals: [goalA], currentStreak: 3)
        XCTAssertTrue(content.body.contains("\nGoal A"), "Single-goal body should contain goal title after newline")
        let newlineCount = content.body.components(separatedBy: "\n").count - 1
        XCTAssertEqual(newlineCount, 1, "Single-goal body should have exactly one newline (message + one title)")
    }

    func test_makeContent_noActiveGoals_bodyIsToneMessageOnly() throws {
        let content = scheduler.makeContent(activeGoals: [], currentStreak: 0)
        XCTAssertTrue(
            NotificationScheduler.encouragingCopy.contains(content.body),
            "No-goals body should exactly match an encouragingCopy message (no trailing newline)"
        )
        XCTAssertFalse(content.body.contains("\n"), "No-goals body should contain no newlines")
    }

    // MARK: - NOTIF-04: One-Shot 7 PM Tests

    func test_schedule_oneShotStreakAtRisk_repeats_false() async throws {
        // Pass currentHour: 8 so the time-of-day guard never fires regardless of wall-clock time (WR-02).
        await scheduler.scheduleOneShotStreakAtRisk(activeGoals: [], streak: 3, pendingCount: 0, currentHour: 8)

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let request = pending.first { $0.identifier == NotificationScheduler.globalStreakAtRiskIdentifier }
        try XCTSkipIf(request == nil, "Notification permission not granted in test environment — skip trigger assertion")
        guard let trigger = request?.trigger as? UNCalendarNotificationTrigger else {
            return XCTFail("Expected UNCalendarNotificationTrigger for one-shot 7 PM alert")
        }
        XCTAssertFalse(trigger.repeats, "One-shot 7 PM alert must have repeats: false")
        XCTAssertEqual(trigger.dateComponents.hour, 19, "One-shot trigger hour should be 19")
        XCTAssertEqual(trigger.dateComponents.minute, 0, "One-shot trigger minute should be 0")
    }

    func test_schedule_oneShotSkipped_atCapBoundary() async {
        // Pass currentHour: 8 so the time guard doesn't fire — only cap guard should prevent scheduling (WR-02).
        await scheduler.scheduleOneShotStreakAtRisk(activeGoals: [], streak: 5, pendingCount: 60, currentHour: 8)

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let nudgeAdded = pending.contains {
            $0.identifier == NotificationScheduler.globalStreakAtRiskIdentifier
        }
        XCTAssertFalse(nudgeAdded, "Cap guard should prevent one-shot when pendingCount >= 60")
    }

    // MARK: - NOTIF-03: Pure Helper Tests (pass after Task 1)

    func test_appendCheckInHour_fifo14() {
        // Append 15 entries (hours 0..14); verify FIFO drops oldest (0) and keeps last 14 (1..14).
        for hour in 0..<15 {
            NotificationPreferences.appendCheckInHour(hour)
        }
        let history = NotificationPreferences.checkInHourHistory()
        XCTAssertEqual(history.count, 14, "appendCheckInHour must keep at most 14 entries (FIFO)")
        XCTAssertEqual(history.first, 1, "Oldest entry (0) should have been dropped; first entry should be 1")
    }

    func test_modalHour_returnsMode() {
        // Seed [8, 8, 9, 8, 9] — mode is 8.
        for hour in [8, 8, 9, 8, 9] {
            NotificationPreferences.appendCheckInHour(hour)
        }
        let modal = NotificationPreferences.modalCheckInHour()
        XCTAssertEqual(modal, 8, "Modal of [8, 8, 9, 8, 9] should be 8 (appears 3 times)")
    }

    func test_modalHour_tieBreakByFirstOccurrence() {
        // Seed [9, 8, 9, 8] — 9 and 8 each appear twice; 9 appears first at index 0.
        for hour in [9, 8, 9, 8] {
            NotificationPreferences.appendCheckInHour(hour)
        }
        let modal = NotificationPreferences.modalCheckInHour()
        XCTAssertEqual(modal, 9, "Tie between 9 and 8: 9 appears at earlier index, so 9 wins")
    }

    func test_modalHour_filtersOutOfRange() {
        // Seed [25, -1, 8, 8] — 25 and -1 are out of valid range (0...23) and must be filtered.
        // After filtering: [8, 8] — mode is 8.
        for hour in [25, -1, 8, 8] {
            NotificationPreferences.appendCheckInHour(hour)
        }
        let modal = NotificationPreferences.modalCheckInHour()
        XCTAssertEqual(modal, 8, "Out-of-range values (25, -1) must be filtered before modal computation")
    }

    func test_nudgeSuggestionDismissed_defaultsFalse() {
        // clearAppGroupKeys() in setUp ensures the key is absent.
        XCTAssertFalse(
            NotificationPreferences.nudgeSuggestionDismissed,
            "nudgeSuggestionDismissed should default to false when key is absent"
        )
    }

    func test_markNudgeSuggestionDismissed_setsTrue() {
        NotificationPreferences.markNudgeSuggestionDismissed()
        XCTAssertTrue(
            NotificationPreferences.nudgeSuggestionDismissed,
            "markNudgeSuggestionDismissed() must flip nudgeSuggestionDismissed to true"
        )
    }
}
