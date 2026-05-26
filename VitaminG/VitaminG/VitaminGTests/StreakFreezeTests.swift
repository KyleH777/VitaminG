import XCTest
@testable import VitaminG

final class StreakFreezeTests: XCTestCase {

    var service: StreakFreezeService!
    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.streakfreeze")!
        defaults.removePersistentDomain(forName: "test.streakfreeze")
        service = StreakFreezeService(defaults: defaults)
    }

    func test_canFreeze_trueOnFreshInstall() {
        XCTAssertTrue(service.canFreeze)
    }

    func test_afterFreeze_canFreezeIsFalse() {
        service.freeze()
        XCTAssertFalse(service.canFreeze)
    }

    func test_frozenDates_containsTodayAfterFreeze() {
        let today = Calendar.current.startOfDay(for: .now)
        service.freeze()
        XCTAssertTrue(service.frozenDates.contains(today))
    }

    // MARK: - Weekly gate tests (replaces monthly gate tests)

    func test_freezeOnDifferentWeek_resetsAvailability() {
        // Freeze 8 days ago (guaranteed different ISO week)
        let iso = Calendar(identifier: .iso8601)
        let eightDaysAgo = iso.date(byAdding: .day, value: -8, to: .now)!
        service.freeze(on: eightDaysAgo)
        // canFreeze should return true because that freeze was in a different ISO week
        XCTAssertTrue(service.canFreeze,
            "Expected canFreeze to be true after freeze 8 days ago in a different ISO week")
    }

    func test_twoFreezesInSameWeek_secondIsIgnored() {
        service.freeze()
        let countBefore = service.frozenDates.count
        service.freeze()
        XCTAssertEqual(service.frozenDates.count, countBefore,
            "Expected second freeze in same week to be ignored")
    }

    func test_yearBoundary_week52ToWeek1_resetsAvailability() {
        // Freeze on Dec 28, 2025 (week 52 of 2025 in ISO8601)
        let iso = Calendar(identifier: .iso8601)
        guard let dec28 = iso.date(from: DateComponents(
            weekday: 1, weekOfYear: 52, yearForWeekOfYear: 2025
        )) else {
            XCTFail("Could not construct Dec 28 date")
            return
        }
        service.freeze(on: dec28)

        // Simulate checking canFreeze on Jan 5, 2026 (week 1 of 2026 in ISO8601)
        guard let jan5 = iso.date(from: DateComponents(
            weekday: 1, weekOfYear: 1, yearForWeekOfYear: 2026
        )) else {
            XCTFail("Could not construct Jan 5 date")
            return
        }
        XCTAssertTrue(service.canFreezeRelativeTo(jan5),
            "Expected canFreezeRelativeTo(Jan 5 2026) to be true after freeze on Dec 28 2025 — year boundary must reset availability")
    }
}
