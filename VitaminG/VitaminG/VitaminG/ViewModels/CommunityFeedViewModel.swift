import Foundation
import Observation
import CloudKit

@MainActor
@Observable
final class CommunityFeedViewModel {
    // MARK: - Public state
    var posts: [CKRecord] = []
    var isLoading: Bool = false
    var submitError: String? = nil
    var reactionError: String? = nil

    // MARK: - Test overrides (nil in production)
    var fetchOverride: ((String, Int) async throws -> [CKRecord])? = nil
    var createOverride: ((String, Data?, String, String?, String?) async throws -> CKRecord)? = nil
    var toggleOverride: ((CKRecord.ID, ReactionType, Bool) async throws -> CKRecord)? = nil
    var reportOverride: ((CKRecord.ID, String) async throws -> Int)? = nil

    // MARK: - Constants
    static let profanityRejectionMessage =
        "Your post contains content that isn't allowed. Please edit and try again."
    static let postSaveFailureMessage = "Couldn't post. Please try again."
    static let reactionSaveFailureMessage = "Couldn't save your reaction. Please try again."

    // MARK: - Load (CHAL-13)
    func loadPosts(category: String, limit: Int = 50) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let override = fetchOverride {
                posts = try await override(category, limit)
            } else {
                posts = try await CommunityService.fetchPosts(category: category, limit: limit)
            }
        } catch {
            posts = []
        }
    }

    // MARK: - Submit post (CHAL-16, CHAL-17)
    /// Returns true if the post was submitted; false if it was rejected (profanity or service error).
    @discardableResult
    func submitPost(
        text: String,
        imageData: Data?,
        category: String,
        authorDisplayName: String?,
        authorColorHex: String?
    ) async -> Bool {
        submitError = nil
        // Profanity gate FIRST — never silently drop
        if ProfanityFilter.containsProfanity(text) {
            submitError = Self.profanityRejectionMessage
            return false
        }
        do {
            let saved: CKRecord
            if let override = createOverride {
                saved = try await override(text, imageData, category, authorDisplayName, authorColorHex)
            } else {
                saved = try await CommunityService.createPost(
                    text: text,
                    imageData: imageData,
                    category: category,
                    authorDisplayName: authorDisplayName,
                    authorColorHex: authorColorHex
                )
            }
            posts.insert(saved, at: 0)
            return true
        } catch {
            submitError = Self.postSaveFailureMessage
            return false
        }
    }

    // MARK: - Toggle reaction (CHAL-14)
    @discardableResult
    func toggleReaction(
        recordID: CKRecord.ID,
        reactionType: ReactionType,
        add: Bool
    ) async -> CKRecord? {
        reactionError = nil
        do {
            if let override = toggleOverride {
                return try await override(recordID, reactionType, add)
            }
            return try await CommunityService.toggleReaction(
                recordID: recordID, reactionType: reactionType, add: add
            )
        } catch {
            reactionError = Self.reactionSaveFailureMessage
            return nil
        }
    }

    // MARK: - Report post (CHAL-15)
    /// Returns the new report count, or -1 on failure.
    func reportPost(recordID: CKRecord.ID, reporterID: String) async -> Int {
        do {
            if let override = reportOverride {
                return try await override(recordID, reporterID)
            }
            return try await CommunityService.reportPost(recordID: recordID, reporterID: reporterID)
        } catch {
            return -1
        }
    }
}
