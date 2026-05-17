import CloudKit
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum ReactionType: String {
    case thumbsUp
    case heart
    var fieldKey: String {
        switch self {
        case .thumbsUp: return "thumbsUpCount"
        case .heart:    return "heartCount"
        }
    }
}

enum CommunityService {
    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    static let postRecordType = "CommunityPost"
    static let reactionRecordType = "CommunityReaction"

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
