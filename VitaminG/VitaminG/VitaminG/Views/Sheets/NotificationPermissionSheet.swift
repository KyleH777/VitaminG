import SwiftUI

// MARK: - NotificationPermissionSheet

/// Half-sheet (medium detent) for contextual notification permission request.
/// Per D-04: presented after first goal creation or onboarding skip — NEVER on cold launch (NOTIF-01).
/// Presented via .sheet + .presentationDetents([.medium]) from OnboardingView.
struct NotificationPermissionSheet: View {

    let onAllow: () -> Void
    let onNotNow: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Accent gradient (matches global design system)
    private let gradientColors: [Color] = [
        Color(red: 0.98, green: 0.55, blue: 0.27),
        Color(red: 0.78, green: 0.48, blue: 0.95)
    ]

    var body: some View {
        VStack(spacing: 24) {
            // MARK: Mock notification card preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Vitamin G")
                    .font(.caption.weight(.semibold))
                    .fontDesign(.rounded)

                Text("Your Vitamin G for today")
                    .font(.footnote.weight(.semibold))
                    .fontDesign(.rounded)

                Text("Complete one goal \u{00B7} Make progress \u{00B7} Stay intentional")
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            // MARK: Value proposition headline
            Text("Wake up to your goals every morning.")
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)

            // MARK: Allow CTA
            Button("Allow Notifications", action: onAllow)
                .font(.body.weight(.semibold))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .buttonStyle(.plain)
                .accessibilityLabel("Allow Notifications button")

            // MARK: Not now
            Button("Not now", action: onNotNow)
                .font(.callout)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(Color(.systemGroupedBackground))
    }
}
