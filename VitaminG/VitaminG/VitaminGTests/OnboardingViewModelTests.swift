// VitaminGTests/OnboardingViewModelTests.swift
import XCTest
@testable import VitaminG

@MainActor
final class OnboardingViewModelUnitTests: XCTestCase {

    private var sut: OnboardingViewModel!
    private var testDefaults: UserDefaults!
    private let suiteName = "com.vitamingapp.onboardingvm.tests"

    override func setUpWithError() throws {
        testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)
        sut = OnboardingViewModel(defaults: testDefaults)
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: suiteName)
        sut = nil
        testDefaults = nil
    }

    // MARK: savedName

    func test_savedName_whenNameStored_returnsName() {
        testDefaults.set("Maya", forKey: "vg_onboardingName")
        XCTAssertEqual(sut.savedName, "Maya")
    }

    func test_savedName_whenNothingStored_returnsEmpty() {
        XCTAssertEqual(sut.savedName, "")
    }

    func test_savedName_tripsWhitespace() {
        testDefaults.set("  Maya  ", forKey: "vg_onboardingName")
        XCTAssertEqual(sut.savedName, "Maya")
    }

    // MARK: isReturningUser

    func test_isReturningUser_whenNameStored_returnsTrue() {
        testDefaults.set("Maya", forKey: "vg_onboardingName")
        XCTAssertTrue(sut.isReturningUser)
    }

    func test_isReturningUser_whenNoName_returnsFalse() {
        XCTAssertFalse(sut.isReturningUser)
    }

    func test_isReturningUser_whitespaceOnlyName_returnsFalse() {
        testDefaults.set("   ", forKey: "vg_onboardingName")
        XCTAssertFalse(sut.isReturningUser)
    }

    // MARK: restartOnboarding

    func test_restartOnboarding_clearsNameKey() {
        testDefaults.set("Maya", forKey: "vg_onboardingName")
        sut.restartOnboarding()
        XCTAssertNil(testDefaults.string(forKey: "vg_onboardingName"))
    }

    func test_restartOnboarding_clearsCompletedKey() {
        testDefaults.set(true, forKey: "hasCompletedOnboarding")
        sut.restartOnboarding()
        XCTAssertFalse(testDefaults.bool(forKey: "hasCompletedOnboarding"))
    }
}
