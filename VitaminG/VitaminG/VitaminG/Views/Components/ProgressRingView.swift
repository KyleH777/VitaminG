import SwiftUI

// MARK: - ProgressRingView

/// 28pt circular progress ring used in the trailing slot of GoalRowView (D-01).
/// - Background track: faint tier-color circle (opacity 0.15, 3pt stroke)
/// - Progress arc: tier-color (or completionGreen for completed goals), drawn
///   clockwise from 12 o'clock via `.rotationEffect(.degrees(-90))`
/// - Reduced motion: skip the easeInOut animation; render static fill
///
/// PROG-01: per-goal recent-activity indicator. Replaces the prior tier pip
/// (RoundedRectangle 4×36) in GoalRowView.
struct ProgressRingView: View {
    let progress: Double      // 0.0 to 1.0
    let tier: GoalTier
    let isCompleted: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Identical hex to GoalListView.completionGreen (#10B981) — keep in sync.
    private let completionGreen = Color(red: 0.063, green: 0.725, blue: 0.506)

    private var strokeColor: Color {
        isCompleted ? completionGreen : tier.color
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(tier.color.opacity(0.15), lineWidth: 3)

            // Progress arc — 12 o'clock start via -90° rotation (Pitfall 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.4),
                    value: progress
                )
        }
        .frame(width: 28, height: 28)
        .accessibilityLabel(
            isCompleted
                ? "Goal complete"
                : "\(Int(progress * 100))% momentum this week"
        )
        .accessibilityAddTraits(.isStaticText)
    }
}
