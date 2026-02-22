import XCTest

final class FloodItUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testGameFlowTapPlayAndTapColor() throws {
        // Tap Play to go to game screen
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        playButton.tap()

        // Verify move counter appears
        let moveCounter = app.staticTexts["moveCounter"]
        XCTAssertTrue(moveCounter.waitForExistence(timeout: 5))
        let initialText = moveCounter.label
        XCTAssertTrue(initialText.contains("Moves:"), "Move counter should show 'Moves:'")

        // Verify color buttons exist
        let colorButton0 = app.buttons["colorButton_0"]
        XCTAssertTrue(colorButton0.waitForExistence(timeout: 3))
        let colorButton1 = app.buttons["colorButton_1"]
        XCTAssertTrue(colorButton1.exists)
        let colorButton2 = app.buttons["colorButton_2"]
        XCTAssertTrue(colorButton2.exists)
        let colorButton3 = app.buttons["colorButton_3"]
        XCTAssertTrue(colorButton3.exists)
        let colorButton4 = app.buttons["colorButton_4"]
        XCTAssertTrue(colorButton4.exists)

        // Extract the initial move count
        let initialMoves = extractMoveCount(from: initialText)

        // Tap a color button — we need to tap one that differs from the current flood color
        // Try each button until the move counter changes
        var moved = false
        for i in 0..<5 {
            let button = app.buttons["colorButton_\(i)"]
            button.tap()

            // Small wait for UI update
            let updatedText = moveCounter.label
            let updatedMoves = extractMoveCount(from: updatedText)
            if let initial = initialMoves, let updated = updatedMoves, updated < initial {
                moved = true
                break
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
