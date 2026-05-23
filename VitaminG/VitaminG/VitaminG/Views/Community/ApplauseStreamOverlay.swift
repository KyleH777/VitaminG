import SwiftUI

// MARK: - ApplauseStreamOverlay
// GeometryReader overlay for ProfileView that renders received applause as
// floating 👏 animations (SOC-02 / Plan 03).
//
// Renders up to 10 items from receivedApplause to cap particle count.
// Staggered by 0.3s per item so they don't all fire simultaneously.
// Suppressed entirely under accessibilityReduceMotion.
// allowsHitTesting(false) prevents interaction with profile UI beneath (T-21-03-03).

struct ApplauseStreamOverlay: View {

    // MARK: - Properties

    /// The received applause items to animate. At most 10 are displayed.
    let receivedApplause: [ApplauseItem]

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(receivedApplause.prefix(10).enumerated()), id: \.offset) { i, item in
                    if !reduceMotion {
                        FloatingApplauseItemView(
                            item: item,
                            delay: Double(i) * 0.3,
                            containerSize: geo.size
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - FloatingApplauseItemView
// A single floating applause particle triggered after a delay.
// Rises 200pt and fades out over 1.5s (easeOut).

private struct FloatingApplauseItemView: View {

    let item: ApplauseItem
    let delay: Double
    let containerSize: CGSize

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 2) {
            Text("👏")
                .font(.system(size: 18))
            Text(item.giverUsername)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(VGTheme.accentGold)
        }
        .opacity(opacity)
        .offset(y: offset)
        .position(
            x: CGFloat.random(in: 20...(max(20, containerSize.width - 20))),
            y: containerSize.height - 40
        )
        .accessibilityHidden(true)
        .task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            opacity = 1.0
            withAnimation(.easeOut(duration: 1.5)) {
                offset = -200
                opacity = 0
            }
        }
    }
}
