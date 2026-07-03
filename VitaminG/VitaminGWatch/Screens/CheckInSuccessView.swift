import SwiftUI

// Screen 03 — Check-in Success (glow bloom + streak)
struct CheckInSuccessView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Glow burst behind the ring
            Circle()
                .fill(
                    RadialGradient(colors: [VGWatch.terraSoft.opacity(0.35), .clear],
                                   center: .center, startRadius: 0, endRadius: 90)
                )
                .frame(width: 180, height: 180)
                .offset(y: -24)

            VStack(spacing: 12) {
                // Ring + check icon
                ZStack {
                    VGRingView(progress: appeared ? 1.0 : 0.0,
                               size: 88, lineWidth: 6, color: VGWatch.terraGlow)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [VGWatch.terraGlow, VGWatch.terra],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 54, height: 54)
                            .shadow(color: VGWatch.terra.opacity(0.65), radius: 12)
                            .scaleEffect(appeared ? 1.0 : 0.7)
                            .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.6), value: appeared)

                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeIn(duration: 0.25).delay(0.9), value: appeared)
                    }
                }
                .padding(.top, -10)

                // "Glow up." headline
                Text("Glow up.")
                    .font(VGWatch.serif(22, italic: true))
                    .foregroundColor(VGWatch.terraGlow)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.7), value: appeared)

                // Subtitle
                VStack(spacing: 2) {
                    Text("Day 65 logged.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                    HStack(spacing: 3) {
                        Text("Streak:")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                        Text("13 🔥")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(VGWatch.terraSoft)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.85), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

#Preview {
    CheckInSuccessView()
}
