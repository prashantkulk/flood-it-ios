# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

Project uses XcodeGen — regenerate after adding/removing files:
```bash
xcodegen generate
```

Build:
```bash
xcodebuild -scheme FloodIt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Run all tests:
```bash
xcodebuild test -scheme FloodIt -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Run a single test:
```bash
xcodebuild test -scheme FloodIt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FloodItTests/FloodBoardTests/testBoardInitialization
```

**Note:** No iPhone 16 Pro simulator available — always use **iPhone 17 Pro**.

## Architecture

SwiftUI app with SpriteKit game board. Clean separation: SwiftUI owns state and UI chrome, SpriteKit is a pure display layer with no game logic.

**Communication flow:**
```
Color button tap (SwiftUI GameView)
  → GameState.performFlood(color:)     // mutates board, returns wave data
  → GameScene.animateFlood(...)        // animates the visual changes
```

`GameState.performFlood()` computes BFS wave data *before* mutating the board, returning `(waves, previousColors)` for animation staggering.

**Key layers:**
- `GameView.swift` — SwiftUI wrapper: holds `GameState` (@StateObject) and `GameScene`, renders color buttons/HUD/overlays
- `GameScene.swift` — SpriteKit scene: cell rendering, wave animations, ripple rings, particles. No game logic
- `FloodCellNode.swift` — Custom SKNode with 6 layered children (glow, shadow, body, highlight, bevel, gloss) for 3D cell appearance
- `CellTextureCache.swift` — Pre-renders and caches SKTextures by key (e.g., `"grad_coral_38"`)
- `Models/GameState.swift` — ObservableObject, single mutation point for game logic
- `Models/FloodBoard.swift` — Value type with BFS flood fill, wave computation, seeded board generation (SplitMix64)
- `Models/GameColor.swift` — 5-color enum (coral/amber/emerald/sapphire/violet) with SwiftUI, SpriteKit, and UIColor variants; includes `Color(hex:)` extension

## Conventions

- **Commit format:** `[P{phase}-T{task}] {description}`
- **Push directly to `main`** — no feature branches
- **Value types** for all game logic (`FloodBoard`, `FloodCell`, `CellPosition`, `Level`). Only `GameState` is a class (ObservableObject)
- **Dark background:** RGB(0.06, 0.06, 0.12) used in both SwiftUI and SpriteKit
- **iPhone only, portrait, iOS 16.0+**
- **Tests** use `@testable import FloodIt`, organized by plan task ID in `// MARK:` comments
- Design spec in `PRODUCT_SPEC.md`, task breakdown in `IMPLEMENTATION_PLAN.md`
