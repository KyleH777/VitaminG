import SwiftUI
import UserNotifications
import Observation

// MARK: - OnboardingViewModel

@MainActor
@Observable
final class OnboardingViewModel {

    var hasCreatedFirstGoal: Bool = false

    func completeOnboarding() async {
        hasCreatedFirstGoal = true
        // Notification permission is handled inline by NotificationOnboardingScreen.
        // Nothing else needed here.
    }
}
