import CloudKit
import Foundation
import SwiftData

/// Manages CloudKit public database operations for the PublicGoal record type.
/// Owns all CRUD, Discover search, participant count increment, backfill, and sync.
/// No instances — static methods only, matching CommunityService and ProfileSharingService idiom.
/// IMPORTANT: Use CKContainer(identifier: containerID) with explicit containerID, NOT the default container.
/// — matches established pattern in ProfileSharingService and UsernameLookupService (Phase 17).
enum PublicGoalService {

    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    private static let recordType = "PublicGoal"

    // MARK: - Test Seams

    /// Test seam: when non-nil, replaces writePublicGoal CloudKit logic.
    /// Set in unit tests to avoid hitting CloudKit. nil in production.
    static var writePublicGoalOverride: ((Goal, String) async throws -> String)? = nil

    /// Test seam: when non-nil, replaces deletePublicGoal CloudKit logic.
    static var deletePublicGoalOverride: ((String) async throws -> Void)? = nil

    /// Test seam: when non-nil, replaces searchGoals CloudKit logic.
    static var searchGoalsOverride: ((String) async throws -> [DiscoverGoalResult])? = nil

    /// Test seam: when non-nil, replaces searchPeople CloudKit logic.
    static var searchPeopleOverride: ((String) async throws -> [DiscoverPersonResult])? = nil

    /// Test seam: when non-nil, replaces fetchGoalsForUser CloudKit logic.
    static var fetchGoalsForUserOverride: ((String) async throws -> [PublicGoalItem])? = nil

    /// Test seam: when non-nil, replaces syncOwnedPublicGoals CloudKit logic.
    /// In test environments, set to a no-op closure to prevent CKContainer init crash.
    static var syncOwnedPublicGoalsOverride: (([Goal]) async -> Void)? = nil

    // MARK: - Write / Delete

    /// Creates or replaces a PublicGoal CKRecord in the public CloudKit database.
    /// Uses goal.id.uuidString as the stable record name (D-09).
    /// Every String field is sanitized via InputSanitizer.sanitizeForPublic (T-22-02-07).
    /// Returns the recordName so the caller can stamp Goal.cloudKitPublicGoalRecordID.
    @discardableResult
    static func writePublicGoal(goal: Goal, creatorUsername: String) async throws -> String {
        if let override = writePublicGoalOverride {
            return try await override(goal, creatorUsername)
        }

        let db = CKContainer(identifier: containerID).publicCloudDatabase
        let recordName = goal.id.uuidString
        let recordID = CKRecord.ID(recordName: recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["title"] = InputSanitizer.sanitizeForPublic(goal.title ?? "") as CKRecordValue
        record["category"] = InputSanitizer.sanitizeForPublic(goal.category ?? "") as CKRecordValue
        record["creatorUsername"] = InputSanitizer.sanitizeForPublic(creatorUsername) as CKRecordValue
        record["participantCount"] = Int64(1) as CKRecordValue   // Creator counts as first participant
        record["progressPercent"] = Int64(0) as CKRecordValue    // 0% on creation
        record["durationDays"] = Int64(goal.durationDays ?? 0) as CKRecordValue
        record["creationEpoch"] = Int64((goal.creationDate ?? Date()).timeIntervalSince1970) as CKRecordValue

        do {
            _ = try await db.save(record)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // One retry on conflict — same pattern as CommunityService.writeApplause
            _ = try await db.save(record)
        }

        return recordName
    }

    /// Deletes the PublicGoal CKRecord with the given recordName.
    /// Swallows CKError.unknownItem — already deleted is not an error (D-10).
    static func deletePublicGoal(recordName: String) async throws {
        do {
            if let override = deletePublicGoalOverride {
                try await override(recordName)
                return
            }
            let db = CKContainer(identifier: containerID).publicCloudDatabase
            let recordID = CKRecord.ID(recordName: recordName)
            try await db.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            // Already deleted — not an error (D-10 idempotent delete)
        }
    }

    // MARK: - Search

    /// Searches PublicGoal records by title substring (case/diacritic insensitive).
    /// Uses NSPredicate(format: "title CONTAINS[cd] %@", keyword).
    /// resultsLimit: 25 hard cap (T-22-02-06 DoS mitigation).
    static func searchGoals(keyword: String) async throws -> [DiscoverGoalResult] {
        if let override = searchGoalsOverride {
            return try await override(keyword)
        }

        let db = CKContainer(identifier: containerID).publicCloudDatabase
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", keyword)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 25)
        let records = results.compactMap { try? $0.1.get() }
        return records.map { mapRecordToDiscoverGoalResult($0) }
    }

    /// Searches PublicProfile records by username prefix (case/diacritic insensitive).
    /// Uses NSPredicate(format: "username BEGINSWITH[cd] %@", usernamePrefix).
    /// resultsLimit: 25 hard cap (T-22-02-06 DoS mitigation).
    static func searchPeople(usernamePrefix: String) async throws -> [DiscoverPersonResult] {
        if let override = searchPeopleOverride {
            return try await override(usernamePrefix)
        }

        let db = CKContainer(identifier: containerID).publicCloudDatabase
        let predicate = NSPredicate(format: "username BEGINSWITH[cd] %@", usernamePrefix)
        let query = CKQuery(recordType: "PublicProfile", predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 25)
        let records = results.compactMap { try? $0.1.get() }
        return records.map { mapRecordToDiscoverPersonResult($0) }
    }

    // MARK: - Fetch

    /// Fetches all PublicGoal records for a given creatorUsername.
    /// resultsLimit: 50 — typical per-user goal count.
    static func fetchGoalsForUser(username: String) async throws -> [PublicGoalItem] {
        if let override = fetchGoalsForUserOverride {
            return try await override(username)
        }

        let db = CKContainer(identifier: containerID).publicCloudDatabase
        let predicate = NSPredicate(format: "creatorUsername == %@", username)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 50)
        let records = results.compactMap { try? $0.1.get() }
        return records.map { mapRecordToPublicGoalItem($0) }
    }

