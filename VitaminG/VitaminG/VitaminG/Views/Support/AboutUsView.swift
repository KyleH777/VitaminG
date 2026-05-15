import SwiftUI

struct AboutUsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Terra gradient header
                ZStack {
                    LinearGradient(
                        colors: [VGTheme.terra, VGTheme.terraSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)

                    VStack(spacing: 12) {
                        Text("About Vitamin G")
                            .font(VGTheme.serif(28, weight: .semibold))
                            .foregroundStyle(VGTheme.sand)
                    }
                }

                // Content area
                VStack(alignment: .leading, spacing: 24) {
                    // OUR STORY section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OUR STORY")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.2)
                            .foregroundStyle(VGTheme.muted)

                        Text("Vitamin G was created for anyone who's ever had a great goal but lost sight of it. We're a small team building tools that make your goals feel less lonely. Every morning, this app puts your goals in front of you — because what you see shapes what you do.")
                            .font(.system(size: 15))
                            .fontDesign(.rounded)
                            .foregroundStyle(VGTheme.textPrimary)
                            .lineSpacing(5)
                    }

                    // THE TEAM section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THE TEAM")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.2)
                            .foregroundStyle(VGTheme.muted)

                        Text("Built by a solo founder who got tired of forgetting what actually matters. If you have feedback, we'd love to hear it at hello@vitamingapp.com.")
                            .font(.system(size: 15))
                            .fontDesign(.rounded)
                            .foregroundStyle(VGTheme.textPrimary)
                            .lineSpacing(5)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(VGTheme.background)
        .navigationTitle("About Us")
        .navigationBarTitleDisplayMode(.inline)
    }
}
