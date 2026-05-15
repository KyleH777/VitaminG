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
    var size: CGFloat = 28
    var strokeWidth: CGFloat = 3
    var glow: Bool = true
    var sublabel: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private let completionGreen = Color.completionGreen

    private var strokeColor: Color {
        isCompleted ? completionGreen : tier.color
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(tier.color.opacity(0.15), lineWidth: strokeWidth)

            // Progress arc — 12 o'clock start via -90° rotation (Pitfall 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.4),
                    value: progress
                )
                .shadow(
                    color: glow && colorScheme == .dark
                        ? strokeColor.opacity(0.6)
                        : .clear,
                    radius: 6
                )

            // Center label
            VStack(spacing: 1) {
                if size >= 40 {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.system(size: size * 0.22, weight: .semibold, design: .rounded))
                        .foregroundStyle(strokeColor)
                }
                if let sublabel {
                    Text(sublabel)
                        .font(.system(size: size * 0.11))
                        .foregroundStyle(VGTheme.textMuted)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(
            isCompleted
                ? "Goal complete"
                : "\(Int((progress * 100).rounded()))% momentum this week"
        )
        .accessibilityAddTraits(.isStaticText)
    }
}
