import XCTest
import SwiftData
@testable import VitaminG

// WATCH-03: WatchSessionManager.handleCheckIn tests — made GREEN in Plan 27-05.
// Tests use closure-injection seam: all three production closures (onCheckIn,
// cancelStreakAtRiskNudge, reloadWidgetTimelines) are replaced with recording stubs
// so production NotificationScheduler/WidgetCenter calls are never exercised.
@MainActor
final class WatchSessionManagerTests: XCTestCase {

    private var manager: WatchSessionManager!

    override func setUpWithError() throws {
        // Each test gets a fresh reference to the shared singleton.
        // Closures are reset to stubs so production side-effects don't fire.
        manager = WatchSessionManager.shared
    }

    override func tearDownWithError() throws {
        // Restore defaults so production closures don't remain replaced across tests.
        manager.onCheckIn = nil
        manager.cancelStreakAtRiskNudge = nil
        manager.reloadWidgetTimelines = nil
        manager = nil
    }

    // WATCH-03: handleCheckIn invokes the onCheckIn closure with the correct UUID
    func test_handleCheckIn_invokesAddCheckInForCorrectGoal() {
        let uuid = UUID()
        var recordedId: UUID? = nil

        // Inject recording stubs
        manager.onCheckIn = { id in recordedId = id }
        manager.cancelStreakAtRiskNudge = {}
        manager.reloadWidgetTimelines = {}

        manager.handleCheckIn(userInfo: ["action": "checkIn", "goalId": uuid.uuidString])

        XCTAssertEqual(recordedId, uuid, "onCheckIn should be called with the matching UUID")
    }

    // WATCH-03: handleCheckIn calls cancelStreakAtRiskNudge exactly once on valid payload
    func test_handleCheckIn_callsCancelGlobalStreakAtRiskNudge() {
        let uuid = UUID()
        var cancelCallCount = 0
        var onCheckInCallCount = 0

        manager.onCheckIn = { _ in onCheckInCallCount += 1 }
        manager.cancelStreakAtRiskNudge = { cancelCallCount += 1 }
        manager.reloadWidgetTimelines = {}

        manager.handleCheckIn(userInfo: ["action": "checkIn", "goalId": uuid.uuidString])

        XCTAssertEqual(cancelCallCount, 1, "cancelStreakAtRiskNudge should be called exactly once")
    }

    // WATCH-03: handleCheckIn calls reloadWidgetTimelines exactly once on valid payload
    func test_handleCheckIn_callsWidgetCenterReloadAllTimelines() {
        let uuid = UUID()
        var reloadCallCount = 0

        manager.onCheckIn = { _ in }
        manager.cancelStreakAtRiskNudge = {}
        manager.reloadWidgetTimelines = { reloadCallCount += 1 }

        manager.handleCheckIn(userInfo: ["action": "checkIn", "goalId": uuid.uuidString])

        XCTAssertEqual(reloadCallCount, 1, "reloadWidgetTimelines should be called exactly once")
    }

    // WATCH-03: handleCheckIn ignores payload missing the "action":"checkIn" key
    func test_handleCheckIn_ignoresPayloadWithoutActionCheckIn() {
        let uuid = UUID()
        var onCheckInCallCount = 0
        var cancelCallCount = 0
        var reloadCallCount = 0

        manager.onCheckIn = { _ in onCheckInCallCount += 1 }
        manager.cancelStreakAtRiskNudge = { cancelCallCount += 1 }
        manager.reloadWidgetTimelines = { reloadCallCount += 1 }

        // No "action" key — should be ignored entirely
        manager.handleCheckIn(userInfo: ["goalId": uuid.uuidString])

        XCTAssertEqual(onCheckInCallCount, 0, "onCheckIn should NOT be called without action key")
        XCTAssertEqual(cancelCallCount, 0, "cancelStreakAtRiskNudge should NOT be called")
        XCTAssertEqual(reloadCallCount, 0, "reloadWidgetTimelines should NOT be called")
    }

    // WATCH-03: handleCheckIn ignores payload with a non-UUID goalId string
    func test_handleCheckIn_ignoresPayloadWithInvalidGoalId() {
        var onCheckInCallCount = 0
        var cancelCallCount = 0
        var reloadCallCount = 0

        manager.onCheckIn = { _ in onCheckInCallCount += 1 }
        manager.cancelStreakAtRiskNudge = { cancelCallCount += 1 }
        manager.reloadWidgetTimelines = { reloadCallCount += 1 }

        // "not-a-uuid" cannot be parsed by UUID(uuidString:) — should be ignored
        manager.handleCheckIn(userInfo: ["action": "checkIn", "goalId": "not-a-uuid"])

        XCTAssertEqual(onCheckInCallCount, 0, "onCheckIn should NOT be called with invalid goalId")
        XCTAssertEqual(cancelCallCount, 0, "cancelStreakAtRiskNudge should NOT be called")
        XCTAssertEqual(reloadCallCount, 0, "reloadWidgetTimelines should NOT be called")
    }
}
