import SwiftUI

/// Root view of the app. Hosts NavigationStack bound to AppRouter.
/// Phase 1: displays GoalListView. Phase 2 adds navigationDestination cases.
struct ContentView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            GoalListView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .goalDetail(let goal):
                        GoalDetailView(goal: goal)
                    }
                }
        }
    }
}
