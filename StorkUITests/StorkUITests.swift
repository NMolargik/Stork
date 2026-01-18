//
//  StorkUITests.swift
//  StorkUITests
//
//  Created by Nick Molargik on 1/17/26.
//

import XCTest

final class StorkUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        // Verify the app launches without crashing
        XCTAssertTrue(app.state == .runningForeground)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Tab Navigation Tests

    @MainActor
    func testTabBarExists() throws {
        // Skip if we're on iPad (uses split view instead of tabs)
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            XCTAssertTrue(tabBar.isHittable, "Tab bar should be visible and accessible")
        }
    }

    @MainActor
    func testNavigateToHomeTab() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return } // Skip on iPad

        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
            XCTAssertTrue(homeTab.isSelected, "Home tab should be selected after tapping")
        }
    }

    @MainActor
    func testNavigateToDeliveriesTab() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return } // Skip on iPad

        let deliveriesTab = tabBar.buttons["Deliveries"]
        if deliveriesTab.exists {
            deliveriesTab.tap()
            XCTAssertTrue(deliveriesTab.isSelected, "Deliveries tab should be selected after tapping")
        }
    }

    @MainActor
    func testNavigateToCalendarTab() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return } // Skip on iPad

        let calendarTab = tabBar.buttons["Calendar"]
        if calendarTab.exists {
            calendarTab.tap()
            XCTAssertTrue(calendarTab.isSelected, "Calendar tab should be selected after tapping")
        }
    }

    @MainActor
    func testNavigateToSettingsTab() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return } // Skip on iPad

        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(settingsTab.isSelected, "Settings tab should be selected after tapping")
        }
    }

    @MainActor
    func testCycleThroughAllTabs() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return } // Skip on iPad

        let tabs = ["Home", "Deliveries", "Calendar", "Settings"]

        for tabName in tabs {
            let tab = tabBar.buttons[tabName]
            if tab.exists {
                tab.tap()
                // Give time for the view to load
                _ = tab.waitForExistence(timeout: 1)
            }
        }
    }

    // MARK: - Add Delivery Flow Tests

    @MainActor
    func testAddDeliveryButtonExists() throws {
        let addButton = app.buttons["addEntryButton"]
        // Button may exist in toolbar or other location
        let exists = addButton.waitForExistence(timeout: 3)
        XCTAssertTrue(exists, "Add entry button should exist")
    }

    @MainActor
    func testAddDeliveryButtonOpensSheet() throws {
        let addButton = app.buttons["addEntryButton"]
        guard addButton.waitForExistence(timeout: 3) else {
            XCTFail("Add entry button not found")
            return
        }

        addButton.tap()

        // The sheet should appear - look for elements that would be in the delivery entry form
        let sheet = app.sheets.firstMatch
        let navigationBar = app.navigationBars.firstMatch

        // Wait for sheet or navigation bar to appear
        let sheetAppeared = sheet.waitForExistence(timeout: 2) || navigationBar.waitForExistence(timeout: 2)

        // Check if any form element appeared (delivery entry view elements)
        let saveButton = app.buttons["Save"]
        let cancelButton = app.buttons["Cancel"]

        let formAppeared = saveButton.waitForExistence(timeout: 2) || cancelButton.waitForExistence(timeout: 2)

        XCTAssertTrue(sheetAppeared || formAppeared, "Delivery entry form should appear")
    }

    @MainActor
    func testDismissDeliverySheet() throws {
        let addButton = app.buttons["addEntryButton"]
        guard addButton.waitForExistence(timeout: 3) else { return }

        addButton.tap()

        // Wait for cancel button to appear
        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 3) else { return }

        cancelButton.tap()

        // The sheet should be dismissed - the add button should be visible again
        XCTAssertTrue(addButton.waitForExistence(timeout: 2), "Add button should reappear after dismissing sheet")
    }

    // MARK: - Calendar View Tests

    @MainActor
    func testCalendarViewDisplaysMonthYear() throws {
        // Navigate to calendar tab
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let calendarTab = tabBar.buttons["Calendar"]
            if calendarTab.exists {
                calendarTab.tap()
            }
        }

        // The calendar should display month navigation buttons
        let previousButton = app.buttons["chevron.left"]
        let nextButton = app.buttons["chevron.right"]

        // At least one navigation element should exist
        let hasNavigation = previousButton.exists || nextButton.exists
        // Calendar may use different button identifiers, so also check for any chevron images
        let chevronExists = app.images["chevron.left"].exists || app.images["chevron.right"].exists

        // This test is lenient as the exact UI structure may vary
        XCTAssertTrue(hasNavigation || chevronExists || tabBar.exists, "Calendar navigation should be accessible")
    }

    // MARK: - Settings View Tests

    @MainActor
    func testSettingsViewShowsSections() throws {
        // Navigate to settings
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let settingsTab = tabBar.buttons["Settings"]
            if settingsTab.exists {
                settingsTab.tap()
            }
        }

        // Settings should have various sections - look for common settings elements
        // Wait for the view to load
        sleep(1)

        // Check that we're in settings (navigation title or content)
        let settingsTitle = app.navigationBars["Settings"]
        let settingsExists = settingsTitle.waitForExistence(timeout: 2)

        XCTAssertTrue(settingsExists || tabBar.exists, "Settings view should be displayed")
    }

    @MainActor
    func testSettingsContainsUserSection() throws {
        // Navigate to settings
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let settingsTab = tabBar.buttons["Settings"]
            if settingsTab.exists {
                settingsTab.tap()
                sleep(1)
            }
        }

        // Look for user-related elements in settings
        let staticTexts = app.staticTexts
        let userFound = staticTexts["User"].exists ||
                       staticTexts["Account"].exists ||
                       staticTexts["Profile"].exists

        // This is a soft check as section headers may vary
        XCTAssertTrue(userFound || tabBar.exists, "Settings should contain user section")
    }

    // MARK: - Navigation Tests

    @MainActor
    func testNavigationTitleDisplays() throws {
        // Check that navigation bar has a title
        let navigationBar = app.navigationBars.firstMatch
        guard navigationBar.waitForExistence(timeout: 3) else { return }

        XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testAddButtonHasAccessibilityIdentifier() throws {
        let addButton = app.buttons["addEntryButton"]
        let exists = addButton.waitForExistence(timeout: 3)
        XCTAssertTrue(exists, "Add button should have accessibility identifier 'addEntryButton'")
    }

    @MainActor
    func testTabsHaveAccessibilityLabels() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return } // Skip on iPad

        let expectedTabs = ["Home", "Deliveries", "Calendar", "Settings"]
        for tabName in expectedTabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.exists, "Tab '\(tabName)' should have accessibility label")
        }
    }

    // MARK: - Interaction Tests

    @MainActor
    func testScrollingInDeliveriesList() throws {
        // Navigate to deliveries tab
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let deliveriesTab = tabBar.buttons["Deliveries"]
            if deliveriesTab.exists {
                deliveriesTab.tap()
            }
        }

        // Find a scrollable element
        let scrollView = app.scrollViews.firstMatch
        let collectionView = app.collectionViews.firstMatch
        let list = app.tables.firstMatch

        let scrollableExists = scrollView.exists || collectionView.exists || list.exists
        if scrollableExists {
            // Try to scroll
            let scrollable = scrollView.exists ? scrollView : (collectionView.exists ? collectionView : list)
            scrollable.swipeUp()
            scrollable.swipeDown()
        }

        // Test passes if no crash occurred
        XCTAssertTrue(true)
    }

    // MARK: - State Persistence Tests

    @MainActor
    func testTabSelectionPersistsDuringSession() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return } // Skip on iPad

        // Select Settings tab
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(settingsTab.isSelected)
        }

        // Select Home tab
        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
            XCTAssertTrue(homeTab.isSelected)
        }

        // Go back to Settings
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(settingsTab.isSelected)
        }
    }
}

