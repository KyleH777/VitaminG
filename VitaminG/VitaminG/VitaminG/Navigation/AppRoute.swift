import Foundation

/// Type-safe route enum for NavigationStack.
/// Phase 2: goalDetail case added per D-08.
enum AppRoute: Hashable {
    case goalDetail(Goal)
}
