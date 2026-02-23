import XCTest
@testable import FloodIt

final class DailyChallengeTests: XCTestCase {

    // MARK: - P11-T1: Date-seeded daily challenge

    func testSameDateSameBoard() {
        let date = makeDate(year: 2026, month: 3, day: 15)
        let board1 = DailyChallenge.generateBoard(for: date)
        let board2 = DailyChallenge.generateBoard(for: date)
        XCTAssertEqual(board1.cells, board2.cells)
    }

    func testDifferentDateDifferentBoard() {
        let date1 = makeDate(year: 2026, month: 3, day: 15)
        let date2 = makeDate(year: 2026, month: 3, day: 16)
        let board1 = DailyChallenge.generateBoard(for: date1)
        let board2 = DailyChallenge.generateBoard(for: date2)
        XCTAssertNotEqual(board1.cells, board2.cells)
    }

    func testBoardIs9x9() {
        let board = DailyChallenge.generateBoard(for: Date())
        XCTAssertEqual(board.gridSize, 9)
    }

    func testBoardUses5Colors() {
        let date = makeDate(year: 2026, month: 6, day: 1)
        let board = DailyChallenge.generateBoard(for: date)
        let colors = Set(board.cells.flatMap { $0 })
        XCTAssertEqual(colors.count, 5)
    }

    func testChallengeNumberFromEpoch() {
        let epoch = makeDate(year: 2026, month: 1, day: 1)
        XCTAssertEqual(DailyChallenge.challengeNumber(for: epoch), 0)

        let dayOne = makeDate(year: 2026, month: 1, day: 2)
        XCTAssertEqual(DailyChallenge.challengeNumber(for: dayOne), 1)

        let dayTen = makeDate(year: 2026, month: 1, day: 11)
        XCTAssertEqual(DailyChallenge.challengeNumber(for: dayTen), 10)
    }

    func testSeedIsDeterministic() {
        let date = makeDate(year: 2026, month: 5, day: 20)
        let seed1 = DailyChallenge.seed(for: date)
        let seed2 = DailyChallenge.seed(for: date)
        XCTAssertEqual(seed1, seed2)
    }

    func testDifferentDatesDifferentSeeds() {
        let date1 = makeDate(year: 2026, month: 5, day: 20)
        let date2 = makeDate(year: 2026, month: 5, day: 21)
        XCTAssertNotEqual(DailyChallenge.seed(for: date1), DailyChallenge.seed(for: date2))
    }

    // MARK: - P11-T3: Daily result persistence

    func testSaveDailyResultAndRetrieve() {
        let store = ProgressStore()
        let result = DailyResult(
            dateString: "2026-99-99",
            movesUsed: 14,
            moveBudget: 22,
            starsEarned: 3,
            colorsUsed: [0, 1, 2, 3, 4]
        )
        store.saveDailyResult(result)

        let retrieved = store.dailyResult(for: "2026-99-99")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.movesUsed, 14)
        XCTAssertEqual(retrieved?.moveBudget, 22)
        XCTAssertEqual(retrieved?.starsEarned, 3)
        XCTAssertEqual(retrieved?.colorsUsed, [0, 1, 2, 3, 4])

        // Clean up
        UserDefaults.standard.removeObject(forKey: "progress_dailyResults")
    }

    func testDailyResultNilIfNotCompleted() {
        let store = ProgressStore()
        XCTAssertNil(store.dailyResult(for: "2099-12-31"))
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
