import SwiftUI
import SwiftData

// MARK: - StatsView

/// Stats screen — shows global streak, per-tier streaks, completion rates, goal counts, and heatmap.
///
/// STATS-04: All four data points (streak, completion rate, goal count, and tier breakdown)
/// visible without scrolling on a standard iPhone.
/// T-03-05: nil-safe — all values fetched from StatsViewModel which guards nil completedAt.
struct StatsView: View {
    @Query private var events: [CompletionEvent]
    @Query private var goals: [Goal]

    @State private var viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                globalStreakCard
                tierStreakGrid
                heatmapSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.refresh(events: events, goals: goals)
        }
        .onChange(of: events.count) {
            viewModel.refresh(events: events, goals: goals)
        }
        .onChange(of: goals.count) {
            viewModel.refresh(events: events, goals: goals)
        }
    }

    // MARK: - Global Streak Card

    private var globalStreakCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.55, blue: 0.27),
                            Color(red: 0.78, green: 0.48, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Global Streak")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                }

                // D-09 exception: display-proportional numeral in fixed-size card (analogous to AvatarView initials)
                Text("\(viewModel.globalStreak)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(viewModel.globalStreak == 1 ? "Day" : "Days")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - Per-Tier Streak Grid

    private var tierStreakGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Tier")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(GoalTier.ordered, id: \.self) { tier in
                    TierStatCard(
                        tier: tier,
                        streak: viewModel.tierStreaks[tier] ?? 0,
                        goalCount: viewModel.tierGoalCounts[tier] ?? 0,
                        completionRate: viewModel.tierCompletionRates[tier] ?? 0
                    )
                }
            }
        }
    }

    // MARK: - Heatmap Section

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 4)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Past 90 Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HeatmapView(data: viewModel.heatmapData)
                }
                .padding(16)
            }
        }
    }
}

// MARK: - TierStatCard

private struct TierStatCard: View {
    let tier: GoalTier
    let streak: Int
    let goalCount: Int
    let completionRate: Double

    private var formattedRate: String {
        let pct = Int((completionRate * 100).rounded())
        return "\(pct)%"
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))

            // Tier color accent bar on leading edge
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(tier.color)
                    .frame(width: 4)
                    .padding(.vertical, 12)
                    .padding(.leading, 8)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: tier.icon)
                            .font(.caption)
                            .foregroundStyle(tier.color)
                        Text(tier.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // D-09 exception: display-proportional numeral in fixed-size card (analogous to AvatarView initials)
                    Text("\(streak)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text("\(goalCount) goal\(goalCount == 1 ? "" : "s")")
                        Text("·")
                        Text(formattedRate)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(.leading, 10)
                .padding(.trailing, 12)
                .padding(.vertical, 14)
            }
        }
    }
}
