import CloudKit
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum ReactionType: String {
    case thumbsUp
    case heart
    case fire
    var fieldKey: String {
        switch self {
        case .thumbsUp: return "thumbsUpCount"
        case .heart:    return "heartCount"
        case .fire:     return "fireCount"
        }
    }
}

enum CommunityService {
    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    static let postRecordType = "CommunityPost"
    static let reactionRecordType = "CommunityReaction"
    static let glimpseRecordType = "GoalGlimpse"
    static let presenceRecordType = "UserPresence"
    static let applauseRecordType = "Applause"
    static let replyRecordType = "CommunityReply"

    // MARK: - Fetch posts by category (CHAL-13)
    static func fetchPosts(category: String, limit: Int = 50) async throws -> [CKRecord] {
        let container = CKContainer.default()
        let db = container.publicCloudDatabase
        let predicate = NSPredicate(format: "category == %@ AND reportCount < 3", category)
        let query = CKQuery(recordType: postRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let (results, _) = try await db.records(matching: query, resultsLimit: limit)
        return results.compactMap { try? $0.1.get() }
    }

    // MARK: - Create post (CHAL-16, CHAL-17)
    static func createPost(
        text: String,
        imageData: Data?,
        category: String,
        authorDisplayName: String?,
        authorColorHex: String?
    ) async throws -> CKRecord {
        let container = CKContainer.default()
        let record = CKRecord(recordType: postRecordType)
        record["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
        record["category"] = category as CKRecordValue
        record["authorDisplayName"] = (InputSanitizer.sanitizeForPublic(authorDisplayName ?? "Anonymous")) as CKRecordValue
        record["authorColorHex"] = (authorColorHex ?? "") as CKRecordValue
        record["thumbsUpCount"] = 0 as CKRecordValue
        record["heartCount"] = 0 as CKRecordValue
        record["reportCount"] = 0 as CKRecordValue
        record["reporterIDsJSON"] = "[]" as CKRecordValue

        if let imageData = imageData,
           let compressed = compressToJPEG(imageData, maxBytes: 500_000) {
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".jpg")
            try compressed.write(to: tmpURL)
            defer { try? FileManager.default.removeItem(at: tmpURL) }
            record["photoAsset"] = CKAsset(fileURL: tmpURL)
            return try await container.publicCloudDatabase.save(record)
        }

        return try await container.publicCloudDatabase.save(record)
    }

    // MARK: - Toggle reaction (CHAL-14)
    static func toggleReaction(
        recordID: CKRecord.ID,
        reactionType: ReactionType,
        add: Bool
    ) async throws -> CKRecord {
        let container = CKContainer.default()
        let db = container.publicCloudDatabase
        do {
            let record = try await db.record(for: recordID)
            let key = reactionType.fieldKey
            let current = (record[key] as? Int) ?? 0
            let newValue = max(0, add ? current + 1 : current - 1)
            record[key] = newValue as CKRecordValue
            return try await db.save(record)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // One retry on conflict — fetch latest and re-apply
            let record = try await db.record(for: recordID)
            let key = reactionType.fieldKey
            let current = (record[key] as? Int) ?? 0
            let newValue = max(0, add ? current + 1 : current - 1)
            record[key] = newValue as CKRecordValue
            return try await db.save(record)
        }
    }

    // MARK: - Report post (CHAL-15)
    /// Returns the new report count after de-duplicated insert.
    static func reportPost(recordID: CKRecord.ID, reporterID: String) async throws -> Int {
        let container = CKContainer.default()
        let db = container.publicCloudDatabase

        // Extracted helper — applies reporter ID mutation to a fetched record.
        // Returns nil when reporterID is already present (duplicate guard).
        func applyReport(to record: CKRecord) -> (CKRecord, Int)? {
            let existingJSON = (record["reporterIDsJSON"] as? String) ?? "[]"
            var reporters = (try? JSONDecoder().decode([String].self,
                from: Data(existingJSON.utf8))) ?? []
            guard !reporters.contains(reporterID) else { return nil }
            reporters.append(reporterID)
            if let data = try? JSONEncoder().encode(reporters),
               let json = String(data: data, encoding: .utf8) {
                record["reporterIDsJSON"] = json as CKRecordValue
            }
            let count = reporters.count
            record["reportCount"] = count as CKRecordValue
            return (record, count)
        }

        do {
            let record = try await db.record(for: recordID)
            guard let (updated, count) = applyReport(to: record) else {
                return (record["reportCount"] as? Int) ?? 0
            }
            _ = try await db.save(updated)
            return count
        } catch let error as CKError where error.code == .serverRecordChanged {
            // One retry on conflict — mirror toggleReaction retry pattern
            let record = try await db.record(for: recordID)
            guard let (updated, count) = applyReport(to: record) else {
                return (record["reportCount"] as? Int) ?? 0
            }
            _ = try await db.save(updated)
            return count
        }
    }

    // MARK: - Check-in photo (UIADD-04, C3)
    static func postCheckInPhoto(_ imageData: Data, challengeCategory: String) async throws -> CKRecord {
        let compressed = compressToJPEG(imageData, maxBytes: 800_000) ?? imageData
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try compressed.write(to: tmpURL)
        let record = CKRecord(recordType: "CheckInPhoto")
        record["category"] = challengeCategory as CKRecordValue
        record["photoAsset"] = CKAsset(fileURL: tmpURL)
        record["creationEpoch"] = Int(Date().timeIntervalSince1970) as CKRecordValue
        return try await CKContainer.default().publicCloudDatabase.save(record)
    }

    // MARK: - JPEG compression helper
    static func compressToJPEG(_ data: Data, maxBytes: Int) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        var quality: CGFloat = 0.8
        var compressed = image.jpegData(compressionQuality: quality) ?? data
        while compressed.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            compressed = image.jpegData(compressionQuality: quality) ?? compressed
        }
        return compressed
        #else
        return data
        #endif
    }

    // MARK: - Resize and compress helper (AUTH-04)
    /// Resizes the image to fit within maxDimension on its longest side, then compresses to JPEG.
    /// Reduces resolution and file size before any persistence — T-17-04-01 mitigation.
    static func resizeAndCompress(_ image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.75) -> Data? {
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: quality)
    }
}

