import XCTest
import CloudKit
@testable import VitaminG

// Phase 22 Plan 03 — PublicProfileViewModel tests.
// All tests are now LIVE — Plan 03 adds followState, onFollow, canCheerToday, and onCheer.

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
    func test_followState_initial_isIdle() async throws {
        XCTAssertEqual(sut.followState, FollowState.idle)
    }

    // PROF-02: onFollow transitions followState: .idle -> .loading -> .followed.
    // Uses writeFollowOverride seam — no CloudKit.
    func test_onFollow_transitionsLoadingThenFollowed() async throws {
        sut.writeFollowOverride = { _, _ in } // no-op override — instant success
        XCTAssertEqual(sut.followState, .idle)
        sut.onFollow(followerUsername: "me", followeeUsername: "alice")
        // After calling onFollow, the Task is launched and followState transitions .loading then .followed
        // We wait for the async Task to complete
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(sut.followState, .followed)
    }

    // PROF-03: canCheerToday returns true for a fresh date (no prior cheer for recipient).
    func test_canCheerToday_trueOnFreshDate() async throws {
        let suiteName = "test.cheer.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }
        let result = sut.canCheerToday(recipientUsername: "alice", defaults: testDefaults)
        XCTAssertTrue(result, "canCheerToday must return true when no prior cheer today")
    }

    // PROF-03: canCheerToday returns false after markApplauseGiven (daily gate).
    func test_canCheerToday_falseAfterMarkApplauseGiven() async throws {
        let suiteName = "test.cheer.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }
        ApplauseGate.markApplauseGiven(to: "alice", defaults: testDefaults)
        let result = sut.canCheerToday(recipientUsername: "alice", defaults: testDefaults)
        XCTAssertFalse(result, "canCheerToday must return false after applause given today")
    }
}
