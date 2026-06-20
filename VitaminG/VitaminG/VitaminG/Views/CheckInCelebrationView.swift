import SwiftUI

// MARK: - CheckInCelebrationView
//
// Full-screen celebration presented via .fullScreenCover when the user completes
// a daily check-in in GoalDetailView.
//
// Displays: dark overlay (0.92 opacity), 60-particle Canvas confetti (copied from
// MilestoneCelebrationView pattern), check-in badge, overall app streak, auto-dismiss.
//
// Key difference from MilestoneCelebrationView: NO badge persistence (per-event
// celebration, not per-milestone). Per D-12 / GOAL2-04 / Phase 18 Plan 05.
//
// Auto-dismiss: DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { onDismiss() }
// Manual dismiss: "Back to Goals" button is always present.
// Reduce motion: confetti canvas hidden; badge scales in statically.

struct CheckInCelebrationView: View {

    // MARK: - Properties

    /// Overall app streak — caller passes StreakEngine.currentStreak(from: allEvents) per D-12.
    let streakCount: Int
    let onDismiss: () -> Void

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

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(VGTheme.accentSage)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                    .accessibilityLabel("Check-in complete!")

                Text("You showed up.")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("\(streakCount) day streak")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(VGTheme.accentTerra)
                    .accessibilityLabel("\(streakCount) day streak")

                Text("Keep showing up.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button("Back to Goals") { onDismiss() }
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(VGTheme.accentTerra)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .accessibilityLabel("Back to Goals")
            }
        }
        .onAppear {
            // Auto-dismiss after 2 seconds (D-13 / GOAL2-04)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { onDismiss() }

            // Accessibility announcement
            UIAccessibility.post(
                notification: .announcement,
                argument: "Check-in complete! \(streakCount) day streak"
            )

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
        }
    }

    // MARK: - Confetti (SwiftUI Canvas + TimelineView — copied verbatim from MilestoneCelebrationView)
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
