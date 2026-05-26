import SwiftUI

// MARK: - PeopleSearchResultCard
// Card for Discover People segment results (DISC-02).
// Pure presentation — no async work, no CloudKit, no business logic.
// UI-SPEC §5: 40pt AvatarView + username + metadata + FollowButton. 12pt corner radius.
// Analog: CommunityPostCard.swift (AvatarView + HStack header row + action button).
//
// Hit-testing design: the FollowButton is .buttonStyle(.plain) and uses contentShape(Rectangle())
// on the HStack to ensure tap-to-open (onTap) only fires outside the Follow button area.
// The FollowButton's internal tap stops propagation naturally in SwiftUI.

struct PeopleSearchResultCard: View {

    let result: DiscoverPersonResult
    /// Current follow state — drives FollowButton appearance. Owned by caller.
    let followState: FollowState
    /// Fired when the user taps the FollowButton.
    let onFollow: () -> Void
    /// Fired when the user taps the card row (outside the FollowButton) to open PublicProfileView.
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                displayName: result.username,
                avatarColorHex: result.avatarColorHex,
                photoData: nil,   // D-06: no photoData on public profiles
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(result.username)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(VGTheme.textPrimary)

                Text("\(result.goalCount) goals · \(result.cheersGivenCount) cheers given")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(VGTheme.textMuted)
            }

            Spacer()

            // FollowButton: must consume its tap and not propagate to the row's onTapGesture.
            // .buttonStyle(.plain) prevents the button tap from bubbling up.
            FollowButton(state: followState, onFollow: onFollow, username: result.username)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .contentShape(Rectangle())  // Makes full card tappable (including spacer regions)
        .onTapGesture(perform: onTap)
        // UI-SPEC §Accessibility
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        PeopleSearchResultCard(
            result: DiscoverPersonResult(
                id: "u1",
                username: "alice_runs",
                avatarColorHex: "#C4673A",
                goalCount: 5,
                cheersGivenCount: 23
            ),
            followState: .idle,
            onFollow: {},
            onTap: {}
        )
        PeopleSearchResultCard(
            result: DiscoverPersonResult(
                id: "u2",
                username: "bob_reads",
                avatarColorHex: "#7A9E7E",
                goalCount: 12,
                cheersGivenCount: 107
            ),
            followState: .followed,
            onFollow: {},
            onTap: {}
        )
        PeopleSearchResultCard(
            result: DiscoverPersonResult(
                id: "u3",
                username: "carol_cooks",
                avatarColorHex: "#C4A459",
                goalCount: 3,
                cheersGivenCount: 8
            ),
            followState: .loading,
            onFollow: {},
            onTap: {}
        )
    }
    .padding()
    .background(VGTheme.background)
}
