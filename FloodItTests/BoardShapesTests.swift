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
        // Top-left corner should NOT be void (origin protected)
        XCTAssertFalse(voids.contains(CellPosition(row: 0, col: 0)))
        // Bottom-right corner should NOT be void (L's bottom arm)
        XCTAssertFalse(voids.contains(CellPosition(row: 8, col: 8)))
    }

    func testDonutRemovesCenter() {
        let voids = BoardShapes.donut(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // Center cell should be void
        XCTAssertTrue(voids.contains(CellPosition(row: 4, col: 4)))
        // Origin should NOT be void
        XCTAssertFalse(voids.contains(CellPosition(row: 0, col: 0)))
    }

    func testDiamondRemovesFarCorners() {
        let voids = BoardShapes.diamond(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // Far corners should be void (not origin-adjacent)
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 8)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 8)))
        // Center should NOT be void
        XCTAssertFalse(voids.contains(CellPosition(row: 4, col: 4)))
    }

    func testCrossRemovesFarCornerQuadrants() {
        let voids = BoardShapes.cross(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // Far corners should be void
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 8)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 8)))
        // Center should NOT be void
        XCTAssertFalse(voids.contains(CellPosition(row: 4, col: 4)))
        // Middle of top edge (in vertical arm) should NOT be void
        XCTAssertFalse(voids.contains(CellPosition(row: 0, col: 4)))
    }

    func testHeartRemovesFarCorners() {
        let voids = BoardShapes.heart(gridSize: 9)
        XCTAssertFalse(voids.isEmpty)
        // Far corners should be void
        XCTAssertTrue(voids.contains(CellPosition(row: 0, col: 8)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 0)))
        XCTAssertTrue(voids.contains(CellPosition(row: 8, col: 8)))
    }

    func testAllShapesPreserveOrigin() {
        let shapes: [(String, [CellPosition])] = [
            ("lShape", BoardShapes.lShape(gridSize: 9)),
            ("donut", BoardShapes.donut(gridSize: 9)),
            ("diamond", BoardShapes.diamond(gridSize: 9)),
            ("cross", BoardShapes.cross(gridSize: 9)),
            ("heart", BoardShapes.heart(gridSize: 9)),
        ]
        for (name, voids) in shapes {
            let voidSet = Set(voids)
            // Origin must always be preserved
            XCTAssertFalse(voidSet.contains(CellPosition(row: 0, col: 0)), "\(name) should preserve (0,0)")
            // All non-void cells must be connected (reachable from origin)
            let gridSize = 9
            let totalNonVoid = gridSize * gridSize - voidSet.count
            var visited = Set<CellPosition>([CellPosition(row: 0, col: 0)])
            var queue = [CellPosition(row: 0, col: 0)]
            while !queue.isEmpty {
                let current = queue.removeFirst()
                for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                    let next = CellPosition(row: current.row + dr, col: current.col + dc)
                    guard next.row >= 0, next.row < gridSize, next.col >= 0, next.col < gridSize else { continue }
                    guard !voidSet.contains(next), !visited.contains(next) else { continue }
                    visited.insert(next)
                    queue.append(next)
                }
            }
            XCTAssertEqual(visited.count, totalNonVoid, "\(name) should have all non-void cells connected to origin")
        }
    }

    func testShapesProduceUniquePositions() {
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

    func testDiamondOnSmallGrid() {
        let voids = BoardShapes.diamond(gridSize: 5)
        let voidSet = Set(voids)
        // Center should be playable
        XCTAssertFalse(voidSet.contains(CellPosition(row: 2, col: 2)))
        // Far corners should be void
        XCTAssertTrue(voidSet.contains(CellPosition(row: 0, col: 4)))
        XCTAssertTrue(voidSet.contains(CellPosition(row: 4, col: 4)))
    }
}
