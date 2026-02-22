import SpriteKit
import UIKit

class GameScene: SKScene {
    private var cellNodes: [[FloodCellNode]] = []
    private var board: FloodBoard?
    private let gridPadding: CGFloat = 16
    private var gridGap: CGFloat = 1

    func configure(with board: FloodBoard) {
        self.board = board
        if size.width > 0 {
            renderBoard()
        }
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        scaleMode = .resizeFill
        if board != nil {
            renderBoard()
        }
    }

    // MARK: - Board Rendering

    func updateColors(from board: FloodBoard) {
        self.board = board
        let floodKeys = Set(board.floodRegion.map { "\($0.row),\($0.col)" })
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let node = cellNodes[row][col]
                let cell = board.cells[row][col]
                if node.gameColor != cell {
                    node.applyColor(cell)
                }
                node.setFlooded(floodKeys.contains("\(row),\(col)"))
            }
        }
    }

    private func renderBoard() {
        guard let board = board else { return }
        for row in cellNodes { for node in row { node.removeFromParent() } }
        cellNodes.removeAll()

        let n = board.gridSize
        let sceneW = size.width
        let available = sceneW - gridPadding * 2
        let cellSize = (available - CGFloat(n - 1) * gridGap) / CGFloat(n)
        let gridWidth = CGFloat(n) * cellSize + CGFloat(n - 1) * gridGap
        let gridHeight = CGFloat(n) * cellSize + CGFloat(n - 1) * gridGap
        let originX = (sceneW - gridWidth) / 2
        let originY = (size.height - gridHeight) / 2 + 40

        let floodKeys = Set(board.floodRegion.map { "\($0.row),\($0.col)" })
        for row in 0..<n {
            var rowNodes: [FloodCellNode] = []
            for col in 0..<n {
                let color = board.cells[row][col]
                let node = FloodCellNode(color: color, cellSize: cellSize)
                let x = originX + CGFloat(col) * (cellSize + gridGap) + cellSize / 2
                let y = originY + CGFloat(n - 1 - row) * (cellSize + gridGap) + cellSize / 2
                node.position = CGPoint(x: x, y: y)
                node.name = "cell_\(row)_\(col)"
                node.setFlooded(floodKeys.contains("\(row),\(col)"))
                addChild(node)
                rowNodes.append(node)
            }
            cellNodes.append(rowNodes)
        }
    }
}
