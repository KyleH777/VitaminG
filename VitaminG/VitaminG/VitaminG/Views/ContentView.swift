import SwiftUI

/// Root view of the app. Hosts a TabView with Goals, Stats, Wins, and Profile tabs.
/// Phase 11: Settings tab replaced by Wins tab (DailyWinsView). Settings now accessible via ProfileView.
/// Goals tab is AppRouter-bound; Stats tab shows StatsView; Wins tab shows DailyWinsView; Profile tab shows ProfileView.
struct ContentView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView {
            goalsTab
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }

            // Wins tab — Phase 11 (D-01, D-02, GRAT-06)
            NavigationStack {
                DailyWinsView()
            }
            .tabItem {
                Label("Wins", systemImage: "book.pages")
            }

            // Profile tab — Plan 07-02 (D-11)
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
        .sheet(item: Binding(
            get: { router.pendingPublicProfileRecordID.map { ProfileDeepLinkItem(id: $0) } },
            set: { _ in router.pendingPublicProfileRecordID = nil }
        )) { item in
            PublicProfileView(recordID: item.id)
        }
    }

    private var goalsTab: some View {
        @Bindable var router = router
        return NavigationStack(path: $router.path) {
            GoalListView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .goalDetail(let goal):
                        GoalDetailView(goal: goal)
                    case .stats:
                        StatsView()
                    case .settings:
                        SettingsView()
                    case .profile:
                        ProfileView()
                    case .publicProfile:
                        EmptyView()  // Never pushed onto NavigationStack; sheet path handles this route
                    case .wins:
                        DailyWinsView()  // Phase 11: wins deep-link destination
                    case .challengeDetail:
                        EmptyView()  // Phase 13 — UI implemented in Phase 13 Wave 4
                    case .challengeCheckIn:
                        EmptyView()  // Phase 13 — sheet path handles check-in; never pushed
                    }
                }
        }
    }
}
