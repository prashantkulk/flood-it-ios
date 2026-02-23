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
        
        // Tap Play
        let playButton = app.buttons["playButton"]
        if playButton.waitForExistence(timeout: 5) {
            playButton.tap()
        } else {
            // Try tapping by label
            app.buttons["Play"].tap()
        }
        sleep(2)
        
        // Screenshot 2: Level select
        let levelSelectAttach = XCTAttachment(screenshot: app.screenshot())
        levelSelectAttach.name = "02-levelselect"
        levelSelectAttach.lifetime = .keepAlways
        add(levelSelectAttach)
        
        // Tap Level 1
        let level1 = app.buttons["level_1"]
        if level1.waitForExistence(timeout: 5) {
            level1.tap()
        } else {
            // Try static texts
            let l1text = app.staticTexts["1"]
            if l1text.waitForExistence(timeout: 3) {
                l1text.tap()
            }
        }
        sleep(2)
        
        // Screenshot 3: Level 1 (3x3 board - onboarding)
        let level1Attach = XCTAttachment(screenshot: app.screenshot())
        level1Attach.name = "03-level1-start"
        level1Attach.lifetime = .keepAlways
        add(level1Attach)
        
        // Play level 1: tap through colors to try to win
        // Just tap each color button a couple times
        let colorNames = ["coral", "amber", "emerald", "sapphire", "violet"]
        for name in colorNames {
            let btn = app.buttons["colorButton_\(name)"]
            if btn.exists {
                btn.tap()
                usleep(500000) // 0.5s
            }
        }
        
        sleep(1)
        // Screenshot 4: Level 1 mid-game
        let mid1Attach = XCTAttachment(screenshot: app.screenshot())
        mid1Attach.name = "04-level1-midgame"
        mid1Attach.lifetime = .keepAlways
        add(mid1Attach)
        
        // Keep tapping colors to try to complete
        for _ in 0..<10 {
            for name in colorNames {
                let btn = app.buttons["colorButton_\(name)"]
                if btn.exists {
                    btn.tap()
                    usleep(300000)
                }
            }
        }
        
        sleep(2)
        // Screenshot 5: After playing (win or lose screen)
        let endAttach = XCTAttachment(screenshot: app.screenshot())
        endAttach.name = "05-level1-end"
        endAttach.lifetime = .keepAlways
        add(endAttach)
        
        // Long pause for manual screenshot capture
        sleep(15)
    }
}
