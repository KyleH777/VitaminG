import SwiftUI

// MARK: - GoalCompletionCelebrationView
//
// Full-screen "You did it" celebration presented via .fullScreenCover in GoalDetailView
// when the user's cumulative check-ins reach the goal's durationDays target (MILE-06).
//
// Key behaviour:
// - Does NOT call StreakMilestoneGate — the shown-once guard for this view is
//   `goal.completionCelebrationShown` (Bool?, SchemaV10), set by the caller in .onChange
//   after it copies the pendingGoalCompletion value.
// - Includes a ShareLink for the iOS native share sheet (iOS 16+ SwiftUI).
// - Confetti suppressed when accessibilityReduceMotion is true.
// - No CloudKit, SwiftData, or business logic in this view.
//
// MILE-06 / Phase 23 Plan 03.

struct GoalCompletionCelebrationView: View {

    // MARK: - Parameters

    /// The completed goal's title.
    let goalTitle: String
    /// Per-goal streak count at the time of completion.
    let streakCount: Int
    /// "Back to Goals" action — provided by the caller.
    let onDismiss: () -> Void

    // MARK: - State

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var badgeScale: Double = 0.3
    @State private var badgeOpacity: Double = 0.0

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            // Confetti — hidden under reduceMotion per accessibility contract
            if !reduceMotion {
                confettiView
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(VGTheme.accentSage)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                    .accessibilityLabel("Goal completed!")

                Text("You did it.")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(goalTitle)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)

                Text("Your streak: \(streakCount) days")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                // ShareLink — iOS native share sheet (T-23-03-02: goalTitle sanitized at creation)
                ShareLink(
                    item: "I just completed '\(goalTitle)' on Vitamin G with a \(streakCount)-day streak! 🏆"
                ) {
                    Text("Share Accomplishment")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(VGTheme.accentGold)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .accessibilityLabel("Share accomplishment")

                // Back to Goals button
                Button {
                    onDismiss()
                } label: {
                    Text("Back to Goals")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(VGTheme.accentSage)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .accessibilityLabel("Back to Goals")
            }
        }
        .onAppear {
            // Badge animation — suppress spring under reduceMotion
            if reduceMotion {
                badgeScale = 1.0
                badgeOpacity = 1.0
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    badgeScale = 1.0
                    badgeOpacity = 1.0
                }
            }

            // Accessibility announcement
            UIAccessibility.post(
                notification: .announcement,
                argument: "Goal completed: \(goalTitle). Streak: \(streakCount) days."
            )
        }
    }

    // MARK: - Confetti (SwiftUI Canvas + TimelineView — copied verbatim from CheckInCelebrationView)
    // 60 particles, golden-angle scatter, hue-varied. No SpriteKit, no third-party.

    private var confettiView: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let count = 60
                for i in 0..<count {
                    let seed = Double(i) * 137.5  // golden angle scatter
                    let x = (sin(seed + now * 0.8 + Double(i)) * 0.5 + 0.5) * size.width
                    // y falls downward over time, wraps at bottom
                    let rawY = (now * 80.0 + seed * 3.7).truncatingRemainder(dividingBy: size.height)
                    let y = rawY < 0 ? rawY + size.height : rawY
                    let hue = (seed / 360.0).truncatingRemainder(dividingBy: 1.0)
                    let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
                    let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
