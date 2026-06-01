import XCTest
import UserNotifications
@testable import VitaminG

final class Phase23NotificationTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Ensure a clean notification center slate before each test so prior-test
        // pending notifications cannot cause false negatives (CR-05 fix).
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    override func tearDown() async throws {
        // Clean up after each test so we don't pollute the notification center for
        // subsequent tests in the suite.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        try await super.tearDown()
    }

    // MARK: - test_scheduleOneShotStreakAtRisk_respectsCapGuard
    //
    // When pending count is already at or above 60, scheduleOneShotStreakAtRisk(pendingCount:)
    // must return early and NOT attempt to add a notification.
    // scheduleGlobalStreakAtRiskNudge was removed in Phase 25 — replaced by scheduleOneShotStreakAtRisk.
    func test_scheduleOneShotStreakAtRisk_respectsCapGuard() async {
        // Arrange: inject a pending count of 60 (at the cap boundary)
        let scheduler = NotificationScheduler.shared

        // Act: call with pendingCount = 60 and a fixed currentHour so the time guard doesn't fire.
        // The method should return early without adding a notification.
        await scheduler.scheduleOneShotStreakAtRisk(activeGoals: [], streak: 5, pendingCount: 60, currentHour: 8)

        // Assert: the global streak-at-risk notification should NOT be pending
        // (because the cap guard fired and we returned early — no center.add was called)
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let globalNudgeAdded = pending.contains {
            $0.identifier == NotificationScheduler.globalStreakAtRiskIdentifier
        }
        XCTAssertFalse(
            globalNudgeAdded,
            "Expected cap guard to prevent adding notification when pendingCount >= 60"
        )
    }

    // MARK: - test_globalStreakAtRiskIdentifier_isStable
    //
    // Regression guard: the static identifier string must remain stable across refactors.
    func test_globalStreakAtRiskIdentifier_isStable() {
        XCTAssertEqual(
            NotificationScheduler.globalStreakAtRiskIdentifier,
            "com.kyleharrington.VitaminG.streakAtRisk.global",
            "globalStreakAtRiskIdentifier must not change — it's used to cancel pending notifications by ID"
        )
    }
}
