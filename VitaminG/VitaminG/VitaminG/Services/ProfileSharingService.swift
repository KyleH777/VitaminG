import CloudKit
import Foundation

/// Manages CloudKit public database writes for profile sharing.
/// Only displayName and avatarColorHex are shared publicly — never photoData or personal data.
/// Per T-07-08: explicit field allowlist enforced in publishProfile to prevent accidental data leakage.
enum ProfileSharingService {

    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    private static let recordType = "PublicProfile"

    /// UserDefaults key tracking timestamps of follow writes for rate-limiting.
    private static let followWriteTimesKey = "vg_follow_write_times"

    /// Test seam: when non-nil, replaces fetchFollowState logic.
    /// Set in unit tests to avoid CloudKit. nil in production.
    static var fetchFollowStateOverride: ((String, String) async throws -> Bool)? = nil

    /// Test seam: when non-nil, replaces writeFollow logic.
    /// Set in unit tests to avoid CloudKit. nil in production.
    static var writeFollowOverride: ((String, String) async throws -> Void)? = nil

    /// Saves a PublicProfile record to CloudKit public database.
    /// Returns the recordID.recordName string for storage in UserProfile.cloudKitPublicRecordID.
    /// If cloudKitPublicRecordID already exists, updates the existing record instead of creating a new one.
    ///
    /// SECURITY: Only displayName, avatarColorHex, username, streakLength, goalCount, and motto
    /// are written. photoData, goal descriptions, inspiration text, and completion data are never
    /// included (T-07-08). New Phase 22 fields (streakLength, goalCount, motto) are only written
    /// when the caller explicitly provides non-default values — existing records are not clobbered
    /// (Pitfall 3 in 22-RESEARCH.md, T-22-02-02 mitigation).
    ///
    /// WRITE PATH COORDINATION (Plan 17-03): When username is non-nil, this function writes the username
    /// field to the same PublicProfile record targeted by UsernameLookupService.writeUsername (both use
    /// CKRecord.ID(recordName: appleUserID) as the record name). Call this AFTER writeUsername to confirm
    /// the claim. Passing username: nil for existing call sites that do not set a username is safe —
    /// the field is simply not updated.
    static func publishProfile(
        displayName: String?,
        avatarColorHex: String?,
        username: String? = nil,
        existingRecordID: String?,
        streakLength: Int = 0,    // NEW Phase 22 (D-05) — only written when > 0
        goalCount: Int = 0,       // NEW Phase 22 (D-05) — only written when > 0
        motto: String? = nil      // NEW Phase 22 (D-07) — only written when non-nil
    ) async throws -> String {
        let publicDB = CKContainer(identifier: containerID).publicCloudDatabase

        let record: CKRecord
        if let existingID = existingRecordID {
            // Update existing record
            let recordID = CKRecord.ID(recordName: existingID)
            record = try await publicDB.record(for: recordID)
        } else {
            // Create new record
            record = CKRecord(recordType: recordType)
        }

        // Explicit field allowlist — only these fields are ever written to the public record
        record["displayName"] = (displayName ?? "") as CKRecordValue
        record["avatarColorHex"] = (avatarColorHex ?? "") as CKRecordValue

        // Write username if provided (Plan 17-03: username claim coordination)
        if let username = username {
            record["username"] = username.lowercased() as CKRecordValue
        }

        // Phase 22: write new fields ONLY when caller passed non-default values.
        // Prevents clobbering existing CK values when caller has not opted into updating them.
        if streakLength > 0 {
            record["streakLength"] = Int64(streakLength) as CKRecordValue
        }
        if goalCount > 0 {
            record["goalCount"] = Int64(goalCount) as CKRecordValue
        }
        if let motto = motto {
            record["motto"] = InputSanitizer.sanitizeForPublic(motto) as CKRecordValue
        }

        let savedRecord = try await publicDB.save(record)
        SecurityAuditLog.shared.log(AuditEvent(eventType: .profileEdited))
        return savedRecord.recordID.recordName
    }

