import XCTest
import SwiftData
@testable import VitaminG

// RED stubs for WatchSnapshot — Wave 1 (Plan 27-02) makes these GREEN.
// WatchSnapshot type does not exist yet; test bodies compile today
// because all assertions are XCTFail placeholders with no references
// to unresolved symbols outside of TODO comments.
final class WatchSnapshotTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // WATCH-02: WatchSnapshot.build() returns the active goal title from the highest-priority tier
    // TODO: replace with WatchSnapshot.build(goals:events:context:) once type exists in Plan 27-02
    func test_build_returnsActiveGoalTitle_fromHighestPriorityTier() {
        XCTFail("RED stub — WatchSnapshot not yet implemented in Plan 02")
    }

    // WATCH-02: WatchSnapshot.build() returns activeGoalProgress in range 0.0–1.0
    // TODO: assert snapshot.activeGoalProgress is in 0.0...1.0
    func test_build_returnsActiveGoalProgress_zeroToOne() {
        XCTFail("RED stub — WatchSnapshot not yet implemented in Plan 02")
    }

    // WATCH-02: WatchSnapshot.build() returns the global streak from StreakEngine
    // TODO: assert snapshot.globalStreak == expected streak count
    func test_build_returnsGlobalStreak_fromStreakEngine() {
        XCTFail("RED stub — WatchSnapshot not yet implemented in Plan 02")
    }

    // WATCH-02: WatchSnapshot.build() returns hasCheckedInToday == true when a today event exists
    // TODO: insert CompletionEvent with completedAt == today, assert snapshot.hasCheckedInToday == true
    func test_build_returnsHasCheckedInToday_trueWhenTodayEventExists() {
        XCTFail("RED stub — WatchSnapshot not yet implemented in Plan 02")
    }

    // WATCH-02: WatchSnapshot.build() returns activeGoalId as UUID string
    // TODO: assert snapshot.activeGoalId == activeGoal.id.uuidString
    func test_build_returnsActiveGoalId_uuidString() {
        XCTFail("RED stub — WatchSnapshot not yet implemented in Plan 02")
    }

    // WATCH-02: WatchSnapshot round-trips through JSONEncoder/JSONDecoder without data loss
    // TODO: encode WatchSnapshot via JSONEncoder, decode via JSONDecoder, assert field equality
    func test_codable_roundTripsThroughJSONEncoderDecoder() {
        XCTFail("RED stub — WatchSnapshot not yet implemented in Plan 02")
    }
}
