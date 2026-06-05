import XCTest
import SwiftData
@testable import VitaminG

// GREEN tests for WatchReceiver — Wave 2 (Plan 27-03).
//
// Tests construct a WatchSnapshot, encode it as Data, build an applicationContext dictionary,
// then call processApplicationContext(_:into:) on a fresh ephemeral UserDefaults suite.
// This bypasses WCSession entirely — no WCSession can be instantiated in unit tests.
//
// Teardown removes the ephemeral UserDefaults suite to ensure test isolation.
final class WatchReceiverTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a uniquely-named ephemeral UserDefaults for test isolation.
    private func makeEphemeralDefaults() -> (UserDefaults, String) {
        let suiteName = "test-watch-snapshot-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (defaults, suiteName)
    }

    /// Encodes a WatchSnapshot into an applicationContext dictionary.
    private func makeApplicationContext(snapshot: WatchSnapshot) -> [String: Any] {
        let data = try! JSONEncoder().encode(snapshot)
        return ["snapshot": data]
    }

    // MARK: - Tests

    // WATCH-02: WatchReceiver.processApplicationContext writes activeGoalTitle to UserDefaults
    func test_didReceiveApplicationContext_writesActiveGoalTitleToUserDefaults() {
        let (defaults, suiteName) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let snapshot = WatchSnapshot(
            activeGoalTitle: "Read every day",
            activeGoalProgress: 0.5,
            globalStreak: 3,
            hasCheckedInToday: false,
            activeGoalId: nil
        )
        let context = makeApplicationContext(snapshot: snapshot)

        WatchReceiver.shared.processApplicationContext(context, into: defaults)

        XCTAssertEqual(
            defaults.string(forKey: "watchSnapshot_activeGoalTitle"),
            "Read every day",
            "activeGoalTitle should be written to UserDefaults"
        )
    }

    // WATCH-02: WatchReceiver.processApplicationContext writes activeGoalProgress to UserDefaults
    func test_didReceiveApplicationContext_writesActiveGoalProgressToUserDefaults() {
        let (defaults, suiteName) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let snapshot = WatchSnapshot(
            activeGoalTitle: nil,
            activeGoalProgress: 0.42,
            globalStreak: 0,
            hasCheckedInToday: false,
            activeGoalId: nil
        )
        let context = makeApplicationContext(snapshot: snapshot)

        WatchReceiver.shared.processApplicationContext(context, into: defaults)

        XCTAssertEqual(
            defaults.double(forKey: "watchSnapshot_activeGoalProgress"),
            0.42,
            accuracy: 1e-6,
            "activeGoalProgress should be written to UserDefaults"
        )
    }

    // WATCH-02: WatchReceiver.processApplicationContext writes globalStreak to UserDefaults
    func test_didReceiveApplicationContext_writesGlobalStreakToUserDefaults() {
        let (defaults, suiteName) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let snapshot = WatchSnapshot(
            activeGoalTitle: nil,
            activeGoalProgress: 0.0,
            globalStreak: 12,
            hasCheckedInToday: false,
            activeGoalId: nil
        )
        let context = makeApplicationContext(snapshot: snapshot)

        WatchReceiver.shared.processApplicationContext(context, into: defaults)

        XCTAssertEqual(
            defaults.integer(forKey: "watchSnapshot_globalStreak"),
            12,
            "globalStreak should be written to UserDefaults"
        )
    }

    // WATCH-02: WatchReceiver.processApplicationContext writes hasCheckedInToday to UserDefaults
    func test_didReceiveApplicationContext_writesHasCheckedInTodayToUserDefaults() {
        let (defaults, suiteName) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let snapshot = WatchSnapshot(
            activeGoalTitle: nil,
            activeGoalProgress: 0.0,
            globalStreak: 0,
            hasCheckedInToday: true,
            activeGoalId: nil
        )
        let context = makeApplicationContext(snapshot: snapshot)

        WatchReceiver.shared.processApplicationContext(context, into: defaults)

        XCTAssertTrue(
            defaults.bool(forKey: "watchSnapshot_hasCheckedInToday"),
            "hasCheckedInToday should be written as true to UserDefaults"
        )
    }

    // WATCH-02: WatchReceiver.processApplicationContext writes activeGoalId to UserDefaults
    func test_didReceiveApplicationContext_writesActiveGoalIdToUserDefaults() {
        let (defaults, suiteName) = makeEphemeralDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let goalId = UUID().uuidString
        let snapshot = WatchSnapshot(
            activeGoalTitle: "Evening meditation",
            activeGoalProgress: 0.8,
            globalStreak: 5,
            hasCheckedInToday: false,
            activeGoalId: goalId
        )
        let context = makeApplicationContext(snapshot: snapshot)

        WatchReceiver.shared.processApplicationContext(context, into: defaults)

        XCTAssertEqual(
            defaults.string(forKey: "watchSnapshot_activeGoalId"),
            goalId,
            "activeGoalId should be written to UserDefaults"
        )
    }
}
