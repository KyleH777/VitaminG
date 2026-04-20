import XCTest
import CloudKit
@testable import VitaminG

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
        sut.fetchOverride = { _ in ("Alice", "#FF8C44") }
        sut.fetchProfile(recordID: "abc123")
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms for Task to complete
        if case .loaded(let name, let hex) = sut.state {
            XCTAssertEqual(name, "Alice")
            XCTAssertEqual(hex, "#FF8C44")
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
