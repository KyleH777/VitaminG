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
        let container = CKContainer(identifier: containerID)
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
        let container = CKContainer(identifier: containerID)
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
            record["photoAsset"] = CKAsset(fileURL: tmpURL)
        }

        return try await container.publicCloudDatabase.save(record)
    }

    // MARK: - Toggle reaction (CHAL-14)
    static func toggleReaction(
        recordID: CKRecord.ID,
        reactionType: ReactionType,
        add: Bool
    ) async throws -> CKRecord {
        let container = CKContainer(identifier: containerID)
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
        let container = CKContainer(identifier: containerID)
        let db = container.publicCloudDatabase
        let record = try await db.record(for: recordID)

        let existingJSON = (record["reporterIDsJSON"] as? String) ?? "[]"
        var reporters = (try? JSONDecoder().decode([String].self, from: Data(existingJSON.utf8))) ?? []

        guard !reporters.contains(reporterID) else {
            return (record["reportCount"] as? Int) ?? reporters.count
        }
        reporters.append(reporterID)

        if let data = try? JSONEncoder().encode(reporters),
           let json = String(data: data, encoding: .utf8) {
            record["reporterIDsJSON"] = json as CKRecordValue
        }
        let newCount = reporters.count
        record["reportCount"] = newCount as CKRecordValue
        _ = try await db.save(record)
        return newCount
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
}
