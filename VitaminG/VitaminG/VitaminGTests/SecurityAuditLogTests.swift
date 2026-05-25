// VitaminGTests/SecurityAuditLogTests.swift
import XCTest
@testable import VitaminG

final class SecurityAuditLogTests: XCTestCase {

    private let log = SecurityAuditLog.shared

    override func setUp() {
        super.setUp()
        log.clearForTesting()
    }

    override func tearDown() {
        log.clearForTesting()
        super.tearDown()
    }

    func testLog_storesEvent() {
        let event = AuditEvent(eventType: .appLaunch)
        log.log(event)
        let events = log.recentEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].eventType, .appLaunch)
    }

    func testLog_ringBuffer_capsAt500() {
        for _ in 0..<510 {
            log.log(AuditEvent(eventType: .appLaunch))
        }
        let events = log.recentEvents(limit: 600)
        XCTAssertLessThanOrEqual(events.count, 500)
    }

    func testLog_preservesNewestEntries_whenCapped() {
        for i in 0..<504 {
            log.log(AuditEvent(eventType: .appLaunch, metadata: ["i": "\(i)"]))
        }
        log.log(AuditEvent(eventType: .userBlocked, targetUserID: "newest"))
        let events = log.recentEvents(limit: 600)
        XCTAssertEqual(events.last?.eventType, .userBlocked)
        XCTAssertEqual(events.last?.targetUserID, "newest")
    }

    func testLog_jsonRoundTrip() {
        let event = AuditEvent(eventType: .userBlocked, targetUserID: "uid-abc", metadata: ["reason": "spam"])
        log.log(event)
        let events = log.recentEvents()
        XCTAssertEqual(events.first?.targetUserID, "uid-abc")
        XCTAssertEqual(events.first?.metadata["reason"], "spam")
        XCTAssertEqual(events.first?.eventType, .userBlocked)
    }

    func testExport_returnsValidJSON() {
        log.log(AuditEvent(eventType: .appLaunch))
        let json = log.export()
        let data = json.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    func testRecentEvents_limit() {
        for _ in 0..<10 {
            log.log(AuditEvent(eventType: .appLaunch))
        }
        let events = log.recentEvents(limit: 3)
        XCTAssertEqual(events.count, 3)
    }

    func testLog_corruptedDefaults_startsClean() {
        UserDefaults.standard.set("not-json".data(using: .utf8), forKey: log.defaultsKey)
        log.log(AuditEvent(eventType: .appLaunch))
        let events = log.recentEvents()
        XCTAssertEqual(events.count, 1)
    }
}
