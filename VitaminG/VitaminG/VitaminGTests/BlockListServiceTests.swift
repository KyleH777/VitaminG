// VitaminGTests/BlockListServiceTests.swift
import XCTest
@testable import VitaminG

final class BlockListServiceTests: XCTestCase {

    private let key = "vg_blockedUserIDs"

    override func setUp() {
        super.setUp()
        // Start each test with a clean slate
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    // MARK: - Tests

    func testBlockUser_persistsID() {
        BlockListService.blockUser(appleUserID: "apple-uid-123")
        XCTAssertTrue(BlockListService.isBlocked(appleUserID: "apple-uid-123"))
    }

    func testBlockUser_multipleUsers() {
        BlockListService.blockUser(appleUserID: "apple-uid-alpha")
        BlockListService.blockUser(appleUserID: "apple-uid-beta")
        XCTAssertTrue(BlockListService.isBlocked(appleUserID: "apple-uid-alpha"))
        XCTAssertTrue(BlockListService.isBlocked(appleUserID: "apple-uid-beta"))
        XCTAssertEqual(BlockListService.allBlocked().count, 2)
    }

    func testUnblockUser_removesID() {
        BlockListService.blockUser(appleUserID: "uid-to-remove")
        BlockListService.unblockUser(appleUserID: "uid-to-remove")
        XCTAssertFalse(BlockListService.isBlocked(appleUserID: "uid-to-remove"))
    }

    func testIsBlocked_returnsFalseForUnknown() {
        XCTAssertFalse(BlockListService.isBlocked(appleUserID: "nobody"))
    }

    func testBlockList_survivesReadRoundTrip() {
        BlockListService.blockUser(appleUserID: "uid-a")
        BlockListService.blockUser(appleUserID: "uid-b")
        let reloaded = BlockListService.blockedUserIDs()
        XCTAssertTrue(reloaded.contains("uid-a"))
        XCTAssertTrue(reloaded.contains("uid-b"))
    }
}