    /// Reads a PublicProfile record from CloudKit public database by recordID.
    /// Returns a PublicProfileData struct with all Phase 22 fields mapped from the CKRecord.
    /// cheersGivenCount is set to 0 here — callers add it via CommunityService.fetchApplauseGivenCount.
    /// Throws CKError on network failure or missing record; callers handle CKError.unknownItem.
    static func fetchProfile(recordID: String) async throws -> PublicProfileData {
        let publicDB = CKContainer(identifier: containerID).publicCloudDatabase
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDB.record(for: ckRecordID)
        let displayName = record["displayName"] as? String
        let avatarColorHex = record["avatarColorHex"] as? String
        let username = record["username"] as? String
        let motto = record["motto"] as? String
        let streakLength = Int((record["streakLength"] as? Int64) ?? 0)
        let goalCount = Int((record["goalCount"] as? Int64) ?? 0)
        return PublicProfileData(
            displayName: displayName,
            avatarColorHex: avatarColorHex,
            username: username,
            motto: motto,
            streakLength: streakLength,
            goalCount: goalCount,
            cheersGivenCount: 0   // Fetched separately by caller via CommunityService
        )
    }

    /// Deletes the PublicProfile record from CloudKit public database.
    /// Silently succeeds if record does not exist (already deleted).
    /// Per D-06: going private removes the public record to prevent orphaned accessible data.
    static func unpublishProfile(recordID: String) async throws {
        let publicDB = CKContainer(identifier: containerID).publicCloudDatabase
        let ckRecordID = CKRecord.ID(recordName: recordID)

        do {
            try await publicDB.deleteRecord(withID: ckRecordID)
        } catch let error as CKError where error.code == .unknownItem {
            // Record already deleted — not an error
        }
    }

    // MARK: - Follow State (Phase 22 PROF-02)

    /// Returns true if a Follow record exists for the given (follower, followee) pair.
    /// The record name is deterministic: "\(followerUsername)_\(followeeUsername)" (D-13).
    /// Returns false when CKError.unknownItem (no follow exists). Rethrows other errors.
    static func fetchFollowState(followerUsername: String, followeeUsername: String) async throws -> Bool {
        if let override = fetchFollowStateOverride {
            return try await override(followerUsername, followeeUsername)
        }
        let db = CKContainer(identifier: containerID).publicCloudDatabase
        let recordName = "\(followerUsername)_\(followeeUsername)"
        let recordID = CKRecord.ID(recordName: recordName)
        do {
            _ = try await db.record(for: recordID)
            return true
        } catch let e as CKError where e.code == .unknownItem {
            return false
        }
    }

    /// Creates a Follow record for (follower → followee). Idempotent — if the record already
    /// exists, returns without creating a duplicate. Uses a deterministic record name
    /// "\(followerUsername)_\(followeeUsername)" per D-13.
    ///
    /// Rate limit: enforced via UserDefaults key `vg_follow_write_times` — maximum 10 follow
    /// writes per rolling hour. Throws NSError with domain "VGRateLimit" code 429 on breach.
    static func writeFollow(followerUsername: String, followeeUsername: String) async throws {
        if let override = writeFollowOverride {
            return try await override(followerUsername, followeeUsername)
        }
        let db = CKContainer(identifier: containerID).publicCloudDatabase
        let recordName = "\(followerUsername)_\(followeeUsername)"
        let recordID = CKRecord.ID(recordName: recordName)

        // Idempotency check — if record already exists, return immediately.
        do {
            _ = try await db.record(for: recordID)
            return  // Already following — idempotent
        } catch let e as CKError where e.code == .unknownItem {
            // Record does not exist — proceed to rate-limit check and creation.
        }

        // Rate-limit guard: max 10 follow writes per rolling hour (T-22-02-03 control).
        let now = Date().timeIntervalSince1970
        let windowStart = now - 3600.0
        let rawTimes = UserDefaults.standard.array(forKey: followWriteTimesKey) as? [Double] ?? []
        let recentTimes = rawTimes.filter { $0 >= windowStart }
        if recentTimes.count >= 10 {
            throw NSError(
                domain: "VGRateLimit",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: "Follow limit reached. Try again in an hour."]
            )
        }

        // Create Follow record.
        let record = CKRecord(recordType: "Follow", recordID: recordID)
        record["followerUsername"] = InputSanitizer.sanitizeForPublic(followerUsername) as CKRecordValue
        record["followeeUsername"] = InputSanitizer.sanitizeForPublic(followeeUsername) as CKRecordValue
        record["createdAt"] = Int64(Date().timeIntervalSince1970) as CKRecordValue

        _ = try await db.save(record)

        // Record successful write timestamp for rate limiting.
        var updatedTimes = recentTimes
        updatedTimes.append(Date().timeIntervalSince1970)
        UserDefaults.standard.set(updatedTimes, forKey: followWriteTimesKey)
    }
}
