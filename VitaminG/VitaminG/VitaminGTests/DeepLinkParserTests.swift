import XCTest
@testable import VitaminG

final class DeepLinkParserTests: XCTestCase {

    // MARK: - Valid URL

    func test_recordID_validProfileURL_returnsRecordID() {
        let url = URL(string: "vitaming://profile/abc123")!
        let result = DeepLinkParser.recordID(from: url)
        XCTAssertEqual(result, "abc123")
    }

    // MARK: - Wrong Scheme

    func test_recordID_wrongScheme_returnsNil() {
        let url = URL(string: "https://profile/abc123")!
        let result = DeepLinkParser.recordID(from: url)
        XCTAssertNil(result)
    }

    // MARK: - Wrong Host

    func test_recordID_wrongHost_returnsNil() {
        let url = URL(string: "vitaming://settings/abc123")!
        let result = DeepLinkParser.recordID(from: url)
        XCTAssertNil(result)
    }

    // MARK: - Missing RecordID

    func test_recordID_missingRecordID_returnsNil() {
        let url = URL(string: "vitaming://profile")!
        let result = DeepLinkParser.recordID(from: url)
        XCTAssertNil(result)
    }

    // MARK: - Empty RecordID (trailing slash)

    func test_recordID_emptyRecordID_returnsNil() {
        let url = URL(string: "vitaming://profile/")!
        let result = DeepLinkParser.recordID(from: url)
        XCTAssertNil(result)
    }

    // MARK: - Percent-Encoded RecordID

    func test_recordID_recordIDWithSpecialChars_returnsRecordID() {
        // Percent-encoded space (%20) in recordID — URL parser decodes it automatically
        let url = URL(string: "vitaming://profile/record%20ID%2042")!
        let result = DeepLinkParser.recordID(from: url)
        XCTAssertEqual(result, "record ID 42")
    }
}