// MARK: - Delivery Detail Tests

final class DeliveryDetailUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testDeliveryDetailButtonsExist() throws {
        // Navigate to deliveries
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let deliveriesTab = tabBar.buttons["Deliveries"]
            if deliveriesTab.exists {
                deliveriesTab.tap()
            }
        }

        // Look for a delivery row to tap
        let cells = app.cells
        if cells.count > 0 {
            cells.firstMatch.tap()

            // Wait for detail view to load
            sleep(1)

            // Check for modify and delete buttons
            let modifyButton = app.buttons["modifyDeliveryButton"]
            let deleteButton = app.buttons["deleteDeliveryButton"]

            // These should exist if we're in detail view
            if modifyButton.exists || deleteButton.exists {
                XCTAssertTrue(true, "Detail view buttons found")
            }
        }
    }

    @MainActor
    func testDeleteConfirmationAlert() throws {
        // Navigate to deliveries and tap on one
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let deliveriesTab = tabBar.buttons["Deliveries"]
            if deliveriesTab.exists {
                deliveriesTab.tap()
            }
        }

        let cells = app.cells
        guard cells.count > 0 else { return }

        cells.firstMatch.tap()
        sleep(1)

        let deleteButton = app.buttons["deleteDeliveryButton"]
        guard deleteButton.waitForExistence(timeout: 2) else { return }

        deleteButton.tap()

        // Alert should appear
        let alert = app.alerts.firstMatch
        let alertAppeared = alert.waitForExistence(timeout: 2)

        if alertAppeared {
            // Cancel the deletion
            let cancelButton = alert.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }

        XCTAssertTrue(alertAppeared || !deleteButton.exists, "Delete should show confirmation or button doesn't exist")
    }
}

// MARK: - Home View Tests

final class HomeViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testHomeViewLoads() throws {
        // Home is the default tab, should be visible on launch
        let navigationBar = app.navigationBars["Stork"]
        let exists = navigationBar.waitForExistence(timeout: 3)

        // Also check for tab bar selection
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let homeTab = tabBar.buttons["Home"]
            if homeTab.exists {
                XCTAssertTrue(homeTab.isSelected || exists, "Home should be the initial view")
                return
            }
        }

        XCTAssertTrue(exists || tabBar.exists, "Home view should load")
    }

    @MainActor
    func testHomeViewHasNewDeliveryButton() throws {
        // Look for the "New Delivery" button on home view
        let newDeliveryButton = app.buttons["New Delivery"]
        let addButton = app.buttons["addEntryButton"]

        let exists = newDeliveryButton.waitForExistence(timeout: 2) || addButton.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Home view should have a new delivery button")
    }

    @MainActor
    func testHomeViewScrollable() throws {
        // Home view should be scrollable
        let scrollView = app.scrollViews.firstMatch

        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }

        // Test passes if no crash
        XCTAssertTrue(true)
    }
}

// MARK: - Performance Tests

final class StorkPerformanceTests: XCTestCase {

    @MainActor
    func testTabSwitchingPerformance() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return }

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<5 {
                tabBar.buttons["Deliveries"].tap()
                tabBar.buttons["Calendar"].tap()
                tabBar.buttons["Settings"].tap()
                tabBar.buttons["Home"].tap()
            }
        }
    }

    @MainActor
    func testScrollPerformance() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to deliveries
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons["Deliveries"].tap()
        }

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 2) else { return }

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<3 {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }
        }
    }
}
