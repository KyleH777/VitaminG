import SwiftUI

// MARK: - VGCapsule
// Vitamin tablet motif — chunky rounded square used on the splash screen and community cards.

struct VGCapsule: View {
    let size: CGFloat
    let color1: Color
    let color2: Color

    private var corner: CGFloat { size * 0.28 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(color1)
                .overlay(RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            VStack(spacing: 0) {
                Color.clear
                color2.opacity(0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: corner))
            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(height: 1)
            Ellipse()
                .fill(Color.white.opacity(0.22))
                .frame(width: size * 0.27, height: size * 0.22)
                .offset(x: -size * 0.17, y: -size * 0.19)
                .rotationEffect(.degrees(-15))
            Text("g")
                .font(Font.custom("Georgia-Italic", size: size * 0.36))
                .foregroundStyle(Color.white.opacity(0.30))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
