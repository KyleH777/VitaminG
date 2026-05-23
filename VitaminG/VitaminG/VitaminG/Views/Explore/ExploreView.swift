import SwiftUI
import SwiftData

struct ExploreView: View {
    @State private var viewModel = ExploreViewModel()
    @State private var goalVM = GoalViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section 1: Daily Goal Gifter (EXPLORE-01, EXPLORE-02)
                sectionLabel("Today's Gift")
                GoalGifterCard(viewModel: viewModel)

                // Section 2: Mood Prompt (EXPLORE-03) — inserted by Plan 20-02
                sectionLabel("Daily Mood")
                MoodPromptCard(viewModel: viewModel)

                // Section 3: Vitamin Shelf (EXPLORE-04) — inserted by Plan 20-03
                sectionLabel("Vitamin Shelf")
                VitaminShelfSection()

                // Section 4: Trending Now (EXPLORE-05) — inserted by Plan 20-04
                sectionLabel("Trending Now")
                TrendingNowSection(viewModel: viewModel)

                // Section 5: Gifts for Stuck Days (EXPLORE-06) — inserted by Plan 20-04
                sectionLabel("Gifts for Stuck Days")
                StuckDayGiftsSection(viewModel: viewModel)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationDestination(for: GoalCategory.self) { category in
            CategoryGoalListView(category: category)
        }
        .background(VGTheme.background.ignoresSafeArea())
        .navigationTitle("Explore")
        .toolbar {
            if todayGiftedCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(VGTheme.accentTerra)
                        Text("\(todayGiftedCount) done")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(VGTheme.accentTerra)
                    }
                }
            }
        }
        .background(
            ShakeDetectorView(onShake: { viewModel.onGifterActivated() })
                .frame(width: 0, height: 0)
        )
    }

    // Counts goals *added* via the gifter today (not check-in events) — intentional given the
    // one-per-day gifter constraint means this value is always 0 or 1, so add ≡ accomplish.
    private var todayGiftedCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return allGoals.filter {
            $0.associatedInspiration == "vg_gifter" &&
            ($0.creationDate ?? .distantPast) >= today
        }.count
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .kerning(0.4)
            .foregroundStyle(VGTheme.textMuted)
            .padding(.horizontal, 16)
    }
}
