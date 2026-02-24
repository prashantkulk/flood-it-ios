import Foundation

/// Helper functions that generate void masks for non-rectangular board shapes.
/// Each function returns an array of CellPositions that should be marked as void.
struct BoardShapes {

    /// Rectangular board — no voids.
    static func rectangular(gridSize: Int) -> [CellPosition] {
        return []
    }

    /// L-shape: removes the top-right quadrant.
    static func lShape(gridSize: Int) -> [CellPosition] {
        var voids = [CellPosition]()
        let half = gridSize / 2
        for row in 0..<half {
            for col in (gridSize - half)..<gridSize {
                voids.append(CellPosition(row: row, col: col))
            }
        }
        return voids
    }

    /// Donut: removes center cells to create a hollow ring.
    static func donut(gridSize: Int) -> [CellPosition] {
        var voids = [CellPosition]()
        let inset = gridSize / 3
        for row in inset..<(gridSize - inset) {
            for col in inset..<(gridSize - inset) {
                voids.append(CellPosition(row: row, col: col))
            }
        }
        return voids
    }

    /// Diamond: removes corners to create a diamond shape.
    static func diamond(gridSize: Int) -> [CellPosition] {
        var voids = [CellPosition]()
        let center = gridSize / 2
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let dist = abs(row - center) + abs(col - center)
                if dist > center {
                    voids.append(CellPosition(row: row, col: col))
                }
            }
        }
        return voids
    }

    /// Cross / plus shape: removes the four corner quadrants.
    static func cross(gridSize: Int) -> [CellPosition] {
        var voids = [CellPosition]()
        let arm = gridSize / 3
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let inVerticalArm = col >= arm && col < (gridSize - arm)
                let inHorizontalArm = row >= arm && row < (gridSize - arm)
                if !inVerticalArm && !inHorizontalArm {
                    voids.append(CellPosition(row: row, col: col))
                }
            }
        }
        return voids
    }

    /// Heart shape: rounded top with a pointed bottom.
    static func heart(gridSize: Int) -> [CellPosition] {
        var voids = [CellPosition]()
        let n = gridSize
        let half = n / 2
        for row in 0..<n {
            for col in 0..<n {
                var inside = false
                if row < half {
                    // Top half: two circles
                    let leftCenterCol = n / 4
                    let rightCenterCol = n - 1 - n / 4
                    let centerRow = half / 2
                    let radius = Double(half) * 0.6
                    let dLeft = sqrt(Double((row - centerRow) * (row - centerRow) + (col - leftCenterCol) * (col - leftCenterCol)))
                    let dRight = sqrt(Double((row - centerRow) * (row - centerRow) + (col - rightCenterCol) * (col - rightCenterCol)))
                    inside = dLeft <= radius || dRight <= radius
                } else {
                    // Bottom half: triangle pointing down
                    let progress = Double(row - half) / Double(n - half)
                    let halfWidth = Double(half) * (1.0 - progress)
                    let center = Double(n - 1) / 2.0
                    inside = Double(col) >= center - halfWidth && Double(col) <= center + halfWidth
                }
                if !inside {
                    voids.append(CellPosition(row: row, col: col))
                }
            }
        }
        return voids
    }
}
