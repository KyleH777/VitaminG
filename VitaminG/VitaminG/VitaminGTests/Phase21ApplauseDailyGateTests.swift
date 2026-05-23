import XCTest
@testable import VitaminG

// GREEN — Plan 03 implemented ApplauseGate.
// Tests verify the daily-per-recipient applause gate (SOC-01 / D-04).
// UserDefaults key: "vg_community_applauseGiven"
// Value: Data (JSONEncoder([String: Date])) — dict keyed on recipientUsername.

final class Phase21ApplauseDailyGateTests: XCTestCase {

    // Isolated UserDefaults suite per test run to avoid cross-test pollution.
    private var testDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test.applause.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        super.tearDown()
    }

    // SOC-01 / 21-xx-08 — gate not triggered when no prior applause recorded
    // Expected assertion: canApplaud(recipientUsername: "alice") == true
    // with a fresh (empty) UserDefaults suite.
    func test_canApplaud_returnsTrueWhenNoPriorApplause() throws {
        let result = ApplauseGate.canApplaud(
            recipientUsername: "alice",
            defaults: testDefaults
        )
        XCTAssertTrue(result, "Must return true when no prior applause for recipient")
    }

    // SOC-01 / 21-xx-08 — gate blocks same recipient on same day
    // Expected assertion: after markApplauseGiven(to: "alice"),
    // canApplaud("alice") == false.
    func test_canApplaud_returnsFalseAfterApplaudingSameRecipientToday() throws {
        ApplauseGate.markApplauseGiven(to: "alice", defaults: testDefaults)
        let result = ApplauseGate.canApplaud(
            recipientUsername: "alice",
            defaults: testDefaults
        )
        XCTAssertFalse(result,
            "Must return false after applauding same recipient today (SOC-01 daily gate)")
    }

    // SOC-01 / 21-xx-09 — gate is per-recipient; different recipient not blocked
    // Expected assertion: after markApplauseGiven(to: "alice"),
    // canApplaud("bob") == true (bob not affected by alice's gate).
    func test_canApplaud_perRecipient_trueForDifferentRecipient() throws {
        ApplauseGate.markApplauseGiven(to: "alice", defaults: testDefaults)
        let result = ApplauseGate.canApplaud(
            recipientUsername: "bob",
            defaults: testDefaults
        )
        XCTAssertTrue(result,
            "Must return true for a different recipient (gate is per-recipient, not global)")
    }
}
