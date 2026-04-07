import XCTest
@testable import VitaminG

final class WidgetTimelineTests: XCTestCase {

    // WIDGET-05: Widget timeline refreshes at least once daily
    func test_nextMorningRefreshDate_beforeTargetTime_returnsToday() throws {
        XCTExpectFailure("Wave 0 stub — nextMorningRefreshDate not yet implemented")
        XCTFail("Stub: if current time is before notification hour, return today at that hour")
    }

    func test_nextMorningRefreshDate_afterTargetTime_returnsTomorrow() throws {
        XCTExpectFailure("Wave 0 stub — nextMorningRefreshDate not yet implemented")
        XCTFail("Stub: if current time is past notification hour, return tomorrow at that hour")
    }

    func test_nextMorningRefreshDate_defaultsTo8AM_whenNoUserDefaultsSet() throws {
        XCTExpectFailure("Wave 0 stub — nextMorningRefreshDate not yet implemented")
        XCTFail("Stub: absent UserDefaults should default to 8:00 AM")
    }
}
