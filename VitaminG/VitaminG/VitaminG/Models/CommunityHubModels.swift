import Foundation

// MARK: - GoalGlimpseItem
// Mirrors GoalGlimpse CKRecord fields from RESEARCH.md:
// "username" String, "goalTitle" String, "progressPercent" Int64,
// "authorColorHex" String, "photoAsset" CKAsset?, "dayKey" String

struct GoalGlimpseItem: Identifiable, Sendable {
    let id: String                // CKRecord.recordID.recordName
    let username: String          // CKRecord field: "username"
    let goalTitle: String         // CKRecord field: "goalTitle"
    let progressPercent: Int      // CKRecord field: "progressPercent" (Int64 in CK, Int locally)
    let authorColorHex: String    // CKRecord field: "authorColorHex"
    let photoFileURL: URL?        // Copied from CKAsset.fileURL (nil if no photo)
    let dayKey: String            // CKRecord field: "dayKey" (e.g. "2026-05-23")
}

// MARK: - UserPresenceItem
// Mirrors UserPresence CKRecord fields from RESEARCH.md:
// "username" String, "authorColorHex" String, "lastActiveDate" DateTime

struct UserPresenceItem: Identifiable, Sendable {
    let id: String                // CKRecord.recordID.recordName
    let username: String          // CKRecord field: "username"
    let authorColorHex: String    // CKRecord field: "authorColorHex"
    let lastActiveDate: Date      // CKRecord field: "lastActiveDate"
}

// MARK: - ApplauseItem
// Mirrors Applause CKRecord fields from RESEARCH.md:
// "giverUsername" String, "recipientUsername" String

struct ApplauseItem: Identifiable, Sendable {
    let id: String                 // CKRecord.recordID.recordName
    let giverUsername: String      // CKRecord field: "giverUsername"
    let recipientUsername: String  // CKRecord field: "recipientUsername"
    let creationDate: Date         // CKRecord system field: creationDate
}

// MARK: - CommunityReplyItem
// Mirrors CommunityReply CKRecord fields (flat replies per D-08):
// "parentPostID" String, "text" String, "authorDisplayName" String,
// "authorColorHex" String, "creationDate" DateTime

struct CommunityReplyItem: Identifiable, Sendable {
    let id: String                 // CKRecord.recordID.recordName
    let parentPostID: String       // CKRecord field: "parentPostID"
    let text: String               // CKRecord field: "text"
    let authorDisplayName: String  // CKRecord field: "authorDisplayName"
    let authorColorHex: String     // CKRecord field: "authorColorHex"
    let creationDate: Date         // CKRecord field: "creationDate"
}
