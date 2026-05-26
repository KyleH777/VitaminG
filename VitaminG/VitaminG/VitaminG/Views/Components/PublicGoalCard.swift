import SwiftUI

// MARK: - PublicGoalCard
// Displays a single public goal on the redesigned PublicProfileView.
// Pure presentation — no async work, no CloudKit, no business logic.
// UI-SPEC §1: 44pt progress ring + title + metadata, 16pt corner radius.
// Analog: ProgressRingView.swift (Circle().trim pattern, reduced motion, accessibility).

struct PublicGoalCard: View {

    let goal: PublicGoalItem

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // 44pt progress ring — local Circle().trim() (no GoalTier dependency per UI-SPEC §1)
            ZStack {
                // Track: 15% terra opacity
                Circle()
                    .stroke(VGTheme.accentTerra.opacity(0.15), lineWidth: 4)

                // Progress arc
                Circle()
                    .trim(from: 0, to: Double(goal.progressPercent) / 100.0)
                    .stroke(
                        VGTheme.accentTerra,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    // Source: ProgressRingView.swift lines 42–45
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.4),
                        value: goal.progressPercent
                    )

                // Center percentage label (size * 0.22, semibold rounded — matches ProgressRingView)
                Text("\(goal.progressPercent)%")
                    .font(.system(size: 44 * 0.22, weight: .semibold, design: .rounded))
                    .foregroundStyle(VGTheme.accentTerra)
            }
            .frame(width: 44, height: 44)

            // Text block
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(2)

                Text("\(goal.category) · \(goal.durationDays) days left")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(VGTheme.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        // UI-SPEC §Accessibility
        .accessibilityLabel("\(goal.progressPercent)% complete. \(goal.title). \(goal.durationDays) days remaining.")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        PublicGoalCard(goal: PublicGoalItem(
            id: "goal-1",
            title: "Run a 5K every weekend",
            category: "Health",
            creatorUsername: "alice",
            participantCount: 42,
            progressPercent: 65,
            durationDays: 12,
            creationEpoch: 1_700_000_000
        ))
        PublicGoalCard(goal: PublicGoalItem(
            id: "goal-2",
            title: "Read 12 books this year — one per month challenge",
            category: "Learning",
            creatorUsername: "bob",
            participantCount: 8,
            progressPercent: 0,
            durationDays: 30,
            creationEpoch: 1_700_000_000
        ))
        PublicGoalCard(goal: PublicGoalItem(
            id: "goal-3",
            title: "Meditate daily",
            category: "Wellbeing",
            creatorUsername: "carol",
            participantCount: 100,
            progressPercent: 100,
            durationDays: 0,
            creationEpoch: 1_700_000_000
        ))
    }
    .padding()
    .background(VGTheme.background)
}
