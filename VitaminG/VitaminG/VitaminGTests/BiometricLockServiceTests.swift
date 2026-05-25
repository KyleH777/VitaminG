// VitaminGTests/BiometricLockServiceTests.swift
import XCTest
@testable import VitaminG

final class BiometricLockServiceTests: XCTestCase {

    private let enabledKey = "vg_biometric_lock_enabled"
    private let service = BiometricLockService.shared

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: enabledKey)
        service.isEnabled = false
        service.isLocked = false
    }

    override func tearDown() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        service.isLocked = false
        super.tearDown()
    }

    func testIsEnabled_defaultsFalse() {
        XCTAssertFalse(service.isEnabled)
    }

    func testIsEnabled_persistsToUserDefaults() {
        service.isEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: enabledKey))
        service.isEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: enabledKey))
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
