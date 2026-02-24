import XCTest

final class LevelPlaythroughTests: XCTestCase {
    
    func testPlaythroughLevels() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Screenshot 1: Home screen
        sleep(2)
        let homeAttach = XCTAttachment(screenshot: app.screenshot())
        homeAttach.name = "01-home"
        homeAttach.lifetime = .keepAlways
        add(homeAttach)
        
        // Tap Continue to enter game
        let continueButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Continue' OR label CONTAINS 'Level'")).firstMatch
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }
        sleep(3) // Wait for level intro splash
        
        // Screenshot 2: Gameplay
        let gameAttach = XCTAttachment(screenshot: app.screenshot())
        gameAttach.name = "02-gameplay"
        gameAttach.lifetime = .keepAlways
        add(gameAttach)
        
        // Play: tap color buttons
        for _ in 0..<15 {
            for i in 0..<5 {
                let btn = app.buttons["colorButton_\(i)"]
                if btn.exists {
                    btn.tap()
                    usleep(300000)
                }
            }
        }
        
        sleep(2)
        // Screenshot 3: After playing
        let endAttach = XCTAttachment(screenshot: app.screenshot())
        endAttach.name = "03-end"
        endAttach.lifetime = .keepAlways
        add(endAttach)
        
        // Long pause for manual screenshots
        sleep(10)
    }
}
