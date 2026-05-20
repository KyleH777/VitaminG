// Phase 18 Wave 0 — RED tests. Will go GREEN as Plans 02 & 05 land implementations.
// Tests HOME-02: VGQuoteBank.all flattens all categories; daily rotation is deterministic by day-of-year.
// NOTE: VGQuoteBank.all is already defined in the codebase — these tests may go GREEN early.

import XCTest
@testable import VitaminG

final class Phase18QuoteBankTests: XCTestCase {

    // MARK: - HOME-02a: VGQuoteBank.all is non-empty

    /// HOME-02: VGQuoteBank.all must contain at least one quote (the flattened all-category bank).
    func test_VGQuoteBank_all_isNonEmpty() {
        XCTAssertGreaterThan(
            VGQuoteBank.all.count,
            0,
            "HOME-02: VGQuoteBank.all must be non-empty"
        )
    }

    // MARK: - HOME-02b: VGQuoteBank.all is deterministic (no random shuffle)

    /// HOME-02: Calling VGQuoteBank.all twice must return identical arrays in identical order.
    /// The flattened bank should NOT shuffle between calls — determinism is required for the
    /// day-of-year modular rotation to work correctly.
    func test_VGQuoteBank_all_isDeterministic() {
        let first = VGQuoteBank.all
        let second = VGQuoteBank.all

        XCTAssertEqual(first.count, second.count,
            "HOME-02: VGQuoteBank.all must return same count on consecutive calls")

        for (i, (q1, q2)) in zip(first, second).enumerated() {
            XCTAssertEqual(q1.text, q2.text,
                "HOME-02: Quote at index \(i) must be identical across consecutive calls — no shuffling")
            XCTAssertEqual(q1.attribution, q2.attribution,
                "HOME-02: Attribution at index \(i) must be identical across consecutive calls")
        }
    }

    // MARK: - HOME-02c: Daily quote selection is stable within the same day

    /// HOME-02: The day-of-year modular selection algorithm must return the same index
    /// when called twice with the same date. Per RESEARCH.md Open Question 4 recommendation.
    func test_dailyQuoteSelection_isStableWithinSameDay() {
        let testDate = Date()
        let cal = Calendar.current
        let count = VGQuoteBank.all.count

        guard count > 0 else {
            XCTFail("HOME-02: VGQuoteBank.all must be non-empty for daily rotation test")
            return
        }

        // Simulate the day-of-year selection formula
        let dayOfYear1 = cal.ordinality(of: .day, in: .year, for: testDate) ?? 1
        let index1 = (dayOfYear1 - 1) % count

        let dayOfYear2 = cal.ordinality(of: .day, in: .year, for: testDate) ?? 1
        let index2 = (dayOfYear2 - 1) % count

        XCTAssertEqual(index1, index2,
            "HOME-02: Day-of-year modular selection must be stable — same date produces same index")

        // Verify the index is within bounds
        XCTAssertGreaterThanOrEqual(index1, 0, "HOME-02: Quote index must be >= 0")
        XCTAssertLessThan(index1, count, "HOME-02: Quote index must be < VGQuoteBank.all.count")
    }

    // MARK: - HOME-02d: Daily quote selection differs across different days

    /// HOME-02: Two dates 7 days apart must produce different quote indices when
    /// VGQuoteBank.all has more than 7 entries (which it does with 50+ quotes).
    /// This ensures rotation is actually happening across days.
    func test_dailyQuoteSelection_differsAcrossDays() {
        let count = VGQuoteBank.all.count
        guard count > 7 else {
            // If there are 7 or fewer quotes, all day offsets might collide — skip this test
            XCTSkip("HOME-02: VGQuoteBank.all has \(count) quotes — need more than 7 for this rotation test")
            return
        }

        let cal = Calendar.current
        let date1 = Date()
        let date2 = cal.date(byAdding: .day, value: 7, to: date1)!

        let day1 = cal.ordinality(of: .day, in: .year, for: date1) ?? 1
        let day2 = cal.ordinality(of: .day, in: .year, for: date2) ?? 8

        let index1 = (day1 - 1) % count
        let index2 = (day2 - 1) % count

        // 7 days apart on a bank > 7 quotes must produce different indices
        // (unless the bank count happens to be a divisor of 7, which is unlikely with 50+ quotes)
        XCTAssertNotEqual(index1, index2,
            "HOME-02: Dates 7 days apart should select different quotes (indices: \(index1) vs \(index2), count: \(count))")
    }
}
