import SwiftUI

struct ConsistencyScoreCard: View {
    let score: Int
    let recentDays: [Bool]   // 7 elements: index 0 = today

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Consistency Score")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textSecondary)
                    Text("Last 30 days · recent days weighted")
                        .font(.caption)
                        .foregroundStyle(VGTheme.textMuted)
                }
                Spacer()
                // Mini 7-bar chart
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(recentDays.reversed().enumerated()), id: \.offset) { _, active in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(active ? VGTheme.accentSage : VGTheme.separator)
                            .frame(width: 5, height: active ? 28 : 12)
                    }
                }
            }

            // Score numeral
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(VGTheme.accentSage)
                Text("%")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(VGTheme.textMuted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(VGTheme.separator)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(VGTheme.accentSage)
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: 6)
                        .animation(.easeOut(duration: 0.6), value: score)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(VGTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(VGTheme.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Consistency Score: \(score) percent over the last 30 days")
    }
}
