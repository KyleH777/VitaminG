import XCTest
import CloudKit
@testable import VitaminG

// RED/SKIP — Wave 0 stub. Tests reference Phase 22 symbols not yet implemented:
//   - PublicProfileViewModel.fetchOverride returning PublicProfileData (Plan 03 updates this)
//   - PublicProfileViewModel.followState (Plan 03)
//   - PublicProfileViewModel.onFollow() (Plan 03)
//   - PublicProfileViewModel.canCheerToday() (Plan 03)
//   - PublicProfileViewModel.onCheer() (Plan 03)
//
// COMPILE-GATE blocks (#if false) contain the real assertions these tests will perform
// once Plan 03 ships. The blocks must be enabled (remove #if false / #endif) in Plan 03
// when the production symbols are added to PublicProfileViewModel.
//
// All tests XCTSkip so the suite is green-skip in Wave 0, not red-fail.

@MainActor
final class Phase22PublicProfileViewModelTests: XCTestCase {

    var sut: PublicProfileViewModel!

    override func setUp() async throws {
        sut = PublicProfileViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // PROF-01: fetchProfile success transitions to .loaded with PublicProfileData.
    // Wave 0: SKIP — fetchOverride return type is still (String?, String?) until Plan 03.
    func test_fetchProfile_success_transitionsToLoaded_withPublicProfileData() async throws {
        throw XCTSkip("Wave 0 stub — PublicProfileViewModel.fetchOverride returns PublicProfileData in Plan 03")

        // COMPILE-GATE: Enable in Plan 03 when fetchOverride returns PublicProfileData.
        #if false
        let mockProfile = PublicProfileData(
            displayName: "Alice", avatarColorHex: "#FF8C44",
            username: "alice", motto: "Keep going",
            streakLength: 7, goalCount: 3, cheersGivenCount: 5
        )
        sut.fetchOverride = { _ in mockProfile }
        sut.fetchProfile(recordID: "abc123")
        try await Task.sleep(nanoseconds: 50_000_000)
        if case .loaded(let profile) = sut.state {
            XCTAssertEqual(profile.displayName, "Alice")
            XCTAssertEqual(profile.motto, "Keep going")
            XCTAssertEqual(profile.streakLength, 7)
        } else {
            XCTFail("Expected .loaded(profile:), got \(sut.state)")
        }
        #endif
    }

    // PROF-01: fetchProfile failure transitions to .error.
    // Wave 0: SKIP — depends on updated fetchOverride return type from Plan 03.
    func test_fetchProfile_failure_transitionsToError() async throws {
        throw XCTSkip("Wave 0 stub — implemented in Plan 03")

        // COMPILE-GATE: Enable in Plan 03.
        #if false
        sut.fetchOverride = { _ in throw CKError(.unknownItem) }
        sut.fetchProfile(recordID: "gone")
        try await Task.sleep(nanoseconds: 50_000_000)
        if case .error = sut.state {
            // pass
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
        #endif
    }

    // PROF-02: followState is .idle on fresh ViewModel.
    // Wave 0: SKIP — followState property not yet on PublicProfileViewModel.
    func test_followState_initial_isIdle() async throws {
        throw XCTSkip("Wave 0 stub — PublicProfileViewModel.followState added in Plan 03")

        // COMPILE-GATE: Enable in Plan 03 when followState is added.
        #if false
        XCTAssertEqual(sut.followState, PublicProfileViewModel.FollowState.idle)
        #endif
    }

    // PROF-02: onFollow transitions followState: .idle -> .loading -> .followed.
    // Wave 0: SKIP — onFollow not yet on PublicProfileViewModel.
    func test_onFollow_transitionsLoadingThenFollowed() async throws {
        throw XCTSkip("Wave 0 stub — PublicProfileViewModel.onFollow implemented in Plan 03")

        // COMPILE-GATE: Enable in Plan 03.
        #if false
        sut.followOverride = { _, _ in } // no-op override
        XCTAssertEqual(sut.followState, .idle)
        sut.onFollow(followerUsername: "me", followeeUsername: "alice")
        XCTAssertEqual(sut.followState, .loading)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(sut.followState, .followed)
        #endif
    }

    // PROF-03: canCheerToday returns true for a fresh date (no prior cheer for recipient).
    // Wave 0: SKIP — canCheerToday not yet on PublicProfileViewModel.
    func test_canCheerToday_trueOnFreshDate() async throws {
        throw XCTSkip("Wave 0 stub — PublicProfileViewModel.canCheerToday implemented in Plan 03")

        // COMPILE-GATE: Enable in Plan 03 when canCheerToday(recipientUsername:defaults:) is added.
        #if false
        let suiteName = "test.cheer.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }
        let result = sut.canCheerToday(recipientUsername: "alice", defaults: testDefaults)
        XCTAssertTrue(result, "canCheerToday must return true when no prior cheer today")
        #endif
    }

    // PROF-03: canCheerToday returns false after markApplauseGiven (daily gate).
    // Wave 0: SKIP — canCheerToday not yet on PublicProfileViewModel.
    func test_canCheerToday_falseAfterMarkApplauseGiven() async throws {
        throw XCTSkip("Wave 0 stub — PublicProfileViewModel.canCheerToday implemented in Plan 03")

        // COMPILE-GATE: Enable in Plan 03.
        #if false
        let suiteName = "test.cheer.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }
        ApplauseGate.markApplauseGiven(to: "alice", defaults: testDefaults)
        let result = sut.canCheerToday(recipientUsername: "alice", defaults: testDefaults)
        XCTAssertFalse(result, "canCheerToday must return false after applause given today")
        #endif
    }
}
