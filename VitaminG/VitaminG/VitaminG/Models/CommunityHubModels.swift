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

// MARK: - Phase 22 Discover & Profile Models

// MARK: - PublicProfileData
// Returned by ProfileSharingService.fetchProfile() in Phase 22.
// Carries all PROF-01 fields needed for the redesigned PublicProfileView.
// Not Identifiable — the caller keys it by the recordID (appleUserID) from the enclosing context.

struct PublicProfileData: Equatable, Sendable {
    let displayName: String?        // CKRecord field: "displayName"
    let avatarColorHex: String?     // CKRecord field: "avatarColorHex"
    let username: String?           // CKRecord field: "username"
    let motto: String?              // CKRecord field: "motto" (D-07)
    let streakLength: Int           // CKRecord field: "streakLength" (Int64 in CK, Int locally) (D-05)
    let goalCount: Int              // CKRecord field: "goalCount" (Int64 in CK, Int locally) (D-05)
    let cheersGivenCount: Int       // Fetched separately via CommunityService.fetchApplauseGivenCount
}

// MARK: - PublicGoalItem
// Mirrors PublicGoal CKRecord fields (D-09). Used on PublicProfileView goal list and as the
// backing data for PublicGoalCard. Record name = goal.id.uuidString for stable identity (D-09).

struct PublicGoalItem: Identifiable, Sendable {
    let id: String              // CKRecord.recordID.recordName (goal.id.uuidString)
    let title: String           // CKRecord field: "title"
    let category: String        // CKRecord field: "category"
    let creatorUsername: String // CKRecord field: "creatorUsername"
    let participantCount: Int   // CKRecord field: "participantCount" (Int64 in CK, Int locally)
    let progressPercent: Int    // CKRecord field: "progressPercent" (Int64 in CK, Int locally)
    let durationDays: Int       // CKRecord field: "durationDays" (Int64 in CK, Int locally)
    let creationEpoch: Int      // CKRecord field: "creationEpoch" (Int64 in CK, Int locally)
}

// MARK: - DiscoverGoalResult
// Subset of PublicGoal fields returned by PublicGoalService.searchGoals(keyword:) for Discover search (DISC-01).
// Identifiable by CKRecord.recordID.recordName.

struct DiscoverGoalResult: Identifiable, Sendable {
    let id: String              // CKRecord.recordID.recordName
    let title: String           // CKRecord field: "title"
    let category: String        // CKRecord field: "category"
    let creatorUsername: String // CKRecord field: "creatorUsername"
    let participantCount: Int   // CKRecord field: "participantCount" (Int64 in CK, Int locally)
    let progressPercent: Int    // CKRecord field: "progressPercent" (Int64 in CK, Int locally)
}

// MARK: - DiscoverPersonResult
// Subset of PublicProfile fields returned by PublicGoalService.searchPeople(usernamePrefix:) for Discover people search (DISC-02).
// Identifiable by CKRecord.recordID.recordName (== appleUserID keying strategy from Phase 17).

struct DiscoverPersonResult: Identifiable, Sendable {
    let id: String              // CKRecord.recordID.recordName (appleUserID)
    let username: String        // CKRecord field: "username"
    let avatarColorHex: String  // CKRecord field: "avatarColorHex"
    let goalCount: Int          // CKRecord field: "goalCount" (Int64 in CK, Int locally)
    let cheersGivenCount: Int   // CKRecord field: "cheersGivenCount" (Int64 in CK, Int locally; absent in current schema — default 0)
}
