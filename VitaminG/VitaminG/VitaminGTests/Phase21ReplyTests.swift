import XCTest
import CloudKit
@testable import VitaminG

// GREEN — Phase 21 Plan 04 implements CommunityService.writeReply with saveOverride
// and CommunityReplySheetView with onWriteReply closure injection.

final class Phase21ReplyTests: XCTestCase {

    // COMM-06 / 21-04-01 — profane reply text must be rejected by CommunityService.writeReply.
    // Verifies: profanity gate fires before CloudKit save; CloudKit is never called.
    func test_writeReply_rejectsProfaneText() async throws {
        var cloudKitCalled = false
        let result = try await CommunityService.writeReply(
            parentPostID: "post-1",
            text: "this is damn bad",
            authorDisplayName: "Tester",
            authorColorHex: "#FF0000",
            saveOverride: { _ in
                cloudKitCalled = true
                return CKRecord(recordType: "CommunityReply")
            }
        )
        XCTAssertFalse(result, "writeReply must return false when profanity detected")
        XCTAssertFalse(cloudKitCalled,
            "CloudKit must not be called when profanity gate triggers")
    }

    // COMM-06 / 21-04-02 — accepted text is sanitized before CloudKit write.
    // Verifies: the text stored in the CKRecord equals InputSanitizer.sanitizeForPublic(original).
    func test_writeReply_sanitizesTextBeforeWrite() async throws {
        let original = "Hello <world>  extra  spaces"
        var capturedText: String?
        _ = try await CommunityService.writeReply(
            parentPostID: "post-2",
            text: original,
            authorDisplayName: "Tester",
            authorColorHex: "#FF0000",
            saveOverride: { record in
                capturedText = record["text"] as? String
                return record
            }
        )
        let expected = InputSanitizer.sanitizeForPublic(original)
        XCTAssertEqual(capturedText, expected,
            "writeReply must sanitize text via InputSanitizer.sanitizeForPublic before writing")
    }

    // COMM-06 / 21-04-03 — clean text succeeds (returns true) via closure injection.
    // Verifies: the view's onWriteReply closure path works for clean text.
    func test_writeReply_cleanText_returnsTrue() async throws {
        var capturedText: String?
        let result = try await CommunityService.writeReply(
            parentPostID: "post-3",
            text: "This is a great community post!",
            authorDisplayName: "Kyle",
            authorColorHex: "#4A7C59",
            saveOverride: { record in
                capturedText = record["text"] as? String
                return record
            }
        )
        XCTAssertTrue(result, "writeReply must return true for clean text")
        XCTAssertNotNil(capturedText, "CloudKit save override must have been called for clean text")
    }
}
