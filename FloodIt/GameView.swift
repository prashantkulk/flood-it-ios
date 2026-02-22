import SwiftUI
import SpriteKit

struct GameView: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: makeScene(size: geometry.size))
                .ignoresSafeArea()
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.12))
    }

    private func makeScene(size: CGSize) -> GameScene {
        let scene = GameScene(size: size)
        scene.scaleMode = .resizeFill
        return scene
    }
}

#Preview {
    GameView()
}
