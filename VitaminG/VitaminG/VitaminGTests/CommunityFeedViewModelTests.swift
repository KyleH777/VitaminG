import XCTest
import CloudKit
@testable import VitaminG

@MainActor
final class CommunityFeedViewModelTests: XCTestCase {
    // CHAL-13 — implemented in Plan 02
    func test_loadPosts_success_populatesPostsArray() async throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }
    // CHAL-16 — implemented in Plan 02
    func test_submitPost_profanity_setsErrorAndDoesNotCallService() async throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }
    // CHAL-13, CHAL-17 — implemented in Plan 02
    func test_submitPost_cleanText_callsCommunityServiceCreatePost() async throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }
    // CHAL-14 — implemented in Plan 02
    func test_toggleReaction_optimisticUpdate_thenServiceCall() async throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }
    // CHAL-15 — implemented in Plan 02
    func test_reportPost_deduplicatesReporters() async throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }
}
