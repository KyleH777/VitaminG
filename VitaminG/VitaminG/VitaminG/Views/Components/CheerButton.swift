import SwiftUI

// MARK: - CheerButton
// "Cheer them on today" button for PublicProfileView.
// Pure presentation — availability is determined by the caller (PublicProfileViewModel.canCheerToday).
// UI-SPEC §3: accentGold tint, disabled opacity 0.35, float animation via ApplauseButtonView mechanic.
// Reuses ApplauseButtonView's floating animation pattern (extract-style reuse via inline composition).
//
// Animation reuse strategy: rather than modifying ApplauseButtonView (which has passing tests),
// CheerButton implements the same float mechanic inline using identical state machine
// (showFloat: Bool, floatOffset: CGFloat, floatOpacity: Double). This avoids risk to
// existing ApplauseButtonView tests while sharing the visual mechanic. If a shared modifier
// is extracted in a future refactor, it should live under Views/Components/.

struct CheerButton: View {

    /// False when daily gate already consumed for this recipient.
    let isAvailable: Bool
    /// Username of the person being cheered (shown in float animation).
    let recipientUsername: String
    /// Fired when the user taps and gate allows it.
    let onCheer: () -> Void

    // MARK: - Animation State (mirrors ApplauseButtonView mechanic)

    @State private var showFloat: Bool = false
    @State private var floatOffset: CGFloat = 0
    @State private var floatOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Button(action: triggerCheer) {
                VStack(spacing: 4) {
                    Image(systemName: "hands.clap.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(VGTheme.accentGold)

                    Text(isAvailable ? "Cheer them on today" : "Cheered today")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(isAvailable ? VGTheme.accentGold : VGTheme.textMuted)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!isAvailable)
            .buttonStyle(.plain)
            // UI-SPEC §3 disabled opacity rule: .opacity(0.35) not color swap
            .opacity(isAvailable ? 1.0 : 0.35)
            .accessibilityLabel(
                isAvailable
                    ? "Cheer \(recipientUsername) on today"
                    : "Already cheered today. Come back tomorrow."
            )
            .accessibilityAddTraits(.isButton)

            // Floating animation overlay — matches ApplauseButtonView mechanic exactly
            if showFloat {
                VStack(spacing: 2) {
                    Image(systemName: "hands.clap.fill")
                        .font(.system(size: 22))
                    Text(recipientUsername)
                        .font(.system(size: 14, design: .rounded))
                }
                .foregroundStyle(VGTheme.accentGold)
                .offset(y: floatOffset)
                .opacity(floatOpacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Cheer Trigger

    private func triggerCheer() {
        guard isAvailable else { return }
        onCheer()

        if reduceMotion {
            // Reduced motion: action fires, animation suppressed (UI-SPEC §Accessibility)
            return
        }

        showFloat = true
        floatOffset = 0
        floatOpacity = 1.0

        withAnimation(.easeOut(duration: 1.0)) {
            floatOffset = -80
            floatOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showFloat = false
        }
    }
}

// MARK: - Preview

#Preview("Available") {
    CheerButton(
        isAvailable: true,
        recipientUsername: "alice",
        onCheer: {}
    )
    .padding()
    .background(VGTheme.background)
}

#Preview("Used") {
    CheerButton(
        isAvailable: false,
        recipientUsername: "alice",
        onCheer: {}
    )
    .padding()
    .background(VGTheme.background)
}
