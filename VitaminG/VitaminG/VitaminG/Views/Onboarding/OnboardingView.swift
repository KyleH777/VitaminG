import SwiftUI

// MARK: - OnboardingStep

/// Type-safe navigation steps for the onboarding NavigationStack.
/// Matches AppRoute pattern from ContentView.swift / AppRoute.swift.
enum OnboardingStep: Hashable {
    case tiers
    case createGoal
}

// MARK: - OnboardingView

/// NavigationStack shell for the 3-screen onboarding flow.
/// Gates completion via @AppStorage("hasCompletedOnboarding").
/// Per D-02: uses NavigationStack (not .fullScreenCover) for automatic swipe-back.
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
                    case .tiers:
                        TiersScreen(path: $path, onSkip: finish)
                    case .createGoal:
                        CreateFirstGoalScreen(
                            onboardingVM: onboardingVM,
                            onComplete: finish,
                            onSkipGoal: finish
                        )
                    }
                }
        }
        .sheet(isPresented: $onboardingVM.showNotificationSheet) {
            NotificationPermissionSheet(
                onAllow: {
                    Task { await NotificationScheduler.shared.requestAuthorization() }
                    onboardingVM.showNotificationSheet = false
                },
                onNotNow: {
                    onboardingVM.showNotificationSheet = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Actions

    /// Completes onboarding: sets @AppStorage flag synchronously (Pitfall 2),
    /// then triggers async notification permission check.
    private func finish() {
        hasCompletedOnboarding = true
        Task { await onboardingVM.completeOnboarding() }
    }
}
