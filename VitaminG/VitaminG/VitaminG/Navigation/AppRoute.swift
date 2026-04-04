import Foundation

/// Type-safe route enum for NavigationStack.
/// Phase 2: goalDetail case added per D-08.
/// Phase 3: stats and settings cases added for stats screen and notification settings navigation.
enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats      // Phase 3: stats screen
    case settings   // Phase 3: notification settings
}
