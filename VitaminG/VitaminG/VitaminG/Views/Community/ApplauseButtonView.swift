import SwiftUI

// MARK: - ApplauseButtonView
// Reusable applause button component for GlowingSpotlightSection and
// GlimpsesCarouselSection (SOC-01 / SOC-02 / Plan 03).
//
// Daily gate: canApplaud is false after the caller has already applauded today.
// Animation: floating 👏 + giverUsername label rises 80pt with easeOut(duration: 1.0),
// suppressed entirely under accessibilityReduceMotion.
// Touch target: minimum 44×44pt per HIG.
// Accessibility: label describes action and gate state.

struct ApplauseButtonView: View {

    // MARK: - Properties

    /// The username of the person being applauded.
    let recipientUsername: String
    /// The username of the person giving applause (shown in the float label).
    let giverUsername: String
    /// False when the daily gate has already been consumed for this recipient today.
    let canApplaud: Bool
    /// Called when the user taps the button and the gate allows it.
    let onApplaud: () -> Void

    // MARK: - Animation state

    @State private var showFloat: Bool = false
    @State private var floatOffset: CGFloat = 0
    @State private var floatOpacity: Double = 0

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 4) {
                Button(action: triggerApplause) {
                    Text("👏")
                        .font(.system(size: 28))
                        .opacity(canApplaud ? 1.0 : 0.4)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .disabled(!canApplaud)
                .accessibilityLabel(
                    canApplaud
                        ? "Applaud \(recipientUsername)"
                        : "Already applauded today"
                )
                .accessibilityAddTraits(.isButton)

                if !canApplaud {
                    Text("Come back tomorrow to applaud again.")
                        .font(.system(size: 14))
                        .foregroundStyle(VGTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
            }

            // Floating animation overlay — rises above the button on tap
            if showFloat {
                VStack(spacing: 2) {
                    Text("👏")
                        .font(.system(size: 22))
                    Text(giverUsername)
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

    // MARK: - Applause trigger

    /// Handles the applause tap — enforces gate, calls closure, triggers animation.
    private func triggerApplause() {
        guard canApplaud else { return }
        onApplaud()

        if reduceMotion {
            // No animation under reduceMotion — action still fires (SOC-01 accessibility)
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
