import XCTest
@testable import VitaminG

final class StreakFreezeTests: XCTestCase {

    var service: StreakFreezeService!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test.streakfreeze")!
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

    func test_freezeOnDifferentMonth_resetsAvailability() {
        let cal = Calendar.current
        let lastMonth = cal.date(byAdding: .month, value: -1, to: .now)!
        service.freeze(on: lastMonth)
        XCTAssertTrue(service.canFreeze)
    }

    func test_twoFreezesInSameMonth_secondIsIgnored() {
        service.freeze()
        let countBefore = service.frozenDates.count
        service.freeze()
        XCTAssertEqual(service.frozenDates.count, countBefore)
    }
}
