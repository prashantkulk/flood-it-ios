import XCTest
@testable import FloodIt

final class BoardShapesTests: XCTestCase {

    // MARK: - P18-T2: Board shape templates

    func testRectangularHasNoVoids() {
        let voids = BoardShapes.rectangular(gridSize: 9)
        XCTAssertTrue(voids.isEmpty)
    }

    func testLShapeRemovesTopRight() {
        let voids = BoardShapes.lShape(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // Top-right corner should be void
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 8)))
        // Top-left corner should NOT be void (that's the L's tall side)
        XCTAssertFalse(voids.contains(CellPosition(row: 0, col: 0)))
        // Bottom-right corner should NOT be void (L's bottom arm)
        XCTAssertFalse(voids.contains(CellPosition(row: 8, col: 8)))
    }

    func testDonutRemovesCenter() {
        let voids = BoardShapes.donut(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // Center cell should be void
        XCTAssertTrue(voids.contains(CellPosition(row: 4, col: 4)))
        // Corner should NOT be void
        XCTAssertFalse(voids.contains(CellPosition(row: 0, col: 0)))
    }

    func testDiamondRemovesCorners() {
        let voids = BoardShapes.diamond(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // All four corners should be void
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 8)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 8)))
        // Center should NOT be void
        XCTAssertFalse(voids.contains(CellPosition(row: 4, col: 4)))
    }

    func testCrossRemovesCornerQuadrants() {
        let voids = BoardShapes.cross(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // All four corners should be void
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 8)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 8)))
        // Center should NOT be void
        XCTAssertFalse(voids.contains(CellPosition(row: 4, col: 4)))
        // Middle of top edge (in vertical arm) should NOT be void
        XCTAssertFalse(voids.contains(CellPosition(row: 0, col: 4)))
    }

    func testHeartRemovesCorners() {
        let voids = BoardShapes.heart(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // Top corners should be void (not part of heart humps)
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 8)))
        // Bottom corners should be void (heart tapers to a point)
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 8)))
    }

    func testShapesProduceUniquePositions() {
        // All shapes should produce positions within bounds and no duplicates
        let shapes: [(String, [CellPosition])] = [
            ("lShape", BoardShapes.lShape(gridSize: 9)),
            ("donut", BoardShapes.donut(gridSize: 9)),
            ("diamond", BoardShapes.diamond(gridSize: 9)),
            ("cross", BoardShapes.cross(gridSize: 9)),
            ("heart", BoardShapes.heart(gridSize: 9)),
        ]
        for (name, voids) in shapes {
            let unique = Set(voids)
            XCTAssertEqual(voids.count, unique.count, "\(name) has duplicate positions")
            for pos in voids {
                XCTAssertTrue(pos.row >= 0 && pos.row < 9, "\(name) position out of bounds: \(pos)")
                XCTAssertTrue(pos.col >= 0 && pos.col < 9, "\(name) position out of bounds: \(pos)")
            }
        }
    }

    func testLShapePreservesTopLeft() {
        // The L-shape must keep (0,0) playable since that's the flood origin
        let voids = Set(BoardShapes.lShape(gridSize: 9))
        XCTAssertFalse(voids.contains(CellPosition(row: 0, col: 0)))
    }

    func testDiamondOnSmallGrid() {
        let voids = BoardShapes.diamond(gridSize: 5)
        let voidSet = Set(voids)
        // Center should be playable
        XCTAssertFalse(voidSet.contains(CellPosition(row: 2, col: 2)))
        // Corners should be void
        XCTAssertTrue(voidSet.contains(CellPosition(row: 0, col: 0)))
    }
}
