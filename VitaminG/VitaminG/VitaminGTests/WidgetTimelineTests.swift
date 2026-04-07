import XCTest
@testable import VitaminG

final class WidgetTimelineTests: XCTestCase {

    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
    }

    // WIDGET-05: Widget timeline refreshes at least once daily
    func test_nextMorningRefreshDate_beforeTargetTime_returnsToday() throws {
        // Set "now" to 6:00 AM, target is 8:00 AM — should return today at 8:00
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0
        components.second = 0
        let sixAM = calendar.date(from: components)!

        let result = WidgetDataProvider.nextMorningRefreshDate(
            hour: 8, minute: 0, now: sixAM, calendar: calendar
        )

        let resultComponents = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(resultComponents.hour, 8)
        XCTAssertEqual(resultComponents.minute, 0)
        // Should be same day
        XCTAssertTrue(calendar.isDate(result, inSameDayAs: sixAM),
                      "Before target time, refresh should be today")
    }

    func test_nextMorningRefreshDate_afterTargetTime_returnsTomorrow() throws {
        // Set "now" to 10:00 AM, target is 8:00 AM — should return tomorrow at 8:00
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 10
        components.minute = 0
        components.second = 0
        let tenAM = calendar.date(from: components)!

        let result = WidgetDataProvider.nextMorningRefreshDate(
            hour: 8, minute: 0, now: tenAM, calendar: calendar
        )

        let resultComponents = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(resultComponents.hour, 8)
        XCTAssertEqual(resultComponents.minute, 0)
        // Should be next day
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: tenAM)!
        XCTAssertTrue(calendar.isDate(result, inSameDayAs: tomorrow),
                      "After target time, refresh should be tomorrow")
    }

    func test_nextMorningRefreshDate_defaultsTo8AM_whenNoUserDefaultsSet() throws {
        // Default parameters are hour: 8, minute: 0
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 3
        components.minute = 0
        components.second = 0
        let threeAM = calendar.date(from: components)!

        let result = WidgetDataProvider.nextMorningRefreshDate(now: threeAM, calendar: calendar)

        let resultComponents = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(resultComponents.hour, 8, "Default hour should be 8")
        XCTAssertEqual(resultComponents.minute, 0, "Default minute should be 0")
    }

    func test_nextMorningRefreshDate_customTime() throws {
        // User set notification to 7:30 AM, current time is 6:00 AM
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0
        components.second = 0
        let sixAM = calendar.date(from: components)!

        let result = WidgetDataProvider.nextMorningRefreshDate(
            hour: 7, minute: 30, now: sixAM, calendar: calendar
        )

        let resultComponents = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(resultComponents.hour, 7)
        XCTAssertEqual(resultComponents.minute, 30)
    }
}