    // MARK: - Participant Count

    /// Increments the participantCount field of a PublicGoal record by 1.
    /// Non-throwing — fire-and-forget. All errors are silently swallowed (D-16).
    /// Uses fetch + increment + save with one retry on .serverRecordChanged.
    /// Pattern mirrors CommunityService.toggleReaction (lines 73–96).
    static func incrementParticipantCount(recordName: String) async {
        let db = CKContainer(identifier: containerID).publicCloudDatabase
        let recordID = CKRecord.ID(recordName: recordName)
        do {
            let record = try await db.record(for: recordID)
            let current = (record["participantCount"] as? Int64) ?? 0
            record["participantCount"] = current + 1 as CKRecordValue
            _ = try await db.save(record)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // One retry on conflict — mirror toggleReaction retry pattern
            do {
                let record = try await db.record(for: recordID)
                let current = (record["participantCount"] as? Int64) ?? 0
                record["participantCount"] = current + 1 as CKRecordValue
                _ = try await db.save(record)
            } catch {
                // Silently discard (D-16: count failure must not affect caller)
            }
        } catch {
            // Silently discard — fire-and-forget (D-16)
        }
    }

    // MARK: - Backfill

    /// Iterates local goals and writes PublicGoal records for any public goal that does not
    /// yet have a cloudKitPublicGoalRecordID. Sets Goal.cloudKitPublicGoalRecordID on success.
    /// Per-goal failures are silently logged; loop continues (D-11 — best-effort backfill).
    /// - Parameters:
    ///   - goals: All local Goal objects to inspect.
    ///   - context: ModelContext used to persist cloudKitPublicGoalRecordID after write.
    ///   - creatorUsername: Username of the current user (written to the CK record).
    ///   - writeOverride: Test seam — when non-nil, replaces the real CloudKit write.
    static func backfillPublicGoals(
        goals: [Goal],
        context: ModelContext,
        creatorUsername: String,
        writeOverride: ((Goal, String) async throws -> String)? = nil
    ) async {
        for goal in goals {
            guard goal.isPublic == true, goal.cloudKitPublicGoalRecordID == nil else { continue }
            do {
                let recordName: String
                if let override = writeOverride {
                    recordName = try await override(goal, creatorUsername)
                } else {
                    recordName = try await writePublicGoal(goal: goal, creatorUsername: creatorUsername)
                }
                if !recordName.isEmpty {
                    goal.cloudKitPublicGoalRecordID = recordName
                    try? context.save()
                }
            } catch {
                // Silently log per-goal failure — continue backfill (D-11)
                #if DEBUG
                print("[PublicGoalService] backfill failed for goal \(goal.id.uuidString): \(error)")
                #endif
            }
        }
    }

