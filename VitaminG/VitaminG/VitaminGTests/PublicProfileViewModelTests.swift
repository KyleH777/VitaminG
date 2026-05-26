import XCTest
import CloudKit
@testable import VitaminG

// Updated in Phase 22 Plan 02: fetchOverride now returns PublicProfileData
// and ViewState.loaded now carries a profile: PublicProfileData associated value.
// Original pre-Phase-22 tests updated to match new signatures.

@MainActor
final class PublicProfileViewModelTests: XCTestCase {

    var sut: PublicProfileViewModel!

    override func setUp() async throws {
        sut = PublicProfileViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }

    func test_initialState_isLoading() {
        if case .loading = sut.state {
            // pass
        } else {
            XCTFail("Expected .loading, got \(sut.state)")
        }
    }

    func test_fetchProfile_success_transitionsToLoaded() async throws {
        let mockProfile = PublicProfileData(
            displayName: "Alice", avatarColorHex: "#FF8C44",
            username: nil, motto: nil,
            streakLength: 0, goalCount: 0, cheersGivenCount: 0
        )
        sut.fetchOverride = { _ in mockProfile }
        sut.fetchProfile(recordID: "abc123")
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms for Task to complete
        if case .loaded(let profile) = sut.state {
            XCTAssertEqual(profile.displayName, "Alice")
            XCTAssertEqual(profile.avatarColorHex, "#FF8C44")
        } else {
            XCTFail("Expected .loaded, got \(sut.state)")
        }
    }

    func test_fetchProfile_unknownItem_transitionsToError() async throws {
        sut.fetchOverride = { _ in throw CKError(.unknownItem) }
        sut.fetchProfile(recordID: "gone")
        try await Task.sleep(nanoseconds: 50_000_000)
        if case .error(let msg) = sut.state {
            XCTAssert(msg.contains("no longer available"), "Error message was: \(msg)")
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }

    func test_fetchProfile_networkFailure_transitionsToError() async throws {
        sut.fetchOverride = { _ in throw CKError(.networkFailure) }
        sut.fetchProfile(recordID: "nonet")
        try await Task.sleep(nanoseconds: 50_000_000)
        if case .error(let msg) = sut.state {
            XCTAssert(msg.contains("internet connection"), "Error message was: \(msg)")
        } else {
            XCTFail("Expected .error, got \(sut.state)")
        }
    }
}
