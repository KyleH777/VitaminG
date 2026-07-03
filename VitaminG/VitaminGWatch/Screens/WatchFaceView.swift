import SwiftUI

// Screen 01 — Watch Face (Modular / Infograph style)
// Shows the Vitamin G complication layout. To activate as a real complication,
// add a WidgetKit target (File > New > Target > Widget Extension) and reference
// VGWatch colors + VGRingView from this source set.
struct WatchFaceView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Radial terra halo behind the ring
            RadialGradient(
                colors: [VGWatch.terra.opacity(0.18), .clear],
                center: .init(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: 80
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Date + battery row
                HStack {
                    Text("FRI · 16 MAY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(VGWatch.terraSoft)
                        .tracking(1.2)
                    Spacer()
                    Text("87%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(VGWatch.muted)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                // Time + ring
                ZStack {
                    VGRingView(progress: 0.72, size: 108, lineWidth: 5, color: VGWatch.terraSoft)

                    VStack(spacing: 2) {
                        Text("10:09")
                            .font(.system(size: 44, weight: .thin))
                            .foregroundColor(.white)
                        Text("Vitamin G")
                            .font(VGWatch.serif(13, italic: true))
                            .foregroundColor(VGWatch.terraGlow)
                    }
                }
                .frame(height: 112)
                .padding(.top, 4)

                // 4 complications grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ComplicationCard(emoji: "🔥", value: "12", label: "Day streak", accent: VGWatch.terra)
                    ComplicationCard(
                        ringProgress: 0.6,
                        ringColor: VGWatch.sageBright,
                        value: "3/5",
                        label: "Today",
                        accent: VGWatch.sageBright
                    )
                    ComplicationCard(emoji: "☀️", value: "72%", label: "Group", accent: VGWatch.gold)
                    ComplicationCard(emoji: "🌿", value: "6pm", label: "Walk", accent: VGWatch.plum)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                Spacer()
            }
        }
    }
}

private struct ComplicationCard: View {
    var emoji: String? = nil
    var ringProgress: Double? = nil
    var ringColor: Color = .white
    var value: String
    var label: String
    var accent: Color

    var body: some View {
        HStack(spacing: 5) {
            if let ring = ringProgress {
                VGRingView(progress: ring, size: 18, lineWidth: 2.5, color: ringColor,
                           trackColor: Color.white.opacity(0.08), glow: false)
            } else if let e = emoji {
                Text(e).font(.system(size: 13))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(label.uppercased())
                    .font(.system(size: 7.5, weight: .semibold))
                    .foregroundColor(accent)
                    .tracking(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(accent.opacity(0.18))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.30), lineWidth: 1))
        .cornerRadius(12)
    }
}

#Preview {
    WatchFaceView()
}