    // MARK: - Sync

    /// Refreshes progressPercent on owned public goals in CloudKit.
    /// Iterates goals where isPublic == true AND cloudKitPublicGoalRecordID != nil.
    /// On any per-goal error: silently logs and continues (D-12 — fire-and-forget).
    static func syncOwnedPublicGoals(goals: [Goal]) async {
        if let override = syncOwnedPublicGoalsOverride {
            await override(goals)
            return
        }
        let db = CKContainer(identifier: containerID).publicCloudDatabase
        for goal in goals {
            guard goal.isPublic == true,
                  let recordName = goal.cloudKitPublicGoalRecordID else { continue }

            let recordID = CKRecord.ID(recordName: recordName)
            do {
                let record = try await db.record(for: recordID)
                // Compute current progress — number of completionEvents / durationDays
                // For MVP: use completion event count vs duration as percent proxy.
                let completionCount = goal.completionEvents?.count ?? 0
                let duration = max(1, goal.durationDays ?? 1)
                let progressPercent = min(100, Int((Double(completionCount) / Double(duration)) * 100))
                record["progressPercent"] = Int64(progressPercent) as CKRecordValue
                _ = try await db.save(record)
            } catch {
                // Silently log per-goal failure — continue sync (D-12)
                #if DEBUG
                print("[PublicGoalService] sync failed for goal \(goal.id.uuidString): \(error)")
                #endif
            }
        }
    }

    // MARK: - Private Mappers

    private static func mapRecordToDiscoverGoalResult(_ record: CKRecord) -> DiscoverGoalResult {
        DiscoverGoalResult(
            id: record.recordID.recordName,
            title: (record["title"] as? String) ?? "",
            category: (record["category"] as? String) ?? "",
            creatorUsername: (record["creatorUsername"] as? String) ?? "",
            participantCount: Int((record["participantCount"] as? Int64) ?? 0),
            progressPercent: Int((record["progressPercent"] as? Int64) ?? 0)
        )
    }

    private static func mapRecordToDiscoverPersonResult(_ record: CKRecord) -> DiscoverPersonResult {
        DiscoverPersonResult(
            id: record.recordID.recordName,
            username: (record["username"] as? String) ?? "",
            avatarColorHex: (record["avatarColorHex"] as? String) ?? "",
            goalCount: Int((record["goalCount"] as? Int64) ?? 0),
            cheersGivenCount: Int((record["cheersGivenCount"] as? Int64) ?? 0)
        )
    }

    private static func mapRecordToPublicGoalItem(_ record: CKRecord) -> PublicGoalItem {
        PublicGoalItem(
            id: record.recordID.recordName,
            title: (record["title"] as? String) ?? "",
            category: (record["category"] as? String) ?? "",
            creatorUsername: (record["creatorUsername"] as? String) ?? "",
            participantCount: Int((record["participantCount"] as? Int64) ?? 0),
            progressPercent: Int((record["progressPercent"] as? Int64) ?? 0),
            durationDays: Int((record["durationDays"] as? Int64) ?? 0),
            creationEpoch: Int((record["creationEpoch"] as? Int64) ?? 0)
        )
    }
}
