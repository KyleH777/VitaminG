import SwiftUI
import SwiftData

struct CommunityTabView: View {
    @Binding var selectedTab: Int
    @Query private var userChallenges: [UserChallenge]
    private var activeChallenges: [UserChallenge] {
        userChallenges.filter { !$0.isCompleted }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Community")
                    .font(VGTheme.serif(28))
                    .foregroundStyle(VGTheme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                if activeChallenges.isEmpty {
                    emptyState
                } else {
                    challengeList
                }
            }
        }
        .background(VGTheme.background)
    }

    private var challengeList: some View {
        LazyVStack(spacing: 10) {
            ForEach(activeChallenges) { challenge in
                NavigationLink(value: AppRoute.communityFeed(challenge)) {
                    CommunityChallengeCellView(challenge: challenge)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No challenges yet")
                .font(VGTheme.serif(20))
                .foregroundStyle(VGTheme.textPrimary)
            Text("Join a challenge to connect with others.")
                .font(.system(size: 14))
                .foregroundStyle(VGTheme.textMuted)
                .multilineTextAlignment(.center)
            Button("Explore Challenges") {
                selectedTab = 3
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(VGTheme.terra)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }
}

private struct CommunityChallengeCellView: View {
    let challenge: UserChallenge

    private var accentColor: Color {
        if let hex = challenge.template?.accentColorHex {
            return Color(hex: hex)
        }
        return VGTheme.terra
    }
    private var challengeName: String { challenge.template?.name ?? "Challenge" }
    private var categoryLabel: String { challenge.template?.category ?? "" }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 4, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(challengeName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(VGTheme.textPrimary)
                Text(categoryLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(VGTheme.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(VGTheme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(VGTheme.separator, lineWidth: 1)
        )
    }
}
