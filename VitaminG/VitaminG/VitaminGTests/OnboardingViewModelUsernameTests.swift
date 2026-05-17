// VitaminGTests/OnboardingViewModelUsernameTests.swift
// Tests for OnboardingViewModel UsernameCheckState state machine.
// No CloudKit dependency — tests only the in-memory synchronous guard paths in onUsernameChanged.
//
// Test strategy: onUsernameChanged() has synchronous early returns for invalid chars, short input,
// and empty input. These are tested directly without needing to wait for the debounce Task.

import XCTest
@testable import VitaminG

@MainActor
final class OnboardingViewModelUsernameTests: XCTestCase {

    // MARK: - Invalid Characters → .invalid state

    func testInvalidChars_setsInvalidState() {
        let vm = OnboardingViewModel()
        vm.onUsernameChanged("bad user!")
        XCTAssertEqual(
            vm.usernameCheckState,
            .invalid("Only letters, numbers, and underscores"),
            "Input with spaces/special chars should immediately set .invalid state"
        )
    }

    // MARK: - Short Input → .idle state

    func testShortInput_setsIdleState() {
        let vm = OnboardingViewModel()
        vm.onUsernameChanged("ab")
        XCTAssertEqual(
            vm.usernameCheckState,
            .idle,
            "Input shorter than 3 characters should set .idle state"
        )
    }

    // MARK: - Empty Input → .idle state

    func testEmptyInput_setsIdleState() {
        let vm = OnboardingViewModel()
        vm.onUsernameChanged("")
        XCTAssertEqual(
            vm.usernameCheckState,
            .idle,
            "Empty input should set .idle state"
        )
    }

    // MARK: - Valid Input Does Not Set .invalid

    func testValidInput_remainsIdleBeforeDebounce() {
        let vm = OnboardingViewModel()
        vm.onUsernameChanged("valid_user")
        // Debounce has not fired yet — state must NOT be .invalid since input is valid.
        // It could be .idle (initial) or .checking (if debounce somehow fired synchronously),
        // but it must NOT be .invalid.
        if case .invalid = vm.usernameCheckState {
            XCTFail("Valid input should not result in .invalid state; got \(vm.usernameCheckState)")
        }
    }
}
