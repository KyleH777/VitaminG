import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppRouter.self) private var router
    @Query private var allUserChallenges: [UserChallenge]
    @State private var selectedTab: Int = 0

    var body: some View {
        @Bindable var router = router
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            goalsTab
                .tabItem { Label("Goals", systemImage: "target") }
                .tag(1)

            NavigationStack {
                CommunityTabView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Community", systemImage: "person.2.fill") }
            .tag(2)

            NavigationStack {
                ChallengeDiscoveryView()
            }
            .tabItem { Label("Challenges", systemImage: "flame.fill") }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            .tag(4)
        }
        .tint(VGTheme.terra)
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
                    case .stats: StatsView()
                    case .settings: SettingsView()
                    case .profile: ProfileView()
                    case .publicProfile: EmptyView()
                    case .wins: DailyWinsView()
                    case .challengeDetail(let c): ChallengeDetailView(userChallenge: c)
                    case .challengeCheckIn(let c): ChallengeCheckInView(userChallenge: c, viewModel: ChallengeViewModel())
                    case .communityFeed(let c): CommunityFeedView(userChallenge: c)
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
