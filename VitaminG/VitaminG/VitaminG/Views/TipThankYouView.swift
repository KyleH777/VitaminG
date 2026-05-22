import SwiftUI

// MARK: - TipThankYouView
// Post-purchase celebration overlay shown via .fullScreenCover in TipJarView.
// Displayed ONLY on verified purchase success — never on .userCancelled or .pending.
// MON-04: consumable tip — no feature gates, no entitlement announcement.
// T-19-03-01: presented only when TipStore.purchase returns (success: true, _).
// Structural analog of MilestoneCelebrationView.swift.
// MON-03 / T-19-03-03: zero external URLs in this file (grep-verified).

struct TipThankYouView: View {

    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: Double = 0.3
    @State private var opacity: Double = 0.0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dark overlay — 0.92 opacity, matching MilestoneCelebrationView pattern
            Color.black.opacity(0.92).ignoresSafeArea()

            // Confetti canvas (decorative — accessibilityHidden)
            confettiView
                .ignoresSafeArea()
                .accessibilityHidden(true)

            // Content
            VStack(spacing: 24) {
                Spacer()

                Text("☕")
                    .font(.system(size: 64))
                    .scaleEffect(scale)
                    .opacity(opacity)

                Text("Thank you!\nYou're the best.")
                    .font(.title2.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button("Done") { onDismiss() }
                    .font(.body.weight(.semibold))
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(VGTheme.accentTerra)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            if reduceMotion {
                // Reduce Motion: show content statically, skip scale animation
                scale = 1.0
                opacity = 1.0
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
            UIAccessibility.post(
                notification: .announcement,
                argument: "Thank you for your support!"
            )
        }
    }

    // MARK: - Confetti (SwiftUI Canvas + TimelineView — no SpriteKit, no third-party)
    // Copied verbatim from MilestoneCelebrationView.swift lines 123-141.

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