// MARK: - Phase 21 Community Hub methods

extension CommunityService {

    // MARK: - GoalGlimpse

    /// Upserts a GoalGlimpse record for username + today's dayKey (one record per user per day).
    /// Fire-and-forget — all errors are caught silently (called from GoalViewModel.addCheckIn).
    static func writeGlimpse(
        username: String,
        goalTitle: String,
        progressPercent: Int,
        authorColorHex: String,
        photoData: Data? = nil
    ) async {
        let db = CKContainer.default().publicCloudDatabase
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let todayKey = formatter.string(from: Date())

        let sanitizedUsername = InputSanitizer.sanitizeForPublic(username)
        let sanitizedTitle = InputSanitizer.sanitizeForPublic(goalTitle)
        let sanitizedColorHex = InputSanitizer.sanitizeForPublic(authorColorHex)

        do {
            // Upsert: fetch existing record for this user+dayKey, or create new.
            let predicate = NSPredicate(format: "username == %@ AND dayKey == %@",
                                        sanitizedUsername, todayKey)
            let query = CKQuery(recordType: glimpseRecordType, predicate: predicate)
            let (results, _) = try await db.records(matching: query, resultsLimit: 1)
            let existing = results.first.flatMap { try? $0.1.get() }

            let record: CKRecord
            if let existingRecord = existing {
                record = existingRecord
            } else {
                record = CKRecord(recordType: glimpseRecordType)
            }

            record["username"] = sanitizedUsername as CKRecordValue
            record["goalTitle"] = sanitizedTitle as CKRecordValue
            record["progressPercent"] = Int64(progressPercent) as CKRecordValue
            record["authorColorHex"] = sanitizedColorHex as CKRecordValue
            record["dayKey"] = todayKey as CKRecordValue

            // Handle optional photo
            if let photoData = photoData,
               let compressed = compressToJPEG(photoData, maxBytes: 500_000) {
                let tmpURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                try compressed.write(to: tmpURL)
                defer { try? FileManager.default.removeItem(at: tmpURL) }
                record["photoAsset"] = CKAsset(fileURL: tmpURL)
            }

            _ = try await db.save(record)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // One retry: fetch fresh record and re-apply (mirror toggleReaction pattern).
            do {
                let predicate = NSPredicate(format: "username == %@ AND dayKey == %@",
                                            sanitizedUsername, todayKey)
                let query = CKQuery(recordType: glimpseRecordType, predicate: predicate)
                let (results, _) = try await db.records(matching: query, resultsLimit: 1)
                guard let freshRecord = results.first.flatMap({ try? $0.1.get() }) else { return }
                freshRecord["username"] = sanitizedUsername as CKRecordValue
                freshRecord["goalTitle"] = sanitizedTitle as CKRecordValue
                freshRecord["progressPercent"] = Int64(progressPercent) as CKRecordValue
                freshRecord["authorColorHex"] = sanitizedColorHex as CKRecordValue
                freshRecord["dayKey"] = todayKey as CKRecordValue
                _ = try await db.save(freshRecord)
            } catch {
                // Silently discard — fire-and-forget
            }
        } catch {
            // Silently discard — fire-and-forget
        }
    }

