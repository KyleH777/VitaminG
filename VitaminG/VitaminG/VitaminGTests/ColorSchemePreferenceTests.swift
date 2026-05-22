import XCTest
import SwiftUI
@testable import VitaminG

// MARK: - ColorSchemePreferenceTests
// Covers SET-04: ColorSchemePreference enum behavior (Phase 19, Plan 01).
// Pure unit tests — no ModelContainer needed.

final class ColorSchemePreferenceTests: XCTestCase {

    // MARK: - colorScheme mapping

    func test_system_colorScheme_isNil() {
        XCTAssertNil(ColorSchemePreference.system.colorScheme,
                     ".system should map to nil so the OS controls light/dark")
    }

    func test_light_colorScheme_isLight() {
        XCTAssertEqual(ColorSchemePreference.light.colorScheme, .light,
                       ".light should map to ColorScheme.light")
    }

    func test_dark_colorScheme_isDark() {
        XCTAssertEqual(ColorSchemePreference.dark.colorScheme, .dark,
                       ".dark should map to ColorScheme.dark")
    }

    // MARK: - CaseIterable

    func test_allCases_count_isThree() {
        XCTAssertEqual(ColorSchemePreference.allCases.count, 3,
                       "Enum must have exactly three cases: system, light, dark")
    }

    // MARK: - RawValue round-trip

    func test_rawValue_roundTrip_system() {
        XCTAssertEqual(ColorSchemePreference(rawValue: "system"), .system)
    }

    func test_rawValue_roundTrip_light() {
        XCTAssertEqual(ColorSchemePreference(rawValue: "light"), .light)
    }

    func test_rawValue_roundTrip_dark() {
        XCTAssertEqual(ColorSchemePreference(rawValue: "dark"), .dark)
    }

    // MARK: - displayName

    func test_displayName_system() {
        XCTAssertEqual(ColorSchemePreference.system.displayName, "System")
    }

    func test_displayName_light() {
        XCTAssertEqual(ColorSchemePreference.light.displayName, "Light")
    }

    func test_displayName_dark() {
        XCTAssertEqual(ColorSchemePreference.dark.displayName, "Dark")
    }
}
