//
//  StorkUITestsLaunchTests.swift
//  StorkUITests
//
//  Created by Nick Molargik on 1/17/26.
//

import XCTest

final class StorkUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Capture launch screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchHomeScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for the home view to fully load
        let navigationBar = app.navigationBars["Stork"]
        _ = navigationBar.waitForExistence(timeout: 3)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchDeliveriesScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Deliveries tab
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let deliveriesTab = tabBar.buttons["Deliveries"]
            if deliveriesTab.exists {
                deliveriesTab.tap()
                sleep(1)
            }
        }

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Deliveries Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchCalendarScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Calendar tab
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let calendarTab = tabBar.buttons["Calendar"]
            if calendarTab.exists {
                calendarTab.tap()
                sleep(1)
            }
        }

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Calendar Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchSettingsScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Settings tab
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let settingsTab = tabBar.buttons["Settings"]
            if settingsTab.exists {
                settingsTab.tap()
                sleep(1)
            }
        }

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Settings Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchAddDeliveryScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        // Tap the add button to show delivery entry form
        let addButton = app.buttons["addEntryButton"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            sleep(1)
        }

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Add Delivery Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
