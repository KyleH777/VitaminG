import SwiftUI

// MARK: - GoalStreakMilestoneView
//
// Full-screen "Achievement Unlocked" celebration presented via .fullScreenCover in
// GoalDetailView and GoalListView when the user's per-goal streak crosses a milestone
// threshold (7, 14, 30, 60, 90, or 365 days).
//
// Key behaviour:
// - Calls StreakMilestoneGate.markShown in .onAppear to persist the "shown" state.
//   StreakMilestoneGate is the primary idempotency guard (soft gate, re-showing is low risk).
// - "Share to Community" calls onShareToCommunity closure — Plan 04 wires the real
//   implementation; here the closure is a parameter, not hardcoded.
// - Confetti suppressed when accessibilityReduceMotion is true.
//
// MILE-04 / Phase 23 Plan 03.

struct GoalStreakMilestoneView: View {

    // MARK: - Parameters

    /// The goalID — used for StreakMilestoneGate.markShown.
    let goalID: UUID
    /// The milestone threshold just crossed (7, 14, 30, 60, 90, or 365).
    let threshold: Int
    /// The goal's title, displayed as a subtitle under the milestone label.
    let goalTitle: String
    /// The current per-goal streak length at time of presentation.
    let streakCount: Int
    /// Called when the user taps "Share to Community". Plan 04 wires real implementation.
    let onShareToCommunity: () -> Void
    /// Called when the user taps "Continue".
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

                Image(systemName: badgeSymbol)
                    .font(.system(size: 64))
                    .foregroundStyle(badgeColor)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                    .accessibilityLabel("Achievement unlocked: \(milestoneLabel)")

                Text("Achievement Unlocked")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(milestoneLabel)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(badgeColor)
                    .multilineTextAlignment(.center)

                Text(goalTitle)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 32)

                Text("Current streak: \(streakCount) days")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                // Share to Community button — closure provided by caller (Plan 04 wires it)
                Button {
                    onShareToCommunity()
                } label: {
                    Text("Share to Community")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(VGTheme.accentGold)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .accessibilityLabel("Share to Community")

                // Continue (dismiss) button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(VGTheme.accentSage)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .accessibilityLabel("Continue")
            }
        }
        .onAppear {
            // Persist "shown" state — primary idempotency guard (T-23-03-01)
            StreakMilestoneGate.markShown(goalID: goalID, threshold: threshold)

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
                argument: "Achievement unlocked! \(milestoneLabel) on \(goalTitle)."
            )
        }
    }

    // MARK: - Badge Symbol (mapped from threshold — mirrors MilestoneCelebrationView pattern)

    private var badgeSymbol: String {
        switch threshold {
        case 7:   return "flame.fill"
        case 14:  return "star.fill"
        case 30:  return "trophy.fill"
        case 60:  return "medal.fill"
        case 90:  return "medal.fill"
        case 365: return "crown.fill"
        default:  return "star.fill"
        }
    }

    // MARK: - Badge Color

    private var badgeColor: Color {
        switch threshold {
        case 7:   return VGTheme.accentTerra
        case 14:  return VGTheme.accentGold
        case 30:  return VGTheme.accentGold
        case 60:  return VGTheme.accentSage
        case 90:  return Color.purple
        case 365: return VGTheme.accentGold
        default:  return VGTheme.accentGold
        }
    }

    // MARK: - Milestone Label

    private var milestoneLabel: String {
        "\(threshold)-Day Streak!"
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
