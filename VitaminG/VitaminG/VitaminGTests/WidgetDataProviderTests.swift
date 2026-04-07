import XCTest
@testable import VitaminG

final class WidgetDataProviderTests: XCTestCase {

    // WIDGET-01: Home screen widget shows top active goals across tiers
    func test_build_returnsOneTierRowPerTier() throws {
        // STUB: Will test that build() returns exactly 4 TierRow entries (one per GoalTier.ordered)
        // Implementation in Plan 02
        XCTExpectFailure("Wave 0 stub — WidgetDataProvider not yet implemented")
        XCTFail("Stub: WidgetDataProvider.build() must return 4 tier rows")
    }

    func test_build_topGoalPerTier_isFirstActiveByCreationDate() throws {
        XCTExpectFailure("Wave 0 stub — WidgetDataProvider not yet implemented")
        XCTFail("Stub: each tier row topGoalTitle should be the earliest-created active goal")
    }

    func test_build_emptyTier_returnsNilTitle() throws {
        XCTExpectFailure("Wave 0 stub — WidgetDataProvider not yet implemented")
        XCTFail("Stub: tier with no active goals should have topGoalTitle == nil")
    }

    // WIDGET-02: Lock screen widget shows global streak or top Immediate goal
    func test_build_globalStreak_computedFromEvents() throws {
        XCTExpectFailure("Wave 0 stub — WidgetDataProvider not yet implemented")
        XCTFail("Stub: globalStreak should match StreakEngine.currentStreak(from:)")
    }

    func test_build_noGoals_allTierRowsNil() throws {
        XCTExpectFailure("Wave 0 stub — WidgetDataProvider not yet implemented")
        XCTFail("Stub: empty goals array produces all-nil tier rows and streak 0")
    }
}
