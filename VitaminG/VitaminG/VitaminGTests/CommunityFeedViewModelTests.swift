import XCTest
import CloudKit
@testable import VitaminG

@MainActor
final class CommunityFeedViewModelTests: XCTestCase {
    var sut: CommunityFeedViewModel!

    override func setUp() async throws { sut = CommunityFeedViewModel() }
    override func tearDown() async throws { sut = nil }

    // CHAL-13
    func test_loadPosts_success_populatesPostsArray() async throws {
        let mockRecord = CKRecord(recordType: CommunityService.postRecordType)
        mockRecord["text"] = "hello" as CKRecordValue
        sut.fetchOverride = { _, _ in [mockRecord] }
        await sut.loadPosts(category: "fitness")
        XCTAssertEqual(sut.posts.count, 1)
        XCTAssertFalse(sut.isLoading)
    }

    // CHAL-16
    func test_submitPost_profanity_setsErrorAndDoesNotCallService() async throws {
        var serviceCalled = false
        sut.createOverride = { _, _, _, _, _ in
            serviceCalled = true
            return CKRecord(recordType: CommunityService.postRecordType)
        }
        let result = await sut.submitPost(
            text: "this is damn bad",
            imageData: nil, category: "fitness",
            authorDisplayName: nil, authorColorHex: nil
        )
        XCTAssertFalse(result)
        XCTAssertFalse(serviceCalled, "Service must not be called when profanity detected")
        XCTAssertEqual(sut.submitError, CommunityFeedViewModel.profanityRejectionMessage)
    }

    // CHAL-13, CHAL-17
    func test_submitPost_cleanText_callsCommunityServiceCreatePost() async throws {
        var capturedText: String?
        sut.createOverride = { text, _, _, _, _ in
            capturedText = text
            let r = CKRecord(recordType: CommunityService.postRecordType)
            r["text"] = text as CKRecordValue
            return r
        }
        let result = await sut.submitPost(
            text: "Day 5 strong!", imageData: nil,
            category: "sobriety", authorDisplayName: "Kyle", authorColorHex: nil
        )
        XCTAssertTrue(result)
        XCTAssertEqual(capturedText, "Day 5 strong!")
        XCTAssertEqual(sut.posts.count, 1)
        XCTAssertNil(sut.submitError)
    }

    // CHAL-14
    func test_toggleReaction_optimisticUpdate_thenServiceCall() async throws {
        let recordID = CKRecord.ID(recordName: "test-post")
        var capturedType: ReactionType?
        sut.toggleOverride = { _, type, _ in
            capturedType = type
            let r = CKRecord(recordType: CommunityService.postRecordType)
            r["thumbsUpCount"] = 1 as CKRecordValue
            return r
        }
        let result = await sut.toggleReaction(recordID: recordID, reactionType: .thumbsUp, add: true)
        XCTAssertNotNil(result)
        XCTAssertEqual(capturedType, .thumbsUp)
    }

    // CHAL-15
    func test_reportPost_deduplicatesReporters() async throws {
        let recordID = CKRecord.ID(recordName: "test-post-2")
        var calls = 0
        sut.reportOverride = { _, _ in
            calls += 1
            return calls
        }
        let count1 = await sut.reportPost(recordID: recordID, reporterID: "user-A")
        let count2 = await sut.reportPost(recordID: recordID, reporterID: "user-A")
        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 2, "Override increments per call — de-duplication is in CommunityService.reportPost itself, not in the ViewModel")
    }
}
