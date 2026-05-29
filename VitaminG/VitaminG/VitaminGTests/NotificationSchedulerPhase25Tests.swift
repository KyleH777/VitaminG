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
    // RED until Plan 02 adds makeContent(activeGoals:currentStreak:) + copy bank statics.

    func test_makeContent_celebratoryCopy_whenStreakGe7() throws {
        // RED scaffold: makeContent(activeGoals:currentStreak:) and celebratoryCopy
        // do not exist yet — added by Plan 02.
        // When GREEN: call scheduler.makeContent(activeGoals: [goal], currentStreak: 7)
        // and assert content.body.hasPrefix one of NotificationScheduler.celebratoryCopy.
        XCTFail("Plan 02 required: makeContent(activeGoals:currentStreak:) and celebratoryCopy not yet implemented")
    }

    func test_makeContent_neutralBuildingCopy_whenStreak1To6() throws {
        // RED scaffold: Plan 02 required.
        // When GREEN: currentStreak=3, assert body prefix in neutralBuildingCopy.
        XCTFail("Plan 02 required: makeContent(activeGoals:currentStreak:) and neutralBuildingCopy not yet implemented")
    }

    func test_makeContent_encouragingCopy_whenStreak0() throws {
        // RED scaffold: Plan 02 required.
        // When GREEN: currentStreak=0, assert body prefix in encouragingCopy.
        XCTFail("Plan 02 required: makeContent(activeGoals:currentStreak:) and encouragingCopy not yet implemented")
    }

    // MARK: - NOTIF-02: Goal-Title Injection Tests
    // RED until Plan 02 adds multi-goal support to makeContent.

    func test_makeContent_twoGoalTitles() throws {
        // RED scaffold: Plan 02 required.
        // When GREEN: 2 active goals "Goal A"/"Goal B", currentStreak=3.
        // Assert content.body.contains("\nGoal A") AND content.body.contains("\nGoal B").
        XCTFail("Plan 02 required: makeContent(activeGoals:currentStreak:) with 2-title injection not yet implemented")
    }

    func test_makeContent_singleGoal() throws {
        // RED scaffold: Plan 02 required.
        // When GREEN: 1 active goal "Goal A", currentStreak=3.
        // Assert body contains "\nGoal A" and body.components(separatedBy:"\n").count - 1 == 1.
        XCTFail("Plan 02 required: makeContent(activeGoals:currentStreak:) single-goal body not yet implemented")
    }

    func test_makeContent_noActiveGoals_bodyIsToneMessageOnly() throws {
        // RED scaffold: Plan 02 required.
        // When GREEN: empty activeGoals, currentStreak=0.
        // Assert body equals a message from encouragingCopy exactly (no trailing newline).
        XCTFail("Plan 02 required: makeContent(activeGoals:currentStreak:) no-goals body not yet implemented")
    }

    // MARK: - NOTIF-04: One-Shot 7 PM Tests
    // RED until Plan 02 adds scheduleOneShotStreakAtRisk(activeGoals:streak:pendingCount:).

    func test_schedule_oneShotStreakAtRisk_repeats_false() async throws {
        // RED scaffold: Plan 02 required.
        // When GREEN:
        //   await scheduler.scheduleOneShotStreakAtRisk(activeGoals: [], streak: 3, pendingCount: 0)
        //   let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        //   let request = pending.first { $0.identifier == NotificationScheduler.globalStreakAtRiskIdentifier }
        //   try XCTSkipIf(request == nil, "Notification permission not granted — skip trigger assertion")
        //   guard let trigger = request?.trigger as? UNCalendarNotificationTrigger else {
        //       return XCTFail("Expected UNCalendarNotificationTrigger")
        //   }
        //   XCTAssertFalse(trigger.repeats, "One-shot 7 PM alert must have repeats: false")
        //   XCTAssertEqual(trigger.dateComponents.hour, 19)
        //   XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTFail("Plan 02 required: scheduleOneShotStreakAtRisk(activeGoals:streak:pendingCount:) not yet implemented")
    }

    func test_schedule_oneShotSkipped_atCapBoundary() async {
        // RED scaffold: Plan 02 required.
        // When GREEN:
        //   await scheduler.scheduleOneShotStreakAtRisk(activeGoals: [], streak: 5, pendingCount: 60)
        //   let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        //   let nudgeAdded = pending.contains {
        //       $0.identifier == NotificationScheduler.globalStreakAtRiskIdentifier
        //   }
        //   XCTAssertFalse(nudgeAdded, "Cap guard should prevent one-shot when pendingCount >= 60")
        XCTFail("Plan 02 required: scheduleOneShotStreakAtRisk cap guard not yet implemented")
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
