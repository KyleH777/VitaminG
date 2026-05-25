import Foundation

/// Namespace-only service for persisting the local block list to UserDefaults.
/// Blocked user Apple IDs are stored as a JSON-encoded [String] under key "vg_blockedUserIDs".
/// Uses recordID as the Apple User ID per UsernameLookupService convention.
enum BlockListService {

    private static let key = "vg_blockedUserIDs"

    // MARK: - Read

    /// Returns the full set of blocked Apple User IDs.
    static func blockedUserIDs() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: key),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(array)
    }

    /// Returns true if the given Apple User ID is in the block list.
    static func isBlocked(appleUserID: String) -> Bool {
        blockedUserIDs().contains(appleUserID)
    }

    /// Returns all blocked Apple User IDs sorted alphabetically.
    static func allBlocked() -> [String] {
        Array(blockedUserIDs()).sorted()
    }

    // MARK: - Write

    /// Adds the given Apple User ID to the block list and persists it.
    static func blockUser(appleUserID: String) {
        var ids = blockedUserIDs()
        ids.insert(appleUserID)
        if let data = try? JSONEncoder().encode(Array(ids)) {
            UserDefaults.standard.set(data, forKey: key)
        }
        SecurityAuditLog.shared.log(AuditEvent(eventType: .userBlocked, targetUserID: appleUserID))
    }

    /// Removes the given Apple User ID from the block list and persists the result.
    static func unblockUser(appleUserID: String) {
        var ids = blockedUserIDs()
        ids.remove(appleUserID)
        if let data = try? JSONEncoder().encode(Array(ids)) {
            UserDefaults.standard.set(data, forKey: key)
        }
        SecurityAuditLog.shared.log(AuditEvent(eventType: .userUnblocked, targetUserID: appleUserID))
    }
}
