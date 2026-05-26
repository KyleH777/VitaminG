import XCTest
@testable import VitaminG

final class Phase23MilestoneGateTests: XCTestCase {

    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "test.milestoneGate")!
        testDefaults.removePersistentDomain(forName: "test.milestoneGate")
    }

    func test_hasShown_falseForFreshKey() {
        let goalID = UUID()
        XCTAssertFalse(
            StreakMilestoneGate.hasShown(goalID: goalID, threshold: 7, defaults: testDefaults),
            "Expected hasShown to return false for fresh defaults"
        )
    }

    func test_markShown_then_hasShown_returnsTrue() {
        let goalID = UUID()
        StreakMilestoneGate.markShown(goalID: goalID, threshold: 7, defaults: testDefaults)
        XCTAssertTrue(
            StreakMilestoneGate.hasShown(goalID: goalID, threshold: 7, defaults: testDefaults),
            "Expected hasShown to return true after markShown"
        )
    }

    func test_differentThreshold_trackedIndependently() {
        let goalID = UUID()
        StreakMilestoneGate.markShown(goalID: goalID, threshold: 7, defaults: testDefaults)
        XCTAssertFalse(
            StreakMilestoneGate.hasShown(goalID: goalID, threshold: 14, defaults: testDefaults),
            "Expected threshold 14 to be unaffected by marking threshold 7"
        )
    }

    func test_differentGoalID_trackedIndependently() {
        let goalA = UUID()
        let goalB = UUID()
        StreakMilestoneGate.markShown(goalID: goalA, threshold: 7, defaults: testDefaults)
        XCTAssertFalse(
            StreakMilestoneGate.hasShown(goalID: goalB, threshold: 7, defaults: testDefaults),
            "Expected goalB-7 to be unaffected by marking goalA-7"
        )
    }

    func test_allSixThresholdsAreDefined() {
        XCTAssertEqual(
            StreakMilestoneGate.goalStreakThresholds,
            [7, 14, 30, 60, 90, 365],
            "Expected goalStreakThresholds to contain exactly [7, 14, 30, 60, 90, 365]"
        )
    }
}
