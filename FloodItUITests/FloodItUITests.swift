import XCTest

final class FloodItUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testGameFlowTapPlayAndTapColor() throws {
        // Tap Continue to enter game (linear progression — no level select)
        let continueButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Continue' OR label CONTAINS 'Level'")).firstMatch
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Continue button should exist on home screen")
        continueButton.tap()
        sleep(2) // Wait for level intro splash to fade

        // Verify at least some color buttons exist
        var colorButtonCount = 0
        for i in 0..<5 {
            if app.buttons["colorButton_\(i)"].waitForExistence(timeout: 3) {
                colorButtonCount += 1
            }
        }
        XCTAssertGreaterThanOrEqual(colorButtonCount, 3, "Should have at least 3 color buttons")

        // Tap a color button to make a move
        let colorButton0 = app.buttons["colorButton_0"]
        if colorButton0.exists {
            colorButton0.tap()
            sleep(1)
        }
    }
}
