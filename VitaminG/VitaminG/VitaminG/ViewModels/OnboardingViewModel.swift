// VitaminG/ViewModels/OnboardingViewModel.swift
import SwiftUI
import UserNotifications
import Observation

// MARK: - OnboardingViewModel

@MainActor
@Observable
final class OnboardingViewModel {

    var hasCreatedFirstGoal: Bool = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Returning-user detection

    var savedName: String {
        (defaults.string(forKey: "vg_onboardingName") ?? "")
            .trimmingCharacters(in: .whitespaces)
    }

    var isReturningUser: Bool { !savedName.isEmpty }

    // MARK: - Actions

    func completeOnboarding() async {
        hasCreatedFirstGoal = true
        // Notification permission is handled inline by NotificationOnboardingScreen.
    }

    /// Clears persisted profile and onboarding completion flag.
    /// Call from OnboardingView when the user chooses "Start fresh".
    func restartOnboarding() {
        defaults.removeObject(forKey: "vg_onboardingName")
        defaults.set(false, forKey: "hasCompletedOnboarding")
    }
}
