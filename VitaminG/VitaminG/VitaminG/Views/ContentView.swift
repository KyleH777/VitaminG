import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppRouter.self) private var router
    @Query private var allUserChallenges: [UserChallenge]
    @State private var selectedTab: AppTab = .home
    @State private var exploreSearchText: String = ""

    var body: some View {
        @Bindable var router = router
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .stats: StatsView()
                        case .wins: DailyWinsView()
                        case .analytics: AnalyticsView()
                        default: EmptyView()
                        }
                    }
            }
            .tag(AppTab.home)

            goalsTab
                .tag(AppTab.goals)

            NavigationStack {
                ExploreView(searchText: exploreSearchText)
                    .navigationDestination(for: GoalCategory.self) { category in
                        CategoryGoalListView(category: category)
                    }
            }
            .searchable(
                text: $exploreSearchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search goals or people…"
            )
            .tag(AppTab.explore)

            NavigationStack {
                CommunityTabView(selectedTab: $selectedTab)
            }
            .tag(AppTab.community)

            NavigationStack {
                ProfileView()
            }
            .tag(AppTab.profile)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VGTabBar(selection: $selectedTab)
        }
        .tint(VGTheme.accentTerra)
        .sheet(item: Binding(
            get: { router.pendingPublicProfileRecordID.map { ProfileDeepLinkItem(id: $0) } },
            set: { _ in router.pendingPublicProfileRecordID = nil }
        )) { item in
            PublicProfileView(recordID: item.id)
        }
        .sheet(item: Binding(
            get: { router.pendingChallengeCheckInID.map { ChallengeCheckInDeepLinkItem(id: $0) } },
            set: { _ in router.pendingChallengeCheckInID = nil }
        )) { item in
            if let uuid = UUID(uuidString: item.id),
               let challenge = allUserChallenges.first(where: { $0.id == uuid }) {
                NotifCheckInSheetContent(challenge: challenge)
            }
        }
    }

    private var goalsTab: some View {
        @Bindable var router = router
        return NavigationStack(path: $router.path) {
            GoalListView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .goalDetail(let goal): GoalDetailView(goal: goal)
                    case .settings: SettingsView()
                    case .profile: ProfileView()
                    case .publicProfile: EmptyView()
                    case .challengeDetail(let c): ChallengeDetailView(userChallenge: c)
                    case .challengeCheckIn(let c): ChallengeCheckInView(userChallenge: c, viewModel: ChallengeViewModel())
                    case .communityFeed(let c): CommunityFeedView(userChallenge: c)
                    case .communityGoals(let c): CommunityGoalsLandingView(userChallenge: c)
                    default: EmptyView()
                    }
                }
        }
    }
}

// MARK: - NotifCheckInSheetContent

private struct NotifCheckInSheetContent: View {
    let challenge: UserChallenge

    @State private var vm = ChallengeViewModel()
    @State private var notifMilestone: (challengeID: UUID, threshold: Int)? = nil
    @State private var showMilestone = false

    var body: some View {
        ChallengeCheckInView(userChallenge: challenge, viewModel: vm)
            .onChange(of: vm.pendingMilestone?.challengeID) { _, _ in
                if let m = vm.pendingMilestone {
                    notifMilestone = m
                    vm.pendingMilestone = nil
                    showMilestone = true
                }
            }
            .fullScreenCover(isPresented: $showMilestone) {
                if let m = notifMilestone {
                    MilestoneCelebrationView(
                        userChallenge: challenge,
                        threshold: m.threshold,
                        onDismiss: { showMilestone = false }
                    )
                }
            }
    }
}
