import SwiftUI

struct VGRingView: View {
    var progress: Double
    var size: CGFloat
    var lineWidth: CGFloat
    var color: Color
    var trackColor: Color = Color.white.opacity(0.10)
    var glow: Bool = true
    var animated: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: glow ? color.opacity(0.55) : .clear, radius: 4)
                .animation(animated ? .easeInOut(duration: 1.0) : nil, value: progress)
        }
        .frame(width: size, height: size)
    }
}
