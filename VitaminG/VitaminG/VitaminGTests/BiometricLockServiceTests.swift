// VitaminGTests/BiometricLockServiceTests.swift
import XCTest
@testable import VitaminG

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
