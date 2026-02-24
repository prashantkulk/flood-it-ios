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

    // MARK: - P21-T1: Final App Store Screenshots

    func testTakeAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        // Screenshot 1: Home screen with streak flame
        saveScreenshot(name: "01_HomeScreen")

        // Navigate to level select
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        playButton.tap()
        sleep(2)

        // Screenshot 2: Level select with stars and pack progression
        saveScreenshot(name: "02_LevelSelect")

        // Start a level with obstacles (level 25+ has stones)
        let level = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch
        if level.waitForExistence(timeout: 3) {
            level.tap()
            sleep(2)
        }

        // Screenshot 3: Gameplay with obstacles visible
        saveScreenshot(name: "03_Gameplay")

        // Make several moves to try to trigger combos and cascades
        for _ in 0..<5 {
            for i in 0..<5 {
                let button = app.buttons["colorButton_\(i)"]
                if button.waitForExistence(timeout: 1) && button.isHittable {
                    button.tap()
                    usleep(400_000) // 0.4s for animation
                }
            }
        }

        // Screenshot 4: Mid-game cascade/combo moment
        saveScreenshot(name: "04_Cascade")

        // Keep playing to try to win the level
        for _ in 0..<20 {
            for i in 0..<5 {
                let button = app.buttons["colorButton_\(i)"]
                if button.exists && button.isHittable {
                    button.tap()
                    usleep(200_000)
                }
            }
        }
        sleep(2)

        // Screenshot 5: Win/end screen (confetti and score card if won)
        saveScreenshot(name: "05_EndGame")

        // Go back to home for daily challenge
        let doneButton = app.buttons["doneButton"]
        let nextButton = app.buttons["nextButton"]
        let quitButton = app.buttons["quitButton"]
        let backButton = app.buttons["backButton"]

        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
        } else if nextButton.waitForExistence(timeout: 2) {
            nextButton.tap()
        } else if quitButton.waitForExistence(timeout: 2) {
            quitButton.tap()
        } else if backButton.waitForExistence(timeout: 2) {
            backButton.tap()
        }
        sleep(1)

        // Navigate back to home
        let navBack = app.navigationBars.buttons.firstMatch
        if navBack.waitForExistence(timeout: 2) {
            navBack.tap()
            sleep(1)
        }

        // Tap Daily Challenge
        let dailyButton = app.buttons["Daily Challenge"]
        if dailyButton.waitForExistence(timeout: 3) {
            dailyButton.tap()
            sleep(2)

            // Screenshot 6: Daily challenge screen
            saveScreenshot(name: "06_DailyChallenge")
        }
    }

    // MARK: - Helpers

    private func saveScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let data = screenshot.pngRepresentation
        let path = "\(screenshotDir)/\(name).png"
        try? data.write(to: URL(fileURLWithPath: path))
    }
}
