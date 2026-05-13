import XCTest
import UserNotifications
@testable import VitaminG

@MainActor
final class NotificationSchedulerPhase14Tests: XCTestCase {
    // CHAL-24 — implemented in Plan 03
    func test_streakAtRiskIdentifier_includesChallengeUUID() throws {
        try XCTSkipIf(true, "Implemented in Plan 03")
    }
    // CHAL-24 — implemented in Plan 03
    func test_scheduleStreakAtRiskReminder_uses20HourCalendarTrigger() async throws {
        try XCTSkipIf(true, "Implemented in Plan 03")
    }
    // CHAL-24 — implemented in Plan 03
    func test_scheduleMilestoneNotification_usesTimeIntervalTriggerOf1Second() async throws {
        try XCTSkipIf(true, "Implemented in Plan 03")
    }
    // CHAL-22 — implemented in Plan 08
    func test_canSendBuddyPing_within24Hours_returnsFalse() throws {
        try XCTSkipIf(true, "Implemented in Plan 08")
    }
}
