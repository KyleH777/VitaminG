import Foundation

/// Type-safe route enum for NavigationStack.
/// Phase 2: goalDetail case added per D-08.
/// Phase 3: stats and settings cases added for stats screen and notification settings navigation.
/// Phase 7: profile case added for programmatic navigation to the profile tab (D-11, deep link support).
enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats      // Phase 3: stats screen
    case settings   // Phase 3: notification settings
    case profile    // Phase 7: profile tab deep link navigation
    case publicProfile(recordID: String)   // Phase 10 — D-04, D-05; sheet-only, never pushed onto NavigationStack
}
