import SwiftUI

// MARK: - OnboardingStep

/// Type-safe navigation steps for the redesigned onboarding flow.
enum OnboardingStep: Hashable {
    case phoneSignup        // Step 0: phone / email entry
    case verificationCode   // Step 0b: OTP verification
    case name               // Legacy — kept for any existing deep links
    case motivationCategories
    case notifications
    case communityGoal
    case createGoal
}

// MARK: - OnboardingView

/// NavigationStack shell for the full onboarding flow.
/// Flow: Splash → Name → Motivation → Notifications → CommunityGoal → CreateFirstGoal
/// Gates completion via @AppStorage("hasCompletedOnboarding").
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
                    case .phoneSignup:
                        PhoneSignupScreen(path: $path, onSkip: finish)
                    case .verificationCode:
                        VerificationCodeScreen(path: $path, onSkip: finish)
                    case .name:
                        NameScreen(path: $path, onSkip: finish)
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
}
