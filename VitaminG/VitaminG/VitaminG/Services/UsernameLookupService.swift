import CloudKit

/// Provides async CloudKit public database operations for username uniqueness checking,
/// username claiming, and post-save race condition verification.
///
/// All functions target the PublicProfile record type in the VitaminG CloudKit public database.
/// Username values are always lowercased before query or write to ensure case-insensitive uniqueness.
///
/// SECURITY (T-17-03-02): Callers MUST validate the username character set before calling any
/// function here. NSPredicate uses parameterized binding (%@) — not string concatenation —
/// which prevents injection. Character validation is an additional defense-in-depth measure.
///
/// SECURITY (T-17-03-01): writeUsername uses CKRecord.ID(recordName: appleUserID) so the
/// PublicProfile record is tied to the user's Apple-issued UID — not user-controlled input.
enum UsernameLookupService {

    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    private static let recordType = "PublicProfile"

    // MARK: - Availability Check

    /// Returns true if the given username is already taken in CloudKit public DB.
    /// - Parameter username: The username to check (caller must have validated charset first).
    /// - Returns: true if taken; false if available.
    /// - Throws: CKError on CloudKit failure (network, quota, etc.)
    static func isUsernameTaken(_ username: String) async throws -> Bool {
        let container = CKContainer(identifier: containerID)
        let db = container.publicCloudDatabase
        let predicate = NSPredicate(format: "username == %@", username.lowercased())
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 1)
        return !results.isEmpty
    }

    // MARK: - Claim Username

    /// Writes the username to the PublicProfile record identified by appleUserID.
    /// Uses CKRecord.ID(recordName: appleUserID) to tie the record to the user's Apple identity.
    /// If the record does not yet exist, creates a new one with that record name.
    /// If it already exists, updates the username field only.
    ///
    /// WRITE PATH COORDINATION: Both writeUsername and ProfileSharingService.publishProfile
    /// use CKRecord.ID(recordName: appleUserID) as the record name, targeting the SAME record.
    /// claimUsername() in OnboardingViewModel calls writeUsername() FIRST to establish the claim.
    /// completeOnboarding() then calls publishProfile(username:) which overwrites the same record's
    /// username field with the same lowercased value — this is intentional and safe.
    ///
    /// - Parameters:
    ///   - username: The username to claim (will be lowercased before write).
    ///   - appleUserID: The Apple-issued user identifier; used as the CloudKit record name.
    /// - Returns: The CKRecord.ID of the saved record.
    /// - Throws: CKError on CloudKit failure.
    static func writeUsername(_ username: String, appleUserID: String) async throws -> CKRecord.ID {
        let container = CKContainer(identifier: containerID)
        let db = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: appleUserID)

        let record: CKRecord
        do {
            record = try await db.record(for: recordID)
        } catch let ckError as CKError where ckError.code == .unknownItem {
            // Record does not yet exist — create it with the appleUserID record name
            record = CKRecord(recordType: recordType, recordID: recordID)
        }

        record["username"] = username.lowercased() as CKRecordValue

        let savedRecord = try await db.save(record)
        return savedRecord.recordID
    }

    // MARK: - Race Condition Verification (D-17)

    /// Counts how many PublicProfile records share the given username.
    /// A count of 1 means this device is the sole owner.
    /// A count > 1 means a race condition occurred — two devices claimed the same username
    /// simultaneously. Callers should delete this device's record and prompt retry.
    ///
    /// Uses resultsLimit: 2 — we only need to distinguish 0, 1, or >1.
    ///
    /// - Parameter username: The username to count (will be lowercased).
    /// - Returns: Number of matching records (0, 1, or 2).
    /// - Throws: CKError on CloudKit failure.
    static func countRecordsWithUsername(_ username: String) async throws -> Int {
        let container = CKContainer(identifier: containerID)
        let db = container.publicCloudDatabase
        let predicate = NSPredicate(format: "username == %@", username.lowercased())
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 2)
        return results.count
    }
}
