import SwiftUI
import SwiftData
import WidgetKit

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
    // NOTE (WR-04): StatsView and AnalyticsView each hold an independent StreakFreezeService
    // instance. Both read/write the same UserDefaults suite, so a freeze applied here is
    // persisted, but AnalyticsView's instance won't reflect it until its next onAppear.
    // The two frozenDates arrays can transiently diverge within the same navigation session.
    // Full fix: lift StreakFreezeService to a shared @Environment object at the NavigationStack root.
    @State private var freezeService = StreakFreezeService()
    @State private var showFreezeConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                globalStreakCard
                ConsistencyScoreCard(
                    score: viewModel.consistencyScore,
                    recentDays: viewModel.recentDaysActivity
                )
                tierStreakGrid
                heatmapSection
                analyticsNavigationRow
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
        }
        // Track the full array of IDs rather than just .count to detect in-place mutations
        // (e.g., a completedAt date correction or a goal title update) that don't change
        // the collection size but do change what the stats display.
        .onChange(of: events.map(\.id)) {
            viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
        }
        .onChange(of: goals.map(\.id)) {
            viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
        }
    }

    // MARK: - Global Streak Card

    private var globalStreakCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [VGTheme.accentTerra, VGTheme.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                        .accessibilityHidden(true)
                    Text("Global Streak")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Text("\(viewModel.globalStreak)")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityLabel("\(viewModel.globalStreak) \(viewModel.globalStreak == 1 ? "day" : "days") global streak")

                Text(viewModel.globalStreak == 1 ? "Day" : "Days")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .accessibilityHidden(true)

                if freezeService.canFreeze {
                    Button {
                        showFreezeConfirmation = true
                    } label: {
                        Label("Freeze Streak", systemImage: "snowflake")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 4)
                    .frame(minHeight: 44)
                    .accessibilityHint("Uses your monthly streak freeze to protect today's streak")
                } else {
                    Label("Streak protected this month", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 24)
        }
        .confirmationDialog(
            "Use your monthly streak freeze?",
            isPresented: $showFreezeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Freeze Streak") {
                freezeService.freeze()
                WidgetCenter.shared.reloadAllTimelines()
                viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You get one freeze per month. This will protect today's streak even if you miss a day.")
        }
    }

    // MARK: - Per-Tier Streak Grid

    private var tierStreakGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Tier")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

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
                .accessibilityAddTraits(.isHeader)

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

    // MARK: - Analytics Navigation Row

    /// D-01: Navigation entry point to AnalyticsView at the bottom of StatsView.
    private var analyticsNavigationRow: some View {
        NavigationLink(value: AppRoute.analytics) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(VGTheme.accentTerra)
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)

                    Text("Analytics")
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View detailed analytics")
        .accessibilityHint("Opens per-goal breakdown and charts")
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
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: tier.icon)
                            .font(.caption)
                            .foregroundStyle(tier.color)
                            .accessibilityHidden(true)
                        Text(tier.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // D-09 exception: display-proportional numeral in fixed-size card (analogous to AvatarView initials)
                    Text("\(streak)")
                        .font(.system(.title, design: .rounded).weight(.bold))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tier.displayName): \(streak) day streak, \(goalCount) goal\(goalCount == 1 ? "" : "s"), \(formattedRate) completion rate")
    }
}
