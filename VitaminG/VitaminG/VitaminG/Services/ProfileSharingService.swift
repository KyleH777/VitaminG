import CloudKit

/// Manages CloudKit public database writes for profile sharing.
/// Only displayName and avatarColorHex are shared publicly — never photoData or personal data.
/// Per T-07-08: explicit field allowlist enforced in publishProfile to prevent accidental data leakage.
enum ProfileSharingService {

    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    private static let recordType = "PublicProfile"

    /// Saves a PublicProfile record to CloudKit public database.
    /// Returns the recordID.recordName string for storage in UserProfile.cloudKitPublicRecordID.
    /// If cloudKitPublicRecordID already exists, updates the existing record instead of creating a new one.
    ///
    /// SECURITY: Only displayName, avatarColorHex, and username are written. photoData, goal descriptions,
    /// inspiration text, and completion data are never included (T-07-08).
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
        existingRecordID: String?
    ) async throws -> String {
        let container = CKContainer(identifier: containerID)
        let publicDB = container.publicCloudDatabase

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

        let savedRecord = try await publicDB.save(record)
        return savedRecord.recordID.recordName
    }

    /// Reads a PublicProfile record from CloudKit public database by recordID.
    /// Returns only displayName and avatarColorHex — the two fields written by publishProfile.
    /// Throws CKError on network failure or missing record; callers handle CKError.unknownItem.
    static func fetchProfile(recordID: String) async throws -> (displayName: String?, avatarColorHex: String?) {
        let container = CKContainer(identifier: containerID)
        let publicDB = container.publicCloudDatabase
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDB.record(for: ckRecordID)
        let displayName = record["displayName"] as? String
        let avatarColorHex = record["avatarColorHex"] as? String
        return (displayName: displayName, avatarColorHex: avatarColorHex)
    }

    /// Deletes the PublicProfile record from CloudKit public database.
    /// Silently succeeds if record does not exist (already deleted).
    /// Per D-06: going private removes the public record to prevent orphaned accessible data.
    static func unpublishProfile(recordID: String) async throws {
        let container = CKContainer(identifier: containerID)
        let publicDB = container.publicCloudDatabase
        let ckRecordID = CKRecord.ID(recordName: recordID)

        do {
            try await publicDB.deleteRecord(withID: ckRecordID)
        } catch let error as CKError where error.code == .unknownItem {
            // Record already deleted — not an error
        }
    }
}
