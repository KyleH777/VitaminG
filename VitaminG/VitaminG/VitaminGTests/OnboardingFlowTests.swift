import XCTest
@testable import VitaminG

// MARK: - OnboardingFlowTests
// Verifies the OnboardingStep.nudgeTimePicker case (NOTIF-01 / D-13) and
// the NotificationPreferences round-trip used by NudgeTimePickerScreen.save().

final class OnboardingFlowTests: XCTestCase {

    // MARK: - OnboardingStep enum tests

    func test_nudgeTimePickerCase_isConstructible() {
        // The enum case exists and is Hashable
        let step: OnboardingStep = .nudgeTimePicker
        XCTAssertEqual(step, .nudgeTimePicker)
    }

    func test_nudgeTimePickerCase_isDistinctFromCameraPermission() {
        let nudge: OnboardingStep = .nudgeTimePicker
        let camera: OnboardingStep = .cameraPermission
        XCTAssertNotEqual(nudge, camera)
    }

    func test_nudgeTimePickerCase_isDistinctFromNotifications() {
        let nudge: OnboardingStep = .nudgeTimePicker
        let notifications: OnboardingStep = .notifications
        XCTAssertNotEqual(nudge, notifications)
    }

    // MARK: - NotificationPreferences round-trip test

    func test_notificationPreferences_saveAndReadBack() {
        // Restore default after test so state does not leak
        defer { NotificationPreferences.save(hour: NotificationPreferences.defaultHour,
                                             minute: NotificationPreferences.defaultMinute) }

        let testHour = 7
        let testMinute = 0
        NotificationPreferences.save(hour: testHour, minute: testMinute)

        XCTAssertEqual(NotificationPreferences.hour, testHour,
                       "hour read-back should equal the saved non-default value")
        XCTAssertEqual(NotificationPreferences.minute, testMinute,
                       "minute read-back should equal the saved value")
    }
}
