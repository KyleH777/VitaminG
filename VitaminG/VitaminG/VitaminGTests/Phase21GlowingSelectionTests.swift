import XCTest
@testable import VitaminG

// RED stubs — these tests are intentionally failing until Plan 03 implements
// selectGlowingUser (COMM-05 deterministic weekOfYear % eligibleCount selection).

final class Phase21GlowingSelectionTests: XCTestCase {

    // COMM-05 / 21-xx-03 — same eligible array yields the same result on consecutive calls
    // Expected assertion: two calls to selectGlowingUser with the same array return
    // identical UserPresenceItems (same id).
    func test_selectGlowingUser_deterministic_sameWeekSameResult() throws {
        // selectGlowingUser does not exist yet (RED).
        //
        // let eligible = [
        //     UserPresenceItem(id: "a", username: "alice", authorColorHex: "#AAA",
        //                      lastActiveDate: Date()),
        //     UserPresenceItem(id: "b", username: "bob", authorColorHex: "#BBB",
        //                      lastActiveDate: Date()),
        //     UserPresenceItem(id: "c", username: "carol", authorColorHex: "#CCC",
        //                      lastActiveDate: Date()),
        // ]
        // let result1 = GlowingSelector.selectGlowingUser(from: eligible)
        // let result2 = GlowingSelector.selectGlowingUser(from: eligible)
        // XCTAssertEqual(result1?.id, result2?.id,
        //     "selectGlowingUser must be deterministic — same week, same result")

        XCTFail("Not yet implemented — GlowingSelector.selectGlowingUser does not exist (Plan 03)")
    }

    // COMM-05 — empty eligible array returns nil (no crash, no index out-of-bounds)
    // Expected assertion: selectGlowingUser([]) == nil
    func test_selectGlowingUser_returnsNilForEmptyArray() throws {
        // selectGlowingUser does not exist yet (RED).
        //
        // let result = GlowingSelector.selectGlowingUser(from: [])
        // XCTAssertNil(result, "selectGlowingUser with empty array must return nil")

        XCTFail("Not yet implemented — GlowingSelector.selectGlowingUser does not exist (Plan 03)")
    }

    // COMM-05 — selection index matches ISO 8601 weekOfYear % eligible.count
    // Expected assertion:
    //   let weekOfYear = Calendar(identifier: .iso8601)
    //       .component(.weekOfYear, from: Date())
    //   let expectedIndex = weekOfYear % eligible.count
    //   result == eligible[expectedIndex]
    func test_selectGlowingUser_usesISO8601Calendar() throws {
        // selectGlowingUser does not exist yet (RED).
        //
        // let eligible = [
        //     UserPresenceItem(id: "a", username: "alice", authorColorHex: "#AAA",
        //                      lastActiveDate: Date()),
        //     UserPresenceItem(id: "b", username: "bob", authorColorHex: "#BBB",
        //                      lastActiveDate: Date()),
        //     UserPresenceItem(id: "c", username: "carol", authorColorHex: "#CCC",
        //                      lastActiveDate: Date()),
        // ]
        // let result = GlowingSelector.selectGlowingUser(from: eligible)
        // let weekOfYear = Calendar(identifier: .iso8601)
        //     .component(.weekOfYear, from: Date())
        // let expectedIndex = weekOfYear % eligible.count
        // XCTAssertEqual(result?.id, eligible[expectedIndex].id,
        //     "selectGlowingUser index must use ISO8601 weekOfYear % count")

        XCTFail("Not yet implemented — GlowingSelector.selectGlowingUser does not exist (Plan 03)")
    }
}
