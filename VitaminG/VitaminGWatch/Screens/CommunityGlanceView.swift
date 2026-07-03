import SwiftUI

// Screen 05 — Community Live Glance
struct CommunityGlanceView: View {
    @State private var cheerSent = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Live indicator + label
                HStack(spacing: 5) {
                    Circle()
                        .fill(VGWatch.sageBright)
                        .frame(width: 5, height: 5)
                        .opacity(0.9)
                    Text("LIVE · GROUP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(VGWatch.goldBright)
                        .tracking(1.5)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Text("Summer body")
                    .font(VGWatch.serif(18))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.top, 2)

                // Big percentage
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("72")
                        .font(.system(size: 44, weight: .thin))
                        .foregroundColor(.white)
                    Text("%")
                        .font(.system(size: 20))
                        .foregroundColor(VGWatch.terraGlow)
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)

                Text("14,267 of 20,000 glimpses")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.60))
                    .tracking(1)
                    .padding(.horizontal, 14)
                    .padding(.top, 1)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.10))
                        Capsule()
                            .fill(LinearGradient(colors: [VGWatch.terra, VGWatch.terraGlow],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * 0.72)
                            .shadow(color: VGWatch.terra.opacity(0.65), radius: 4)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 14)
                .padding(.top, 8)

                // Cheer button
                Button {
                    cheerSent = true
                } label: {
                    HStack(spacing: 6) {
                        Text("👏")
                        Text(cheerSent ? "Cheered!" : "Give a cheer")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()
            }
        }
    }
}

#Preview {
    CommunityGlanceView()
}
