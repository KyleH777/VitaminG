import XCTest
@testable import VitaminG

// MARK: - SettingsViewTests
// Plan 19-04: Verifies SettingsView constants are correctly formed.
// T-19-04-01: The mailto URL string must produce a valid URL with scheme "mailto".

final class SettingsViewTests: XCTestCase {

    func test_supportMailtoURLString_isValidMailtoURL() {
        // Reference the static let from SettingsView so tests use the authoritative source
        let urlString = SettingsView.supportMailtoURLString
        let url = URL(string: urlString)
        XCTAssertNotNil(url, "supportMailtoURLString '\(urlString)' must produce a non-nil URL")
        XCTAssertEqual(url?.scheme, "mailto", "URL scheme must be 'mailto'")
    }
}
