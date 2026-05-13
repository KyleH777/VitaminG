import XCTest
@testable import VitaminG

final class ProfanityFilterTests: XCTestCase {
    // CHAL-16 — implemented in Plan 02
    func test_containsProfanity_blockedWord_returnsTrue() throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }
    func test_containsProfanity_cleanText_returnsFalse() throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }
    func test_containsProfanity_partialWordEmbedded_returnsFalse() throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }
}
