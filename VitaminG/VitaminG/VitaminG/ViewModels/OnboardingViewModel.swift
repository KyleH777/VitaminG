import SwiftUI
import UserNotifications
import Observation

// MARK: - OnboardingViewModel

/// Manages onboarding flow state and notification permission check.
/// Matches GoalViewModel @MainActor @Observable pattern.
@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - State

    var hasCreatedFirstGoal: Bool = false
    var showNotificationSheet: Bool = false

    // MARK: - Actions

    /// Called after onboarding is complete (goal created or skipped).
    /// Checks notification authorization status. If .notDetermined, presents permission sheet.
    /// If already .authorized or .denied, skips the sheet per NOTIF-01 / Pitfall 6.
    func completeOnboarding() async {
        hasCreatedFirstGoal = true
        let status = await NotificationScheduler.shared.authorizationStatus()
        if status == .notDetermined {
            showNotificationSheet = true
        }
    }
}
