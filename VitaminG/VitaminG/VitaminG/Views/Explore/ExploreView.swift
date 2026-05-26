import SwiftUI
import SwiftData

struct ExploreView: View {
    @State private var viewModel = ExploreViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal]

    // MARK: - Search (Phase 22, Plan 22-05 Task 2)
    // searchText is passed in from ContentView where .searchable lives on the NavigationStack
    // (Pitfall 1 — .searchable must be on NavigationStack ancestor, not on ScrollView).
    let searchText: String

    @Environment(\.isSearching) private var isSearching

    // DiscoverViewModel instance persists for the lifetime of this view so search debounce
    // and joined-goal state survive body re-renders during search.
    @State private var discoverViewModel = DiscoverViewModel()

    init(searchText: String = "") {
        self.searchText = searchText
    }

    var body: some View {
        if isSearching && searchText.isEmpty {
            // D-02: active + empty → show TRENDING CHALLENGES only
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("TRENDING CHALLENGES")
                    ChallengeDiscoveryView(navigationPath: .constant(NavigationPath()))
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(VGTheme.background.ignoresSafeArea())
        } else if isSearching {
            // D-03: active + non-empty → Discover overlay
            DiscoverOverlayView(searchText: searchText, viewModel: discoverViewModel)
                .onChange(of: searchText) { _, newText in
                    discoverViewModel.onSearchTextChanged(newText)
                }
        } else {
            // D-04: inactive → normal 6-section Explore
            existingScrollContent
        }
    }

    // MARK: - Existing Scroll Content
    // Identical to the original ExploreView body — relocated into a private computed var
    // so the three-branch body above can reference it without duplication.

    private var existingScrollContent: some View {
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

                // Section 6: Discover Challenges (D-06) — migrated from CommunityTabView
                Divider()
                    .padding(.horizontal, 16)
                Text("DISCOVER CHALLENGES")
                    .font(.system(size: 20, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                ChallengeDiscoveryView()
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
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
