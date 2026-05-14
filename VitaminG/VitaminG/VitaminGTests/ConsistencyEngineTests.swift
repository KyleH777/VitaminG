import XCTest
@testable import VitaminG

final class ConsistencyEngineTests: XCTestCase {

    private func events(daysAgo offsets: [Int], reference: Date = .now) -> [CompletionEvent] {
        let cal = Calendar.current
        return offsets.compactMap { offset -> CompletionEvent? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: reference) else { return nil }
            let e = CompletionEvent()
            e.completedAt = date
            return e
        }
    }

    func test_perfectMonth_scores100() {
        let evts = events(daysAgo: Array(0...29))
        let score = ConsistencyEngine.score(events: evts)
        XCTAssertEqual(score, 100)
    }

    func test_noEvents_scores0() {
        let score = ConsistencyEngine.score(events: [])
        XCTAssertEqual(score, 0)
    }

    func test_onlyToday_scoredHighlyDueToWeight() {
        let evts = events(daysAgo: [0])
        let score = ConsistencyEngine.score(events: evts)
        XCTAssertGreaterThan(score, 50)
    }

    func test_onlyOldestDay_scoredLow() {
        let evts = events(daysAgo: [29])
        let score = ConsistencyEngine.score(events: evts)
        XCTAssertLessThan(score, 30)
    }

    func test_recentDays_returnsCorrectBoolArray() {
        let evts = events(daysAgo: [0, 2])
        let days = ConsistencyEngine.recentDays(events: evts)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(days[0])
        XCTAssertFalse(days[1])
        XCTAssertTrue(days[2])
        XCTAssertFalse(days[3])
    }

    func test_eventsOlderThan30Days_ignored() {
        let evts = events(daysAgo: [31])
        let score = ConsistencyEngine.score(events: evts)
        XCTAssertEqual(score, 0)
    }
}
