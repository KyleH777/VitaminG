// VitaminGTests/BiometricLockServiceTests.swift
import XCTest
@testable import VitaminG

// [Rule 3 - Blocking] Fixed Swift 6 actor isolation errors: BiometricLockService is @MainActor;
// added @MainActor to the test class so all accesses occur on the correct actor.
@MainActor
final class BiometricLockServiceTests: XCTestCase {

    private let service = BiometricLockService.shared

    override func setUp() {
        super.setUp()
        service.resetForTesting()
    }

    override func tearDown() {
        service.resetForTesting()
        super.tearDown()
    }

    func testIsEnabled_defaultsFalse() {
        XCTAssertFalse(service.isEnabled)
    }

    func testIsEnabled_persistsToUserDefaults() {
        service.isEnabled = true
        // Verify by creating a new instance reading from UserDefaults
        let storedValue = UserDefaults.standard.bool(forKey: "vg_biometric_lock_enabled")
        XCTAssertTrue(storedValue)
        service.isEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "vg_biometric_lock_enabled"))
    }

    func testLockIfEnabled_locksWhenEnabled() {
        service.isEnabled = true
        service.lockIfEnabled()
        XCTAssertTrue(service.isLocked)
    }

    func testLockIfEnabled_doesNotLockWhenDisabled() {
        service.isEnabled = false
        service.lockIfEnabled()
        XCTAssertFalse(service.isLocked)
    }

    func testIsLocked_defaultsFalse() {
        XCTAssertFalse(service.isLocked)
    }
}
