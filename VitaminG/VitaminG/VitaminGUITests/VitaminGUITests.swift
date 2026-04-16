//
//  VitaminGUITests.swift
//  VitaminGUITests
//
//  Created by Kyle Harrington on 4/3/26.
//

import XCTest

final class VitaminGUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesWithGoalsTab() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the Goals tab is visible and selected on launch
        XCTAssertTrue(app.tabBars.buttons["Goals"].exists, "Goals tab should exist")
        XCTAssertTrue(app.navigationBars["My Goals"].exists, "My Goals navigation title should be visible")
    }

    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify all four tabs are accessible
        let tabBar = app.tabBars
        XCTAssertTrue(tabBar.buttons["Goals"].exists)
        XCTAssertTrue(tabBar.buttons["Stats"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)
        XCTAssertTrue(tabBar.buttons["Profile"].exists)
    }
}
