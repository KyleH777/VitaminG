import Foundation

/// Gate service for tracking which streak milestone celebrations have been shown for each goal.
///
/// Mirrors the ApplauseGate pattern from CommunityHubViewModel:
/// - Static enum (no instances)
/// - UserDefaults-backed JSON persistence
/// - Composite key format: "\(goalID.uuidString)-\(threshold)"
///
/// All six thresholds ([7, 14, 30, 60, 90, 365]) are independently trackable per goalID.
/// Threat model T-23-01-01: accept — soft gate, re-showing a celebratory screen is low risk.
enum StreakMilestoneGate {
    /// The six streak milestone thresholds (in days) tracked by this gate.
    static let goalStreakThresholds: [Int] = [7, 14, 30, 60, 90, 365]

    private static let key = "vg_streakMilestonesShown"

    /// Returns true if the milestone celebration for the given goalID + threshold has already been shown.
    static func hasShown(goalID: UUID, threshold: Int, defaults: UserDefaults = .standard) -> Bool {
        let compositeKey = "\(goalID.uuidString)-\(threshold)"
        guard let data = defaults.data(forKey: key),
              let set = try? JSONDecoder().decode(Set<String>.self, from: data)
        else { return false }
        return set.contains(compositeKey)
    }

    /// Marks the milestone celebration for the given goalID + threshold as shown.
    static func markShown(goalID: UUID, threshold: Int, defaults: UserDefaults = .standard) {
        var set: Set<String> = []
        if let data = defaults.data(forKey: key),
           let existing = try? JSONDecoder().decode(Set<String>.self, from: data) {
            set = existing
        }
        set.insert("\(goalID.uuidString)-\(threshold)")
        if let encoded = try? JSONEncoder().encode(set) {
            defaults.set(encoded, forKey: key)
        }
    }
}
