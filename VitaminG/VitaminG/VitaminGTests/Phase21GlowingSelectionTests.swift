import XCTest
@testable import VitaminG

// GREEN — Plan 03 implemented GlowingSelector.
// Tests verify deterministic weekOfYear % eligibleCount selection (COMM-05).

final class Phase21GlowingSelectionTests: XCTestCase {

    // COMM-05 / 21-xx-03 — same eligible array yields the same result on consecutive calls
    // Expected assertion: two calls to selectGlowingUser with the same array return
    // identical GoalGlimpseItems (same id).
    func test_selectGlowingUser_deterministic_sameWeekSameResult() throws {
        let eligible = [
            GoalGlimpseItem(id: "a", username: "alice", goalTitle: "Run 5K",
                            progressPercent: 80, authorColorHex: "#AAA",
                            photoFileURL: nil, dayKey: "2026-05-23"),
            GoalGlimpseItem(id: "b", username: "bob", goalTitle: "Learn Swift",
                            progressPercent: 50, authorColorHex: "#BBB",
                            photoFileURL: nil, dayKey: "2026-05-23"),
            GoalGlimpseItem(id: "c", username: "carol", goalTitle: "Read 12 books",
                            progressPercent: 60, authorColorHex: "#CCC",
                            photoFileURL: nil, dayKey: "2026-05-23"),
        ]
        let result1 = GlowingSelector.selectGlowingUser(from: eligible)
        let result2 = GlowingSelector.selectGlowingUser(from: eligible)
        XCTAssertEqual(result1?.id, result2?.id,
            "selectGlowingUser must be deterministic — same week, same result")
    }

    // COMM-05 — empty eligible array returns nil (no crash, no index out-of-bounds)
    // Expected assertion: selectGlowingUser([]) == nil
    func test_selectGlowingUser_returnsNilForEmptyArray() throws {
        let result = GlowingSelector.selectGlowingUser(from: [])
        XCTAssertNil(result, "selectGlowingUser with empty array must return nil")
    }

    // COMM-05 — selection index matches ISO 8601 weekOfYear % eligible.count
    // Expected assertion:
    //   let weekOfYear = Calendar(identifier: .iso8601)
    //       .component(.weekOfYear, from: Date())
    //   let expectedIndex = weekOfYear % eligible.count
    //   result == eligible[expectedIndex]
    func test_selectGlowingUser_usesISO8601Calendar() throws {
        let eligible = [
            GoalGlimpseItem(id: "a", username: "alice", goalTitle: "Run 5K",
                            progressPercent: 80, authorColorHex: "#AAA",
                            photoFileURL: nil, dayKey: "2026-05-23"),
            GoalGlimpseItem(id: "b", username: "bob", goalTitle: "Learn Swift",
                            progressPercent: 50, authorColorHex: "#BBB",
                            photoFileURL: nil, dayKey: "2026-05-23"),
            GoalGlimpseItem(id: "c", username: "carol", goalTitle: "Read 12 books",
                            progressPercent: 60, authorColorHex: "#CCC",
                            photoFileURL: nil, dayKey: "2026-05-23"),
        ]
        let result = GlowingSelector.selectGlowingUser(from: eligible)
        let weekOfYear = Calendar(identifier: .iso8601)
            .component(.weekOfYear, from: Date())
        let expectedIndex = weekOfYear % eligible.count
        XCTAssertEqual(result?.id, eligible[expectedIndex].id,
            "selectGlowingUser index must use ISO8601 weekOfYear % count")
    }
}
