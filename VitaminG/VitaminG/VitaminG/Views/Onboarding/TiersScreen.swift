import SwiftUI

// MARK: - TiersScreen

/// Onboarding Screen 2: The Four Tiers.
/// Explains all four tiers with warm, gratitude-framing copy per D-07.
struct TiersScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    // Warm copy per D-07
    private func tierDescription(for tier: GoalTier) -> String {
        switch tier {
        case .immediate: return "Quick wins you can chase today"
        case .shortTerm: return "Goals for the coming weeks and months"
        case .longTerm:  return "What would make this year meaningful"
        case .lifeGoal:  return "What you want your life to stand for"
        }
    }

    // MARK: - Accent gradient (matches EmptyStateView and global design system)
    private let gradientColors: [Color] = [VGTheme.accentTerra, VGTheme.accentPurple]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // MARK: Header
                    VStack(spacing: 8) {
                        Text("The Four Tiers")
                            .font(.title2.weight(.semibold))
                            .fontDesign(.rounded)
                            .accessibilityAddTraits(.isHeader)

                        Text("Every goal finds its place.")
                            .font(.body)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                    // MARK: Tier cards
                    ForEach(GoalTier.ordered, id: \.self) { tier in
                        TierCard(tier: tier, description: tierDescription(for: tier))
                    }
                    .padding(.horizontal, 20)

                    // MARK: Continue CTA
                    Button {
                        path.append(.communityGoal)
                    } label: {
                        Text("Continue")
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
                    .padding(.bottom, 32)
                }
            }
        }
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

// MARK: - TierCard

private struct TierCard: View {
    let tier: GoalTier
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: tier.icon)
                .font(.title2)
                .foregroundStyle(tier.color)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(tier.displayName)
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(tier.color)

                Text(description)
                    .font(.footnote)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
