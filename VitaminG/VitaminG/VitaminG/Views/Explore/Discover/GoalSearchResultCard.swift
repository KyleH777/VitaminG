import SwiftUI

// MARK: - GoalSearchResultCard
// Compact card for Discover goal search results (DISC-01).
// Pure presentation — no async work, no CloudKit, no business logic.
// UI-SPEC §4: 32pt ring + title + metadata + Join button. 12pt corner radius.
// Analog: CommunityPostCard.swift (HStack card layout, surface background, shadow).

struct GoalSearchResultCard: View {

    let result: DiscoverGoalResult
    let isJoined: Bool
    let onJoin: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 32pt progress ring (UI-SPEC §4: 3pt stroke, same terra tokens as PublicGoalCard)
            ZStack {
                Circle()
                    .stroke(VGTheme.accentTerra.opacity(0.15), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: Double(result.progressPercent) / 100.0)
                    .stroke(
                        VGTheme.accentTerra,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 32, height: 32)

            // Text block
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(1)

                Text("@\(result.creatorUsername) · \(result.category) · \(result.participantCount) people")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(VGTheme.textMuted)
            }

            Spacer()

            // Join button (UI-SPEC §4: 13pt semibold, terra tint, sage when joined)
            Button(isJoined ? "Joined" : "Join", action: onJoin)
                .disabled(isJoined)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isJoined ? VGTheme.accentSage : VGTheme.accentTerra)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    (isJoined ? VGTheme.accentSage : VGTheme.accentTerra).opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        // UI-SPEC §Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.title). \(result.participantCount) people. \(result.progressPercent)% complete. @\(result.creatorUsername) created this goal.")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        GoalSearchResultCard(
            result: DiscoverGoalResult(
                id: "r1",
                title: "Run a marathon in 2026",
                category: "Health",
                creatorUsername: "alice",
                participantCount: 128,
                progressPercent: 42
            ),
            isJoined: false,
            onJoin: {}
        )
        GoalSearchResultCard(
            result: DiscoverGoalResult(
                id: "r2",
                title: "Learn to cook 5 new recipes",
                category: "Lifestyle",
                creatorUsername: "bob",
                participantCount: 34,
                progressPercent: 80
            ),
            isJoined: true,
            onJoin: {}
        )
    }
    .padding()
    .background(VGTheme.background)
}
