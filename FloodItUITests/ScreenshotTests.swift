import XCTest

final class ScreenshotTests: XCTestCase {
    
    func testTakeAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Screenshot 1: Home screen
        sleep(2)
        let homeAttach = XCTAttachment(screenshot: app.screenshot())
        homeAttach.name = "HomeScreen"
        homeAttach.lifetime = .keepAlways
        add(homeAttach)
        
        // Tap Continue to enter gameplay
        let continueButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Continue' OR label CONTAINS 'Level'")).firstMatch
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Continue button should exist")
        continueButton.tap()
        sleep(3) // Wait for level intro splash
        
        // Screenshot 2: Gameplay
        let gameAttach = XCTAttachment(screenshot: app.screenshot())
        gameAttach.name = "Gameplay"
        gameAttach.lifetime = .keepAlways
        add(gameAttach)
        
        // Play some moves
        for i in 0..<5 {
            let btn = app.buttons["colorButton_\(i)"]
            if btn.exists {
                btn.tap()
                usleep(500000)
            }
        }
        
        sleep(1)
        let midgameAttach = XCTAttachment(screenshot: app.screenshot())
        midgameAttach.name = "Midgame"
        midgameAttach.lifetime = .keepAlways
        add(midgameAttach)
        
        sleep(10)
    }
    
    func testTakeGameplayScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)
        
        // Tap Continue
        let continueButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Continue' OR label CONTAINS 'Level'")).firstMatch
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }
        sleep(3)
        
        // Play moves and screenshot
        for _ in 0..<5 {
            for i in 0..<5 {
                let btn = app.buttons["colorButton_\(i)"]
                if btn.exists {
                    btn.tap()
                    usleep(300000)
                }
            }
        }
        
        sleep(10) // Hold for manual simctl screenshot
    }
}
