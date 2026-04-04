import SwiftUI

/// Root view of the app. Hosts a TabView with Goals and Stats tabs.
/// Phase 3: TabView replaces single NavigationStack. Goals tab preserves existing
/// AppRouter-bound NavigationStack. Stats tab wired to real StatsView (Plan 02).
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
                        Text("Settings") // Replaced in Plan 03
                    }
                }
        }
    }
}
