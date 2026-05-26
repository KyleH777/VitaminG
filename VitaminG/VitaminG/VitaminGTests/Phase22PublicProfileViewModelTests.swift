import XCTest
import CloudKit
@testable import VitaminG

// Phase 22 Plan 02 — PublicProfileViewModel tests.
// fetch-path tests (fetchProfile success + failure) are now LIVE — Plan 02 updates
// PublicProfileViewModel.fetchOverride to return PublicProfileData and updates ViewState.
//
// Follow/cheer tests remain XCTSkip — those require Plan 03 to add followState,
// onFollow, canCheerToday, and onCheer to PublicProfileViewModel.

@MainActor
final class Phase22PublicProfileViewModelTests: XCTestCase {

    var sut: PublicProfileViewModel!

    override func setUp() async throws {
        sut = PublicProfileViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // PROF-01: fetchProfile success transitions to .loaded(profile:) with full PublicProfileData.
    // Now LIVE — PublicProfileViewModel.fetchOverride returns PublicProfileData (Plan 02).
    func test_fetchProfile_success_transitionsToLoaded_withPublicProfileData() async throws {
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
            XCTAssertEqual(profile.goalCount, 3)
        } else {
            XCTFail("Expected .loaded(profile:), got \(sut.state)")
        }
    }

    // PROF-01: fetchProfile failure transitions to .error.
    // Now LIVE — fetchOverride return type is PublicProfileData (Plan 02).
    func test_fetchProfile_failure_transitionsToError() async throws {
        sut.fetchOverride = { _ in throw CKError(.unknownItem) }
        sut.fetchProfile(recordID: "gone")
        try await Task.sleep(nanoseconds: 50_000_000)
        if case .error = sut.state {
            // pass
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    // PROF-02: followState is .idle on fresh ViewModel.
    // Wave 0: SKIP — followState property not yet on PublicProfileViewModel (added in Plan 03).
    func test_followState_initial_isIdle() async throws {
        throw XCTSkip("Plan 03 stub — PublicProfileViewModel.followState added in Plan 03")

        // COMPILE-GATE: Enable in Plan 03 when followState is added.
        #if false
        XCTAssertEqual(sut.followState, PublicProfileViewModel.FollowState.idle)
        #endif
    }

    // PROF-02: onFollow transitions followState: .idle -> .loading -> .followed.
    // Wave 0: SKIP — onFollow not yet on PublicProfileViewModel (added in Plan 03).
    func test_onFollow_transitionsLoadingThenFollowed() async throws {
        throw XCTSkip("Plan 03 stub — PublicProfileViewModel.onFollow implemented in Plan 03")

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
    // Wave 0: SKIP — canCheerToday not yet on PublicProfileViewModel (added in Plan 03).
    func test_canCheerToday_trueOnFreshDate() async throws {
        throw XCTSkip("Plan 03 stub — PublicProfileViewModel.canCheerToday implemented in Plan 03")

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
    // Wave 0: SKIP — canCheerToday not yet on PublicProfileViewModel (added in Plan 03).
    func test_canCheerToday_falseAfterMarkApplauseGiven() async throws {
        throw XCTSkip("Plan 03 stub — PublicProfileViewModel.canCheerToday implemented in Plan 03")

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
