// VitaminG/Views/Onboarding/OnboardingView.swift
import SwiftUI

// MARK: - OnboardingStep

enum OnboardingStep: Hashable {
    case name
    case login
    case recovery
    case motivationCategories
    case notifications
    case communityGoal
    case createGoal
}

// MARK: - OnboardingView

struct OnboardingView: View {

    @State private var path: [OnboardingStep] = []
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingVM = OnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeScreen(path: $path, onSkip: finish)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .name:
                        NameScreen(path: $path, onSkip: finish)
                    case .login:
                        LoginScreen(path: $path, onSkip: finish)
                    case .recovery:
                        RecoveryScreen(path: $path, onSkip: finish, onRestartOnboarding: restartOnboarding)
                    case .motivationCategories:
                        MotivationCategoryScreen(path: $path, onSkip: finish)
                    case .notifications:
                        NotificationOnboardingScreen(path: $path, onSkip: finish)
                    case .communityGoal:
                        CommunityGoalOnboardingScreen(path: $path, onSkip: finish)
                    case .createGoal:
                        CreateFirstGoalScreen(
                            onboardingVM: onboardingVM,
                            onComplete: finish,
                            onSkipGoal: finish
                        )
                    }
                }
        }
    }

    // MARK: - Actions

    private func finish() {
        hasCompletedOnboarding = true
        Task { await onboardingVM.completeOnboarding() }
    }

    private func restartOnboarding() {
        onboardingVM.restartOnboarding()
        path = []
    }
}
