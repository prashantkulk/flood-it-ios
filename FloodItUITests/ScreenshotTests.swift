import XCTest

class ScreenshotTests: XCTestCase {

    let screenshotDir = "/Users/prashant/Projects/FloodIt/Screenshots"

    override func setUpWithError() throws {
        continueAfterFailure = true
        try FileManager.default.createDirectory(
            atPath: screenshotDir,
            withIntermediateDirectories: true
        )
    }

    func testTakeGameplayScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        // Screenshot 1: Home screen
        saveScreenshot(name: "01_HomeScreen")

        // Tap Play to go to level select
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        playButton.tap()
        sleep(2)

        // Screenshot 4: Level select with stars
        saveScreenshot(name: "04_LevelSelect")

        // Tap first level to start game
        let firstLevel = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch
        if firstLevel.waitForExistence(timeout: 3) {
            firstLevel.tap()
            sleep(2)
        }

        // Make a few moves for a mid-game board
        for i in 0..<3 {
            let button = app.buttons["colorButton_\(i)"]
            if button.waitForExistence(timeout: 2) {
                button.tap()
                sleep(1)
            }
        }

        // Screenshot 2: Gameplay mid-game
        saveScreenshot(name: "02_Gameplay")

        // Screenshot 3: Try to get a win - keep tapping colors
        for _ in 0..<30 {
            for i in 0..<5 {
                let button = app.buttons["colorButton_\(i)"]
                if button.exists {
                    button.tap()
                    usleep(200_000) // 0.2s
                }
            }
        }
        sleep(2)
        saveScreenshot(name: "03_EndGame")
    }

    private func saveScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also save to disk
        let data = screenshot.pngRepresentation
        let path = "\(screenshotDir)/\(name).png"
        try? data.write(to: URL(fileURLWithPath: path))
    }
}
