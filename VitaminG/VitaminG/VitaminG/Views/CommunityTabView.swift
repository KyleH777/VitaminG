import SwiftUI
import SwiftData

enum CommunitySegment: String, CaseIterable {
    case feed = "Feed"
    case ideas = "Ideas"
}

struct CommunityTabView: View {
    @Binding var selectedTab: AppTab
    @Query private var userChallenges: [UserChallenge]
    @State private var segment: CommunitySegment = .feed

    private var activeChallenges: [UserChallenge] {
        userChallenges.filter { $0.statusRaw == "active" }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Community")
                    .font(VGTheme.serif(28))
                    .foregroundStyle(VGTheme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                Picker("Section", selection: $segment) {
                    ForEach(CommunitySegment.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                if segment == .feed {
                    if activeChallenges.isEmpty {
                        emptyState
                    } else {
                        challengeList
                    }
                } else {
                    IdeaBoardView()
                }
            }
        }
        .background(VGTheme.background)
    }

    private var challengeList: some View {
        LazyVStack(spacing: 10) {
            ForEach(activeChallenges) { challenge in
                NavigationLink(value: AppRoute.communityGoals(challenge)) {
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
                selectedTab = .explore
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
    private var challengeName: String { challenge.template?.title ?? "Challenge" }
    private var categoryLabel: String { challenge.template?.category ?? "" }

    private var cellProgress: Double {
        let checkIns = Double(challenge.totalCheckIns ?? 0)
        let duration = Double(max(1, challenge.template?.durationDays ?? 90))
        return min(1.0, checkIns / duration)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon chip
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: challenge.template?.iconName ?? "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(accentColor)
            }

            // Text stack
            VStack(alignment: .leading, spacing: 3) {
                Text(challengeName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(2)
                Text(categoryLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(VGTheme.textMuted)
            }

            Spacer()

            // Progress ring
            ProgressRingView(
                progress: cellProgress,
                tier: .longTerm,
                isCompleted: false,
                size: 48,
                strokeWidth: 4,
                glow: false
            )
        }
        .frame(minHeight: 100)
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
