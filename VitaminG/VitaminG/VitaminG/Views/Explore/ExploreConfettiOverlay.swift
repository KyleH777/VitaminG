import SwiftUI

struct ExploreConfettiOverlay: View {
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if !reduceMotion {
                confettiView
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            VStack {
                Spacer()
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(VGTheme.textPrimary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(VGTheme.surface)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 60)
            }
        }
        .background(Color.black.opacity(0.3).ignoresSafeArea())
        .onTapGesture { onDismiss() }
    }

    private var confettiView: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let count = 60
                for i in 0..<count {
                    let seed = Double(i) * 137.5
                    let x = (sin(seed + now * 0.8 + Double(i)) * 0.5 + 0.5) * size.width
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
