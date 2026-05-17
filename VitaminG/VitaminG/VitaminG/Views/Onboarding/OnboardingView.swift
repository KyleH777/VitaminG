// VitaminG/Views/Onboarding/OnboardingView.swift
import SwiftUI

// MARK: - OnboardingStep

enum OnboardingStep: Hashable {
    case name
    case login
    case recovery
    case termsAndConditions  // NEW (Plan 1 — D-06)
    case username            // NEW (Plan 1 — D-06)
    case profilePicture      // NEW (Plan 1 — D-06)
    case notifications
    case cameraPermission    // NEW (Plan 1 — D-06)
    case communityGoal
    // .motivationCategories REMOVED (D-05)
    // .createGoal REMOVED (D-16)
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
                    case .termsAndConditions:
                        TermsAndConditionsScreen(path: $path, onSkip: finish)
                    case .username:
                        UsernameScreen(path: $path, onSkip: finish, viewModel: onboardingVM)
                    case .profilePicture:
                        // Placeholder — real screen created in Plan 4
                        Text("Profile Picture — Plan 4")
                    case .notifications:
                        NotificationOnboardingScreen(path: $path, onSkip: finish)
                    case .cameraPermission:
                        // Placeholder — real screen created in Plan 5
                        Text("Camera Permission — Plan 5")
                    case .communityGoal:
                        CommunityGoalOnboardingScreen(path: $path, onSkip: finish)
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
