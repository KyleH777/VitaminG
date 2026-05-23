import XCTest
@testable import VitaminG

// RED stubs — these tests are intentionally failing until Plan 03 implements
// CommunityService.writeReply (COMM-06 reply write + profanity gate).

final class Phase21ReplyTests: XCTestCase {

    // COMM-06 / 21-xx-06 — profane reply text must be rejected (returns false)
    // Expected assertion: writeReply with text containing profanity returns false
    // and does not call CloudKit.
    func test_writeReply_rejectsProfaneText() async throws {
        // CommunityService.writeReply does not exist yet (RED).
        //
        // var cloudKitCalled = false
        // let result = await CommunityService.writeReply(
        //     parentPostID: "post-1",
        //     text: "this is damn bad",
        //     authorDisplayName: "Tester",
        //     authorColorHex: "#FF0000",
        //     saveOverride: { _ in
        //         cloudKitCalled = true
        //         return CKRecord(recordType: "CommunityReply")
        //     }
        // )
        // XCTAssertFalse(result, "writeReply must return false when profanity detected")
        // XCTAssertFalse(cloudKitCalled,
        //     "CloudKit must not be called when profanity gate triggers")

        XCTFail("Not yet implemented — CommunityService.writeReply does not exist (Plan 03)")
    }

    // COMM-06 / 21-xx-06 — accepted text is sanitized before CloudKit write
    // Expected assertion: the text passed to the CloudKit save override equals
    // InputSanitizer.sanitizeForPublic(original), not the raw original text.
    func test_writeReply_sanitizesTextBeforeWrite() async throws {
        // CommunityService.writeReply does not exist yet (RED).
        //
        // let original = "Hello <world>  extra  spaces"
        // var capturedText: String?
        // _ = await CommunityService.writeReply(
        //     parentPostID: "post-2",
        //     text: original,
        //     authorDisplayName: "Tester",
        //     authorColorHex: "#FF0000",
        //     saveOverride: { record in
        //         capturedText = record["text"] as? String
        //         return record
        //     }
        // )
        // let expected = InputSanitizer.sanitizeForPublic(original)
        // XCTAssertEqual(capturedText, expected,
        //     "writeReply must sanitize text via InputSanitizer.sanitizeForPublic before writing")

        XCTFail("Not yet implemented — CommunityService.writeReply does not exist (Plan 03)")
    }
}
