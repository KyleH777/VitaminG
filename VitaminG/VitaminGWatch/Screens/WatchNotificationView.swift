import SwiftUI

// Screen 06 — Notification / lock-screen banner
struct WatchNotificationView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // App icon header
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [VGWatch.terraGlow, VGWatch.terra, Color(red: 0.545, green: 0.267, blue: 0.133)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("g")
                                .font(VGWatch.serif(13, italic: true))
                                .foregroundColor(.white)
                        )
                        .shadow(color: VGWatch.terraSoft.opacity(0.5), radius: 4)

                    Text("VITAMIN G")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                    Spacer()
                    Text("now")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.50))
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 6)

                Divider().overlay(Color.white.opacity(0.05))

                // Message body
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 0) {
                        Text("Good morning, ")
                            .font(VGWatch.serif(18))
                            .foregroundColor(.white)
                        Text("Maya")
                            .font(VGWatch.serif(18, italic: true))
                            .foregroundColor(VGWatch.terraGlow)
                        Text(".")
                            .font(VGWatch.serif(18))
                            .foregroundColor(.white)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    Text("Day 12 of your streak. The group is at 72% — you're growing right with them.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.70))
                        .lineSpacing(2)

                    // Mini progress bar
                    HStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.12))
                                Capsule()
                                    .fill(VGWatch.terraSoft)
                                    .frame(width: geo.size.width * 0.72)
                            }
                        }
                        .frame(height: 4)
                        Text("72%")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(VGWatch.terraSoft)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()

                // Quick-action buttons
                HStack(spacing: 5) {
                    Button("Later") {}
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())

                    Button("Check in") {}
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(colors: [VGWatch.terra, Color(red: 0.545, green: 0.267, blue: 0.133)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    WatchNotificationView()
}
