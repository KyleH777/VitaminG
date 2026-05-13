import XCTest
import UserNotifications
@testable import VitaminG

@MainActor
final class NotificationSchedulerPhase14Tests: XCTestCase {
    var scheduler: NotificationScheduler!

    override func setUp() async throws {
        scheduler = NotificationScheduler.shared
        // Best-effort: clear any pending Phase 14 requests left over from previous tests
        await UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    override func tearDown() async throws {
        await UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduler = nil
    }

    // CHAL-24
    func test_streakAtRiskIdentifier_includesChallengeUUID() {
        let id = UUID()
        let identifier = NotificationScheduler.streakAtRiskIdentifier(for: id)
        XCTAssertEqual(identifier, "com.kyleharrington.VitaminG.streakAtRisk.\(id.uuidString)")
    }

    // CHAL-24
    func test_milestoneIdentifier_includesUUIDAndThreshold() {
        let id = UUID()
        let identifier = NotificationScheduler.milestoneIdentifier(for: id, threshold: 7)
        XCTAssertEqual(identifier, "com.kyleharrington.VitaminG.milestone.\(id.uuidString).7")
    }

    // CHAL-24
    func test_scheduleStreakAtRiskReminder_uses20HourCalendarTrigger() async throws {
        let id = UUID()
        await scheduler.scheduleStreakAtRiskReminder(
            challengeID: id,
            challengeTitle: "Dry Summer"
        )
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let request = pending.first { $0.identifier == NotificationScheduler.streakAtRiskIdentifier(for: id) }
        try XCTSkipIf(request == nil,
            "Notification permission not granted in test environment — skip trigger assertion")
        guard let trigger = request?.trigger as? UNCalendarNotificationTrigger else {
            return XCTFail("Expected UNCalendarNotificationTrigger")
        }
        XCTAssertEqual(trigger.dateComponents.hour, 20)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTAssertTrue(trigger.repeats)
    }

    // CHAL-24
    func test_scheduleMilestoneNotification_usesTimeIntervalTriggerOf1Second() async throws {
        let id = UUID()
        await scheduler.scheduleMilestoneNotification(
            challengeID: id,
            threshold: 7,
            message: "One week strong!"
        )
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let request = pending.first {
            $0.identifier == NotificationScheduler.milestoneIdentifier(for: id, threshold: 7)
        }
        try XCTSkipIf(request == nil,
            "Notification permission not granted in test environment — skip trigger assertion")
        guard let trigger = request?.trigger as? UNTimeIntervalNotificationTrigger else {
            return XCTFail("Expected UNTimeIntervalNotificationTrigger")
        }
        XCTAssertEqual(trigger.timeInterval, 1)
        XCTAssertFalse(trigger.repeats)
    }

    // CHAL-22 — implemented in Plan 08
    func test_canSendBuddyPing_within24Hours_returnsFalse() throws {
        let challenge = UserChallenge()
        challenge.id = UUID()
        // Boundary 1: nil last-sent — always allowed
        XCTAssertNil(challenge.buddyPingLastSent)
        XCTAssertTrue(challenge.canSendBuddyPing,
            "When buddyPingLastSent is nil, canSendBuddyPing must be true")
        // Boundary 2: 1 hour ago — within cooldown, NOT allowed
        challenge.buddyPingLastSent = Date().addingTimeInterval(-3600)
        XCTAssertFalse(challenge.canSendBuddyPing,
            "1 hour after a ping, canSendBuddyPing must be false")
        // Boundary 3: 25 hours ago — past cooldown, allowed again
        challenge.buddyPingLastSent = Date().addingTimeInterval(-90_000)
        XCTAssertTrue(challenge.canSendBuddyPing,
            "25 hours after a ping, canSendBuddyPing must be true")
    }
}
