import XCTest

final class FloodItUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testGameFlowTapPlayAndTapColor() throws {
        // Tap Play to go to level select
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        playButton.tap()
        sleep(1)

        // Tap first level to enter game
        let firstLevel = app.buttons.matching(NSPredicate(format: "label CONTAINS '1'")).firstMatch
        XCTAssertTrue(firstLevel.waitForExistence(timeout: 5))
        firstLevel.tap()

        // Verify move counter appears
        let moveCounter = app.staticTexts["moveCounter"]
        XCTAssertTrue(moveCounter.waitForExistence(timeout: 5))
        let initialText = moveCounter.label
        XCTAssertTrue(initialText.contains("Moves:"), "Move counter should show 'Moves:'")

        // Verify at least some color buttons exist (level 1 has 3 colors)
        let colorButton0 = app.buttons["colorButton_0"]
        XCTAssertTrue(colorButton0.waitForExistence(timeout: 3))

        // Count available color buttons
        var colorButtonCount = 0
        for i in 0..<5 {
            if app.buttons["colorButton_\(i)"].exists {
                colorButtonCount += 1
            }
        }
        XCTAssertGreaterThanOrEqual(colorButtonCount, 3, "Should have at least 3 color buttons")

        // Extract the initial move count
        let initialMoves = extractMoveCount(from: initialText)

        // Tap a color button — we need to tap one that differs from the current flood color
        // Try each available button until the move counter changes
        var moved = false
        for i in 0..<colorButtonCount {
            let button = app.buttons["colorButton_\(i)"]
            if button.exists {
                button.tap()

                // Small wait for UI update
                let updatedText = moveCounter.label
                let updatedMoves = extractMoveCount(from: updatedText)
                if let initial = initialMoves, let updated = updatedMoves, updated < initial {
                    moved = true
                    break
                }
            }
        }

        XCTAssertTrue(moved, "Move counter should decrement after tapping a different color")
    }

    private func extractMoveCount(from text: String) -> Int? {
        // "Moves: 30" → 30
        let parts = text.components(separatedBy: ": ")
        guard parts.count == 2, let count = Int(parts[1]) else { return nil }
        return count
    }
}
