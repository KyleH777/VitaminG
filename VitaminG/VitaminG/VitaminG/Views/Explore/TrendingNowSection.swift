import SwiftUI

/// Horizontal scroll of community trending goals fetched from CloudKit public DB.
/// Falls back to static data if CloudKit is unavailable or the schema is not yet deployed.
struct TrendingNowSection: View {
    @Bindable var viewModel: ExploreViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isFetchingTrending {
                HStack {
                    ProgressView()
                        .tint(VGTheme.accentTerra)
                    Text("Loading…")
                        .font(.callout)
                        .foregroundStyle(VGTheme.textMuted)
                }
                .padding(.horizontal, 16)
            } else if viewModel.trendingGoals.isEmpty {
                Text("Check back soon — community goals are on their way.")
                    .font(.callout)
                    .foregroundStyle(VGTheme.textMuted)
                    .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.trendingGoals) { item in
                            trendingCard(item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
        }
        .task {
            await viewModel.fetchTrending()
        }
    }

    private func trendingCard(_ item: TrendingGoalItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            categoryColor(item.category),
                            categoryColor(item.category).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    ProgressRingView(
                        progress: item.communityProgress,
                        tier: .immediate,
                        isCompleted: false,
                        size: 28,
                        strokeWidth: 3,
                        glow: false
                    )
                    .accessibilityHidden(true)
                    Text("\(Int(item.communityProgress * 100))% community")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }

                if item.participantCount > 0 {
                    Text("\(item.participantCount.formatted()) joined")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title). \(Int(item.communityProgress * 100)) percent community progress. \(item.participantCount) joined.")
    }

    /// Map GoalCategory to a distinct card accent color using VGTheme.
    private func categoryColor(_ category: GoalCategory) -> Color {
        switch category {
        case .body:       return VGTheme.accentTerra
        case .mind:       return VGTheme.accentSage
        case .wellness:   return Color(hue: 0.33, saturation: 0.55, brightness: 0.55)
        case .money:      return Color(hue: 0.13, saturation: 0.6, brightness: 0.55)
        case .connection: return Color(hue: 0.95, saturation: 0.5, brightness: 0.55)
        case .creative:   return Color(hue: 0.72, saturation: 0.5, brightness: 0.55)
        case .habit:      return VGTheme.accentTerra
        case .other:      return VGTheme.accentSage
        }
    }
}
