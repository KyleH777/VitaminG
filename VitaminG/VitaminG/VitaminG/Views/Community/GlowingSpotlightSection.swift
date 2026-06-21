import SwiftUI

// MARK: - GlowingSpotlightSection
// Glowing This Week hero card (COMM-05 / SOC-01).
//
// Shows the deterministically selected weekly glowing user from GlowingSelector.
// Card: VGTheme.surface background, gold ring 2pt border, 24pt internal padding,
// cornerRadius 20pt, horizontal padding 16pt (UI-SPEC §Component Inventory).
//
// The whole card is a Button for profile navigation; ApplauseButtonView inside
// retains its own Button interaction via .buttonStyle(.plain) on the outer wrapper.
//
// Security (T-21-05-02): Displays public CloudKit fields only — username + goalTitle
// are public by design (user published their goal). No mitigation required.

struct GlowingSpotlightSection: View {

    // MARK: - Properties

    let glowingUser: GoalGlimpseItem?
    let giverUsername: String
    let canApplaud: (String) -> Bool
    let onApplaud: (String) -> Void
    let onTapUser: (GoalGlimpseItem) -> Void

    // MARK: - Body

    var body: some View {
        if let user = glowingUser {
            heroCard(user: user)
        } else {
            emptyState
        }
    }

    // MARK: - Hero card

    private func heroCard(user: GoalGlimpseItem) -> some View {
        Button {
            onTapUser(user)
        } label: {
            VStack(spacing: 12) {
                // Allcaps section label
                Text("GLOWING THIS WEEK")
                    .font(.caption.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.accentGold)
                    .kerning(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)

                // Avatar
                AvatarView(
                    displayName: user.username,
                    avatarColorHex: user.authorColorHex,
                    photoData: nil,
                    size: 64
                )
                .accessibilityHidden(true)

                // Username
                Text(user.username)
                    .font(VGTheme.serif(20))
                    .foregroundStyle(VGTheme.textPrimary)
                    .multilineTextAlignment(.center)

                // Goal title
                Text(user.goalTitle)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                // Applause button — embedded; retains its own Button tap
                ApplauseButtonView(
                    recipientUsername: user.username,
                    giverUsername: giverUsername,
                    canApplaud: canApplaud(user.username),
                    onApplaud: { onApplaud(user.username) }
                )
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(VGTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(VGTheme.accentGold, lineWidth: 2)
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Glowing This Week: \(user.username), \(user.goalTitle). Tap to view profile.")
    }

    // MARK: - Empty state (UI-SPEC §Copywriting)

    private var emptyState: some View {
        Text("Check back later — someone will be glowing this week.")
            .font(.callout)
            .fontDesign(.rounded)
            .foregroundStyle(VGTheme.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }
}
