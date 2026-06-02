import Foundation

/// Type-safe route enum for NavigationStack.
/// Phase 2: goalDetail case added per D-08.
/// Phase 3: stats and settings cases added for stats screen and notification settings navigation.
/// Phase 7: profile case added for programmatic navigation to the profile tab (D-11, deep link support).
/// Phase 11: wins case added for future deep-link navigation to the Wins tab.
enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats      // Phase 3: stats screen
    case settings   // Phase 3: notification settings
    case profile    // Phase 7: profile tab deep link navigation
    case publicProfile(recordID: String)   // Phase 10 — D-04, D-05; sheet-only, never pushed onto NavigationStack
    case wins   // Phase 11 — Wins tab navigation (deep-link reserved; plain foreground open in Phase 11)
    case challengeDetail(UserChallenge)    // Phase 13 — CHAL-08, D-05
    case challengeCheckIn(UserChallenge)   // Phase 13 — CHAL-09, D-05, D-06
    case communityFeed(UserChallenge)      // Phase 14 — CHAL-25
    case communityGoals(UserChallenge)     // Phase 15 — UIADD-04, C4
    case analytics                         // Phase 26 — ANLT-02/03/04
}
