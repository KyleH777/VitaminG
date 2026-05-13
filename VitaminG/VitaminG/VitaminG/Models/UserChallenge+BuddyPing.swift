import Foundation

// MARK: - UserChallenge + BuddyPing (CHAL-22)
//
// Extension on UserChallenge (SchemaV4) providing canSendBuddyPing — the single source of truth
// for the 24-hour cooldown gate. Used by BuddyAccountabilityModuleView (Plan 14-08) and
// CravingToolsModuleView (Plan 14-06 fallback, will migrate to this extension).
//
// T-14-32 mitigation: 24h cooldown prevents rapid-tap ping spam; keyed per challenge UUID
// so multi-challenge ping is bounded by N challenges.

extension UserChallenge {
    /// Returns true when the user is allowed to send a buddy ping (no prior ping in the last 24h).
    /// Single source of truth for the cooldown gate — used by BuddyAccountabilityModuleView
    /// and CravingToolsModuleView.
    var canSendBuddyPing: Bool {
        guard let last = buddyPingLastSent else { return true }
        return Date().timeIntervalSince(last) >= 86_400  // 24 hours in seconds
    }
}
