import SpriteKit

class GameScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        scaleMode = .resizeFill

        let label = SKLabelNode(text: "Game Scene Ready")
        label.fontColor = .white
        label.fontSize = 20
        label.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(label)
    }
}
