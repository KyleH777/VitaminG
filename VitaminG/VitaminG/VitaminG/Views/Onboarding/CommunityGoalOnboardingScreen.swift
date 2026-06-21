import SwiftUI

// MARK: - CommunityGoalOnboardingScreen
// Onboarding Screen 5: Community challenge teaser.
// Shows the Summer Body Challenge card and lets users opt in.

struct CommunityGoalOnboardingScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Back + step
                    HStack {
                        Button(action: { path.removeLast() }) {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(VGTheme.clay)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .accessibilityLabel("Go back")
                        Spacer()
                    }
                    .padding(.bottom, 20)

                    StepBarView(current: 3, total: 4)
                        .padding(.bottom, 28)

                    // Headline
                    Text("Your first\n\(Text("challenge ").font(Font.custom("Georgia-Italic", size: 42)).foregroundStyle(VGTheme.terra))\(Text("awaits.").font(Font.custom("Georgia", size: 42)).foregroundStyle(VGTheme.clay))")
                        .font(Font.custom("Georgia", size: 42))
                        .foregroundStyle(VGTheme.clay)
                        .lineSpacing(4)
                        .padding(.bottom, 12)

                    Text("Join thousands already working toward it. You're never doing this alone.")
                        .font(.callout.weight(.light))
                        .foregroundStyle(VGTheme.muted)
                        .lineSpacing(4)
                        .padding(.bottom, 22)

                    // Challenge card
                    VStack(spacing: 0) {
                        // Gradient header
                        ZStack(alignment: .topLeading) {
                            LinearGradient(
                                colors: [VGTheme.terraSoft, VGTheme.terra, Color(red: 0.627, green: 0.322, blue: 0.176)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 120)
                                .offset(x: -20, y: -20)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("☀️ COMMUNITY CHALLENGE")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(VGTheme.warmWhite.opacity(0.7))
                                    .kerning(1.5)

                                Text("90-Day Summer\nBody Challenge")
                                    .font(Font.custom("Georgia", size: 22))
                                    .foregroundStyle(VGTheme.warmWhite)
                                    .lineSpacing(2)

                                Text("Daily workouts · Nutrition plans · Accountability check-ins")
                                    .font(.caption.weight(.light))
                                    .foregroundStyle(VGTheme.warmWhite.opacity(0.75))
                                    .lineSpacing(3)
                            }
                            .padding(20)
                        }
                        .frame(height: 148)

                        // Stats row
                        VStack(spacing: 12) {
                            HStack {
                                ForEach([("4,821", "Joined"), ("Day 1", "Starts"), ("90", "Days")], id: \.0) { val, label in
                                    VStack(spacing: 2) {
                                        Text(val)
                                            .font(Font.custom("Georgia", size: 22))
                                            .foregroundStyle(VGTheme.clay)
                                        Text(label.uppercased())
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(VGTheme.muted)
                                            .kerning(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            // Progress bar
                            Capsule()
                                .fill(VGTheme.sandMid)
                                .frame(height: 6)
                                .overlay(
                                    GeometryReader { g in
                                        Capsule()
                                            .fill(VGTheme.terra)
                                            .frame(width: g.size.width * 0.02)
                                    }, alignment: .leading
                                )

                            // Avatar stack
                            HStack(spacing: 8) {
                                HStack(spacing: -8) {
                                    ForEach([VGTheme.terraSoft, VGTheme.sage, VGTheme.gold, VGTheme.purple], id: \.self) { c in
                                        Circle()
                                            .fill(c)
                                            .frame(width: 26, height: 26)
                                            .overlay(Circle().strokeBorder(VGTheme.warmWhite, lineWidth: 2))
                                    }
                                }
                                Text("+4,817 others joined")
                                    .font(.caption)
                                    .foregroundStyle(VGTheme.muted)
                            }
                        }
                        .padding(20)
                        .background(VGTheme.warmWhite)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: VGTheme.clay.opacity(0.12), radius: 24, y: 4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("90-Day Summer Body Challenge. 4,821 participants joined. 90 days.")

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
            }

            // Buttons
            VStack(spacing: 8) {
                Button(action: advance) {
                    Text("Join the challenge")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(VGTheme.terra)
                        .foregroundStyle(VGTheme.warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: advance) {
                    Text("Set my own goal first")
                        .font(.callout)
                        .foregroundStyle(VGTheme.muted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
            .background(
                VGTheme.sandLight
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(color: VGTheme.sandMid.opacity(0.6), radius: 8, y: -4)
            )
        }
        .navigationBarHidden(true)
    }

    private func advance() {
        onSkip()
    }
}
