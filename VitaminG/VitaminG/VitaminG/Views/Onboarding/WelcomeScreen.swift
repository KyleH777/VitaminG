import SwiftUI

// MARK: - WelcomeScreen

/// Onboarding Screen 1: Welcome.
/// Shows app name, tagline, and animated accent gradient circle.
/// Per D-01: Skip button visible from first screen.
/// Per D-02: .navigationBarBackButtonHidden(true) — first screen, no back.
/// Per D-13: Pulse animation guarded by accessibilityReduceMotion.
struct WelcomeScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Accent gradient (matches EmptyStateView and global design system)
    private let gradientColors: [Color] = [
        Color(red: 0.98, green: 0.55, blue: 0.27),
        Color(red: 0.78, green: 0.48, blue: 0.95)
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // MARK: Hero circle with pulsing animation (D-13)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            guard !reduceMotion else { return }
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                pulseScale = 1.05
                            }
                        }

                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.white)
                }

                // MARK: Copy
                VStack(spacing: 12) {
                    Text("Vitamin G")
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.rounded)

                    Text("Your daily dose of gratitude and intentionality.")
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // MARK: Get Started CTA
                Button {
                    path.append(.tiers)
                } label: {
                    Text("Get Started")
                        .font(.body.weight(.semibold))
                        .fontDesign(.rounded)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") {
                    onSkip()
                }
                .font(.callout)
                .fontDesign(.rounded)
            }
        }
    }
}
