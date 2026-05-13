import SwiftUI
import SwiftData

/// Root view of the app. Hosts a TabView with Goals, Stats, Wins, Challenges, and Profile tabs.
/// Phase 11: Settings tab replaced by Wins tab (DailyWinsView). Settings now accessible via ProfileView.
/// Phase 13: 5th Challenges tab added (D-04). pendingChallengeCheckInID sheet wired for notification deep links (D-06, D-07).
/// Goals tab is AppRouter-bound; Stats tab shows StatsView; Wins tab shows DailyWinsView;
/// Challenges tab shows ChallengeDiscoveryView; Profile tab shows ProfileView.
struct ContentView: View {
    @Environment(AppRouter.self) private var router

    /// All user challenges — used to resolve pendingChallengeCheckInID UUID string to a UserChallenge
    /// for the notification-triggered check-in sheet (T-13-24: UUID validated before SwiftData lookup).
    @Query private var allUserChallenges: [UserChallenge]

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

            // Challenges tab — Phase 13 (D-04, CHAL-08)
            NavigationStack {
                ChallengeDiscoveryView()
            }
            .tabItem {
                Label("Challenges", systemImage: "flame.fill")
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
        // Phase 13 — D-06, D-07, CHAL-12: Notification deep-link → ChallengeCheckInView sheet.
        // UUID is validated before SwiftData lookup (T-13-24): malformed or unknown IDs render nothing.
        .sheet(item: Binding(
            get: {
                router.pendingChallengeCheckInID.map { ChallengeCheckInDeepLinkItem(id: $0) }
            },
            set: { _ in
                router.pendingChallengeCheckInID = nil
            }
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
                    case .challengeDetail(let challenge):
                        ChallengeDetailView(userChallenge: challenge)
                    // D-05: NavigationStack push path for challenge check-in (from Challenges tab).
                    // The notification deep-link path uses the .sheet(item:) above — both paths wired.
                    case .challengeCheckIn(let challenge):
                        ChallengeCheckInView(userChallenge: challenge, viewModel: ChallengeViewModel())
                    case .communityFeed(let userChallenge):
                        CommunityFeedView(userChallenge: userChallenge)
                    }
                }
        }
    }
}

// MARK: - NotifCheckInSheetContent

/// Private sub-view presented by the pendingChallengeCheckInID notification sheet.
///
/// Owns a stable ChallengeViewModel (@State) for the duration of the sheet.
/// Observes vm.pendingMilestone to present MilestoneCelebrationView as a fullScreenCover
/// when a milestone is crossed during a notification-triggered check-in (CHAL-10).
///
/// Architecture note: using a dedicated sub-view (not inline closure) ensures the VM
/// has a stable lifetime across the sheet — consistent with ChallengeDetailView's
/// @State private var viewModel = ChallengeViewModel() pattern.
private struct NotifCheckInSheetContent: View {
    let challenge: UserChallenge

    @State private var vm = ChallengeViewModel()
    @State private var notifMilestone: (challengeID: UUID, threshold: Int)? = nil
    @State private var showMilestone = false

    var body: some View {
        ChallengeCheckInView(userChallenge: challenge, viewModel: vm)
            .onChange(of: vm.pendingMilestone?.challengeID) { _, _ in
                // Milestone crossed during notification-triggered check-in (CHAL-10).
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
