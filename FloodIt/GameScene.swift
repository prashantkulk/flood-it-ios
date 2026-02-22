import SpriteKit

class GameScene: SKScene {
    private var cellNodes: [[SKSpriteNode]] = []
    private var board: FloodBoard?
    private let gridPadding: CGFloat = 16

    /// Configure the scene with a board and render the grid.
    func configure(with board: FloodBoard) {
        self.board = board
        renderBoard()
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        scaleMode = .resizeFill

        if board != nil {
            renderBoard()
        }
    }

    /// Updates cell colors to match current board state.
    func updateColors(from board: FloodBoard) {
        self.board = board
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                cellNodes[row][col].color = board.cells[row][col].skColor
            }
        }
    }

    private func renderBoard() {
        guard let board = board else { return }

        // Remove existing cell nodes
        for row in cellNodes {
            for node in row {
                node.removeFromParent()
            }
        }
        cellNodes.removeAll()

        let gridSize = board.gridSize
        let sceneWidth = size.width
        let availableWidth = sceneWidth - (gridPadding * 2)
        let cellSize = availableWidth / CGFloat(gridSize)
        let spacing: CGFloat = 1
        let actualCellSize = cellSize - spacing

        // Center the grid vertically — offset upward to leave room for buttons below
        let gridHeight = CGFloat(gridSize) * cellSize
        let gridOriginY = (size.height - gridHeight) / 2 + 40

        for row in 0..<gridSize {
            var rowNodes: [SKSpriteNode] = []
            for col in 0..<gridSize {
                let color = board.cells[row][col]
                let node = SKSpriteNode(color: color.skColor, size: CGSize(width: actualCellSize, height: actualCellSize))

                // Position: SpriteKit has (0,0) at bottom-left
                // Row 0 = top of grid → highest y
                let x = gridPadding + CGFloat(col) * cellSize + cellSize / 2
                let y = gridOriginY + CGFloat(gridSize - 1 - row) * cellSize + cellSize / 2
                node.position = CGPoint(x: x, y: y)
                node.name = "cell_\(row)_\(col)"

                addChild(node)
                rowNodes.append(node)
            }
            cellNodes.append(rowNodes)
        }
    }
}
