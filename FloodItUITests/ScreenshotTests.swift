import XCTest

class ScreenshotTests: XCTestCase {
    func testTakeGameplayScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(1)
        
        // Tap Play
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        playButton.tap()
        sleep(1)
        
        // Now take a screenshot while on the game board
        // The test will pause here for 10 seconds - enough time to grab simctl screenshot
        sleep(10)
    }
}