    /// Fetches all GoalGlimpse records for a given dayKey (YYYY-MM-DD).
    /// CKAsset photoFileURL is copied to Application Support before return.
    static func fetchGlimpses(dayKey: String) async throws -> [GoalGlimpseItem] {
        let db = CKContainer.default().publicCloudDatabase
        let predicate = NSPredicate(format: "dayKey == %@", dayKey)
        let query = CKQuery(recordType: glimpseRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let (results, _) = try await db.records(matching: query, resultsLimit: 50)
        let records = results.compactMap { try? $0.1.get() }
        return records.map { record in
            mapRecordToGlimpseItem(record)
        }
    }

    // MARK: - UserPresence

    /// Upserts a UserPresence record for username (one record per user, lastActiveDate updated).
    /// Fire-and-forget — all errors caught silently.
    static func writeUserPresence(username: String, authorColorHex: String) async {
        let db = CKContainer.default().publicCloudDatabase
        let sanitizedUsername = InputSanitizer.sanitizeForPublic(username)
        let sanitizedColorHex = InputSanitizer.sanitizeForPublic(authorColorHex)

        do {
            let predicate = NSPredicate(format: "username == %@", sanitizedUsername)
            let query = CKQuery(recordType: presenceRecordType, predicate: predicate)
            let (results, _) = try await db.records(matching: query, resultsLimit: 1)
            let existing = results.first.flatMap { try? $0.1.get() }

            let record: CKRecord
            if let existingRecord = existing {
                record = existingRecord
            } else {
                record = CKRecord(recordType: presenceRecordType)
            }

            record["username"] = sanitizedUsername as CKRecordValue
            record["authorColorHex"] = sanitizedColorHex as CKRecordValue
            record["lastActiveDate"] = Date() as CKRecordValue

            _ = try await db.save(record)
        } catch {
            // Silently discard — fire-and-forget
        }
    }

    /// Fetches users active within the last 2 hours (lastActiveDate > now - 7200s).
    static func fetchActiveUsers() async throws -> [UserPresenceItem] {
        let db = CKContainer.default().publicCloudDatabase
        let twoHoursAgo = Date().addingTimeInterval(-7200)
        let predicate = NSPredicate(format: "lastActiveDate > %@", twoHoursAgo as CVarArg)
        let query = CKQuery(recordType: presenceRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastActiveDate", ascending: false)]
        let (results, _) = try await db.records(matching: query, resultsLimit: 20)
        let records = results.compactMap { try? $0.1.get() }
        return records.map { record in
            UserPresenceItem(
                id: record.recordID.recordName,
                username: (record["username"] as? String) ?? "",
                authorColorHex: (record["authorColorHex"] as? String) ?? "",
                lastActiveDate: (record["lastActiveDate"] as? Date) ?? Date()
            )
        }
    }

    // MARK: - Applause

    /// Creates an Applause record from giverUsername to recipientUsername.
    static func writeApplause(giverUsername: String, recipientUsername: String) async throws {
        let db = CKContainer.default().publicCloudDatabase
        let record = CKRecord(recordType: applauseRecordType)
        record["giverUsername"] = InputSanitizer.sanitizeForPublic(giverUsername) as CKRecordValue
        record["recipientUsername"] = InputSanitizer.sanitizeForPublic(recipientUsername) as CKRecordValue

        do {
            _ = try await db.save(record)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // One retry with fresh record
            let freshRecord = CKRecord(recordType: applauseRecordType)
            freshRecord["giverUsername"] = InputSanitizer.sanitizeForPublic(giverUsername) as CKRecordValue
            freshRecord["recipientUsername"] = InputSanitizer.sanitizeForPublic(recipientUsername) as CKRecordValue
            _ = try await db.save(freshRecord)
        }
    }

    /// Fetches Applause records received by recipientUsername (most recent first).
    static func fetchReceivedApplause(recipientUsername: String) async throws -> [ApplauseItem] {
        let db = CKContainer.default().publicCloudDatabase
        let sanitized = InputSanitizer.sanitizeForPublic(recipientUsername)
        let predicate = NSPredicate(format: "recipientUsername == %@", sanitized)
        let query = CKQuery(recordType: applauseRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let (results, _) = try await db.records(matching: query, resultsLimit: 20)
        let records = results.compactMap { try? $0.1.get() }
        return records.map { record in
            ApplauseItem(
                id: record.recordID.recordName,
                giverUsername: (record["giverUsername"] as? String) ?? "",
                recipientUsername: (record["recipientUsername"] as? String) ?? "",
                creationDate: record.creationDate ?? Date()
            )
        }
    }

    // MARK: - Glowing This Week

    /// Fetches GoalGlimpse records from the past 7 days — used for Glowing This Week eligibility pool.
    static func fetchGlowingUser(dayKey: String) async throws -> [GoalGlimpseItem] {
        let db = CKContainer.default().publicCloudDatabase
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let sevenDaysAgoKey = formatter.string(from: sevenDaysAgo)
        let predicate = NSPredicate(format: "dayKey >= %@", sevenDaysAgoKey)
        let query = CKQuery(recordType: glimpseRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let (results, _) = try await db.records(matching: query, resultsLimit: 50)
        let records = results.compactMap { try? $0.1.get() }
        return records.map { record in mapRecordToGlimpseItem(record) }
    }

    // MARK: - Global Feed

    /// Fetches all non-reported community posts (global feed — no category filter).
    static func fetchGlobalPosts(limit: Int = 50) async throws -> [CKRecord] {
        let db = CKContainer.default().publicCloudDatabase
        let predicate = NSPredicate(format: "reportCount < 3")
        let query = CKQuery(recordType: postRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let (results, _) = try await db.records(matching: query, resultsLimit: limit)
        return results.compactMap { try? $0.1.get() }
    }

    // MARK: - Replies

    /// Writes a flat reply to a community post.
    /// Returns false if the text contains profanity or if the CloudKit save ultimately fails.
    /// Returns true on successful save.
    ///
    /// `saveOverride` — test-only closure; pass nil in production. When non-nil, replaces the
    /// real `db.save(record)` call so tests never hit CloudKit. Pattern mirrors
    /// CommunityFeedViewModel.createOverride.
    @discardableResult
    static func writeReply(
        parentPostID: String,
        text: String,
        authorDisplayName: String?,
        authorColorHex: String?,
        saveOverride: ((CKRecord) async throws -> CKRecord)? = nil
    ) async throws -> Bool {
        // Profanity gate — T-21-04-01 mitigation
        guard !ProfanityFilter.containsProfanity(text) else { return false }

        let record = CKRecord(recordType: replyRecordType)
        record["parentPostID"] = InputSanitizer.sanitizeForPublic(parentPostID) as CKRecordValue
        record["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
        record["authorDisplayName"] = InputSanitizer.sanitizeForPublic(authorDisplayName ?? "Anonymous") as CKRecordValue
        record["authorColorHex"] = InputSanitizer.sanitizeForPublic(authorColorHex ?? "") as CKRecordValue

        if let override = saveOverride {
            // Test path: call override directly, never touch CloudKit
            _ = try await override(record)
            return true
        }

        let db = CKContainer.default().publicCloudDatabase
        do {
            _ = try await db.save(record)
            return true
        } catch let error as CKError where error.code == .serverRecordChanged {
            // One retry with fresh record
            let freshRecord = CKRecord(recordType: replyRecordType)
            freshRecord["parentPostID"] = InputSanitizer.sanitizeForPublic(parentPostID) as CKRecordValue
            freshRecord["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
            freshRecord["authorDisplayName"] = InputSanitizer.sanitizeForPublic(authorDisplayName ?? "Anonymous") as CKRecordValue
            freshRecord["authorColorHex"] = InputSanitizer.sanitizeForPublic(authorColorHex ?? "") as CKRecordValue
            do {
                _ = try await db.save(freshRecord)
                return true
            } catch {
                return false
            }
        }
    }

    /// Fetches flat replies for a community post, sorted ascending by creationDate.
    static func fetchReplies(parentPostID: String) async throws -> [CommunityReplyItem] {
        let db = CKContainer.default().publicCloudDatabase
        let sanitized = InputSanitizer.sanitizeForPublic(parentPostID)
        let predicate = NSPredicate(format: "parentPostID == %@", sanitized)
        let query = CKQuery(recordType: replyRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let (results, _) = try await db.records(matching: query, resultsLimit: 50)
        let records = results.compactMap { try? $0.1.get() }
        return records.map { record in
            CommunityReplyItem(
                id: record.recordID.recordName,
                parentPostID: (record["parentPostID"] as? String) ?? "",
                text: (record["text"] as? String) ?? "",
                authorDisplayName: (record["authorDisplayName"] as? String) ?? "Anonymous",
                authorColorHex: (record["authorColorHex"] as? String) ?? "",
                creationDate: record.creationDate ?? Date()
            )
        }
    }

    // MARK: - Private helpers

    /// Maps a GoalGlimpse CKRecord to a GoalGlimpseItem.
    /// Copies CKAsset fileURL to Application Support before returning (T-21-02-04).
    private static func mapRecordToGlimpseItem(_ record: CKRecord) -> GoalGlimpseItem {
        var photoFileURL: URL? = nil
        if let asset = record["photoAsset"] as? CKAsset,
           let srcURL = asset.fileURL {
            let supportDir = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let destURL = supportDir.appendingPathComponent(UUID().uuidString + ".jpg")
            try? FileManager.default.createDirectory(
                at: supportDir, withIntermediateDirectories: true)
            try? FileManager.default.copyItem(at: srcURL, to: destURL)
            photoFileURL = destURL
        }
        return GoalGlimpseItem(
            id: record.recordID.recordName,
            username: (record["username"] as? String) ?? "",
            goalTitle: (record["goalTitle"] as? String) ?? "",
            progressPercent: Int((record["progressPercent"] as? Int64) ?? 0),
            authorColorHex: (record["authorColorHex"] as? String) ?? "",
            photoFileURL: photoFileURL,
            dayKey: (record["dayKey"] as? String) ?? ""
        )
    }
}

// MARK: - Reaction received subscription (CHAL-24) — best-effort

extension CommunityService {

    /// Registers a CKQuerySubscription that fires when someone creates a CommunityReaction
    /// targeting the current user's posts. Non-fatal — any failure is silently logged in DEBUG.
    ///
    /// Reliability caveat (RESEARCH.md Pitfall 3): iOS 26.4 has a regression that prevents
    /// public-database CKQuerySubscription pushes from delivering. Fixed in 26.4.1+. The app
    /// must function fully without this subscription succeeding.
    ///
    /// Capability requirement (RESEARCH.md Pitfall 4): the app target must have the Push
    /// Notifications capability enabled (`aps-environment` entitlement). If missing,
    /// subscription save succeeds but no push is ever delivered — this is a configuration
    /// concern, not a code defect.
    static func registerReactionSubscription(userRecordName: String) async {
        let container = CKContainer.default()
        let db = container.publicCloudDatabase
        let subscriptionID = "reaction-received-\(userRecordName)"

        // Idempotency: skip if already registered
        do {
            _ = try await db.subscription(for: subscriptionID)
            return  // already registered
        } catch {
            // unknownItem or other fetch error — proceed with creation below
        }

        let predicate = NSPredicate(format: "targetAuthorID == %@", userRecordName)
        let subscription = CKQuerySubscription(
            recordType: reactionRecordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation]
        )
        let info = CKSubscription.NotificationInfo()
        info.alertLocalizationKey = "Someone reacted to your post"
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        do {
            _ = try await db.save(subscription)
        } catch {
            #if DEBUG
            print("[CommunityService] Subscription registration failed (non-fatal): \(error)")
            #endif
        }
    }
}
