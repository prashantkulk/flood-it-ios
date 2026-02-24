import Foundation

/// Helper functions that generate void masks for non-rectangular board shapes.
/// Each function returns an array of CellPositions that should be marked as void.
/// All shapes preserve (0,0) and ensure connectivity from origin to the main shape.
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
        return ensureConnectivity(voids, gridSize: gridSize)
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
        return ensureConnectivity(voids, gridSize: gridSize)
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
        return ensureConnectivity(voids, gridSize: gridSize)
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
        return ensureConnectivity(voids, gridSize: gridSize)
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
        return ensureConnectivity(voids, gridSize: gridSize)
    }

    /// Ensures origin (0,0) is not void and is connected to the main shape body.
    /// Clears a corridor along row 0 if needed to bridge the origin to the shape.
    private static func ensureConnectivity(_ voids: [CellPosition], gridSize: Int) -> [CellPosition] {
        var voidSet = Set(voids)

        // Always protect origin
        voidSet.remove(CellPosition(row: 0, col: 0))

        // Check if origin can reach all non-void cells
        let totalNonVoid = gridSize * gridSize - voidSet.count
        var reachable = floodReachableCount(from: CellPosition(row: 0, col: 0), voidSet: voidSet, gridSize: gridSize)

        if reachable < totalNonVoid {
            // Clear a corridor along row 0 until connected
            for col in 1..<gridSize {
                voidSet.remove(CellPosition(row: 0, col: col))
                let newTotal = gridSize * gridSize - voidSet.count
                reachable = floodReachableCount(from: CellPosition(row: 0, col: 0), voidSet: voidSet, gridSize: gridSize)
                if reachable >= newTotal { break }
            }
        }

        // Final safety: also try col 0 if still disconnected
        let finalTotal = gridSize * gridSize - voidSet.count
        reachable = floodReachableCount(from: CellPosition(row: 0, col: 0), voidSet: voidSet, gridSize: gridSize)
        if reachable < finalTotal {
            for row in 1..<gridSize {
                voidSet.remove(CellPosition(row: row, col: 0))
            }
        }

        return voids.filter { voidSet.contains($0) }
    }

    /// Counts how many non-void cells are reachable from a start position via 4-directional BFS.
    private static func floodReachableCount(from start: CellPosition, voidSet: Set<CellPosition>, gridSize: Int) -> Int {
        guard !voidSet.contains(start) else { return 0 }
        var visited = Set<CellPosition>([start])
        var queue = [start]
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
        return visited.count
    }
}
