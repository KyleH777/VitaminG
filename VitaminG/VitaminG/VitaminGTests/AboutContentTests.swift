import XCTest
@testable import VitaminG

// MARK: - AboutContentTests
// Plan 19-04: Verifies AboutContent constants are correctly populated.
// D-03: founderBio must be stored verbatim — tests guard against empty/nil bio.

final class AboutContentTests: XCTestCase {

    func test_founderBio_isNonEmpty() {
        let trimmed = AboutContent.founderBio.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(trimmed.isEmpty, "founderBio must not be empty after trimming")
    }

    func test_appVersionString_matchesExpectedPattern() {
        let versionString = AboutContent.appVersionString
        // Expected format: "Version <something> (<something>)"
        let pattern = #"^Version .+ \(.+\)$"#
        let range = versionString.range(of: pattern, options: .regularExpression)
        XCTAssertNotNil(
            range,
            "appVersionString '\(versionString)' does not match expected pattern 'Version X (Y)'"
        )
    }

    func test_appName_equalsVitaminG() {
        XCTAssertEqual(AboutContent.appName, "Vitamin G")
    }
}
