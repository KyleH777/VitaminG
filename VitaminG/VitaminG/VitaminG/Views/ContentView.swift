import SwiftUI

/// Root view of the app. Hosts a TabView with Goals, Stats, and Settings tabs.
/// Phase 3: TabView with Goals tab (AppRouter-bound), Stats tab (StatsView from Plan 02),
/// and Settings tab (SettingsView from Plan 03).
struct ContentView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
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

            // Settings tab — Plan 03
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
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
                    }
                }
        }
    }
}
