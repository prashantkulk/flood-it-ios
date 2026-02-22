import SpriteKit
import UIKit

class GameScene: SKScene {
    private var cellNodes: [[FloodCellNode]] = []
    private var board: FloodBoard?
    private let gridPadding: CGFloat = 16
    private var gridGap: CGFloat = 4

    // Dynamic background layers
    private var bgCurrent: SKSpriteNode?
    private var bgNext: SKSpriteNode?

    func configure(with board: FloodBoard) {
        self.board = board
        if size.width > 0 {
            renderBoard()
        }
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        scaleMode = .resizeFill
        setupDynamicBackground()
        if board != nil {
            renderBoard()
        }
    }

    // MARK: - Dynamic Background

    private func setupDynamicBackground() {
        let bgA = SKSpriteNode(color: SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1), size: size)
        bgA.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bgA.zPosition = -10
        addChild(bgA)
        bgCurrent = bgA

        let bgB = SKSpriteNode(color: .clear, size: size)
        bgB.position = bgA.position
        bgB.zPosition = -9
        bgB.alpha = 0
        addChild(bgB)
        bgNext = bgB
    }

    func updateBackground(for color: GameColor?, animated: Bool = true) {
        guard let bgCurrent = bgCurrent, let bgNext = bgNext else { return }
        let tex = makeBackgroundTexture(for: color)
        bgNext.texture = tex
        bgNext.size = size
        bgNext.alpha = 0
        bgNext.removeAllActions()
        if animated {
            bgNext.run(SKAction.fadeIn(withDuration: 0.5)) {
                bgCurrent.texture = tex
                bgCurrent.size = self.size
                bgCurrent.alpha = 1
                bgNext.alpha = 0
                bgNext.texture = nil
            }
        } else {
            bgCurrent.texture = tex
            bgCurrent.size = size
            bgCurrent.alpha = 1
        }
    }

    private func makeBackgroundTexture(for color: GameColor?) -> SKTexture {
        let sz = size
        let img = UIGraphicsImageRenderer(size: sz).image { ctx in
            let cgCtx = ctx.cgContext
            let cs = CGColorSpaceCreateDeviceRGB()
            let bottomColor = UIColor(red: 0.03, green: 0.03, blue: 0.07, alpha: 1)
            let topColor: UIColor
            if let c = color {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                c.uiDarkColor.getRed(&r, green: &g, blue: &b, alpha: nil)
                topColor = UIColor(red: min(1, r * 0.28 + 0.04),
                                   green: min(1, g * 0.28 + 0.03),
                                   blue: min(1, b * 0.28 + 0.08), alpha: 1)
            } else {
                topColor = UIColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
            }
            let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
            let locs: [CGFloat] = [0, 1]
            if let g = CGGradient(colorsSpace: cs, colors: colors, locations: locs) {
                cgCtx.drawLinearGradient(g,
                    start: CGPoint(x: sz.width / 2, y: sz.height),
                    end: CGPoint(x: sz.width / 2, y: 0), options: [])
            }
        }
        return SKTexture(image: img)
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
        let floodColor = board.cells[0][0]
        updateBackground(for: floodColor)
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

        let floodColor = board.cells[0][0]
        updateBackground(for: floodColor, animated: false)
    }
}
