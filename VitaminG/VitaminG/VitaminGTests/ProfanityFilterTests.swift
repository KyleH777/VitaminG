import XCTest
@testable import VitaminG

final class ProfanityFilterTests: XCTestCase {
    // CHAL-16
    func test_containsProfanity_blockedWord_returnsTrue() {
        XCTAssertTrue(ProfanityFilter.containsProfanity("oh damn that hurts"))
    }

    // CHAL-16
    func test_containsProfanity_cleanText_returnsFalse() {
        XCTAssertFalse(ProfanityFilter.containsProfanity("This is a great challenge!"))
    }

    // CHAL-16 — whole-word boundary check (RESEARCH.md anti-pattern)
    func test_containsProfanity_partialWordEmbedded_returnsFalse() {
        XCTAssertFalse(ProfanityFilter.containsProfanity("that was a classy performance"))
    }

    // Boundary
    func test_containsProfanity_emptyString_returnsFalse() {
        XCTAssertFalse(ProfanityFilter.containsProfanity(""))
    }

    // Punctuation boundary
    func test_containsProfanity_blockedWordWithPunctuation_returnsTrue() {
        XCTAssertTrue(ProfanityFilter.containsProfanity("damn!"))
    }
}
