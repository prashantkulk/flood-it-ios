# Flood It — Implementation Plan
**Version:** 1.1  
**Date:** 2026-02-22  
**Status:** Not started  
**Tracking:** Update status column as tasks complete. Add bugs to Section 8.

---

## Project Setup

| Item | Value |
|---|---|
| **GitHub Repo** | [prashantkulk/flood-it-ios](https://github.com/prashantkulk/flood-it-ios) (public) |
| **Branch** | `main` only — all work pushed directly to main |
| **Local Path** | `/Users/prashant/Projects/FloodIt/` |
| **Build Tool** | Claude Code CLI (v2.1.50, Opus 4.6, Max subscription) |
| **Auth** | Claude Code: claude.ai OAuth · GitHub: `gh` CLI (prashantkulk) |
| **Product Spec** | `PRODUCT_SPEC.md` in same directory |

---

## Development Workflow

### How Tasks Are Built
Each task is built using **Claude Code CLI** (native Opus 4.6). The workflow for every single task is:

1. **I (Assistant) spawn Claude Code** with a precise prompt for the task, referencing the product spec and existing code.
2. **Claude Code implements the task** — writes code, creates files, runs tests.
3. **Claude Code runs all tests** (unit + UI) to verify nothing is broken.
4. **Claude Code commits and pushes to `main`** with a descriptive commit message: `[P{phase}-T{task}] {description}`.
5. **I send Prashant a summary** via Telegram with:
   - What was implemented
   - Test results (pass/fail, count)
   - Any issues encountered
   - Link to the commit on GitHub
6. **Prashant reviews and decides:**
   - ✅ Approved → move to next task
   - 🔄 Changes needed → I relay feedback to Claude Code, iterate, re-test, re-push
   - ❌ Rejected → rethink approach, discuss before retrying

### Rules
- **NEVER assume.** If there's ambiguity about design, behavior, or approach — ASK Prashant before building.
- **NEVER skip tests.** Every task that involves logic must have unit tests. Every task that involves UI must be verified in simulator.
- **NEVER move to the next task** without Prashant's approval.
- **Always push after each task.** Prashant can review the code on GitHub at any time.
- **Commit message format:** `[P1-T3] Set up basic navigation: HomeView → GameView`
- **Simulator verification after each phase.** At each phase checkpoint, build and run the app on the iOS Simulator (`xcodebuild` or `open` in Xcode), take a screenshot if possible, and include simulator results in the summary sent to Prashant. Use: `xcrun simctl boot "iPhone 16 Pro"` + `xcodebuild -scheme FloodIt -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build` to verify.

### Claude Code Invocation
```bash
cd /Users/prashant/Projects/FloodIt
claude --dangerously-skip-permissions -p "<task prompt>"
```
Claude Code has full file access. It reads `PRODUCT_SPEC.md` and `IMPLEMENTATION_PLAN.md` for context.

---

## How to Use This Document

Each task has:
- **ID** — Reference number (e.g., P1-T3)
- **Task** — What to build
- **JTBD** — Why it matters (Job To Be Done)
- **Status** — `TODO` | `IN PROGRESS` | `DONE` | `BLOCKED`
- **Verify** — How to confirm it works (simulator or test)

Phases are sequential. Each phase ends with a **checkpoint** — a simulator-verifiable milestone.  
**No task moves to DONE without Prashant's approval.**

---

## Phase 1: Project Setup & Skeleton
**Goal:** Xcode project builds and runs. Empty game screen appears. SpriteKit + SwiftUI integration works.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P1-T1 | Create Xcode project (FloodIt, iOS, Swift, SwiftUI lifecycle) | Foundation for all work | TODO | Project compiles, blank screen on simulator |
| P1-T2 | Add SpriteKit framework. Create `GameScene.swift` (SKScene subclass) | Board rendering requires SpriteKit | TODO | SpriteKit scene appears (even if empty) |
| P1-T3 | Create `GameView.swift` — SwiftUI view hosting the SpriteKit scene via `SpriteView` | SwiftUI ↔ SpriteKit bridge | TODO | SwiftUI view wraps SpriteKit scene, renders on screen |
| P1-T4 | Set up basic navigation: `HomeView` → `GameView` with a "Play" button | Players need to start a game | TODO | Tap Play → game screen appears |
| P1-T5 | Define `FloodBoard` model: grid size, cell colors, flood region tracking | Core data model for all game logic | TODO | Unit test: board initializes correctly with 9×9 grid |
| P1-T6 | Define `FloodCell` model: row, col, color enum, isFlooded flag | Individual cell state | TODO | Unit test: cell properties work correctly |
| P1-T7 | Define `GameColor` enum with 5 cases (coral, amber, emerald, sapphire, violet) + gradient pairs | Color system used everywhere | TODO | Unit test: enum has correct color values |
| P1-T8 | Set up test targets: Unit Test bundle + UI Test bundle | Testing infrastructure for all phases | TODO | Both test bundles compile and empty tests pass |

### Checkpoint P1 ✅
**Simulator:** App launches → Home screen with "Play" button → Tap → Empty game screen appears (SpriteKit scene rendering).  
**Tests:** 3+ unit tests passing (board init, cell properties, color enum).

---

## Phase 2: Core Game Logic (No Visuals Yet)
**Goal:** The flood-fill algorithm works correctly. Game state (win/lose) is tracked. All logic is testable independent of UI.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P2-T1 | Implement `FloodBoard.generateBoard(size:colors:seed:)` — random board generation with seeded randomness | Levels need reproducible boards | TODO | Unit test: same seed → same board |
| P2-T2 | Implement `FloodBoard.flood(color:)` — BFS flood fill from top-left | Core gameplay mechanic | TODO | Unit test: flooding changes correct cells |
| P2-T3 | Implement `FloodBoard.floodRegion` — computed property returning all currently flooded cells | Need to know which cells are "owned" | TODO | Unit test: flood region grows correctly after flood() |
| P2-T4 | Implement `FloodBoard.isComplete` — true when all cells are same color | Win detection | TODO | Unit test: returns true on fully flooded board |
| P2-T5 | Implement `GameState` class: current board, moves remaining, moves made, game status (playing/won/lost) | Track game state | TODO | Unit test: game transitions to won/lost correctly |
| P2-T6 | Implement `FloodBoard.cellsAbsorbedBy(color:)` — returns ordered list of cells that WOULD be absorbed (BFS order + distance) | Needed for staggered flood animation later | TODO | Unit test: returns correct cells in correct BFS order |
| P2-T7 | Implement `LevelGenerator` — creates levels with known optimal solution and sets move budget | Difficulty system needs pre-solved levels | TODO | Unit test: generated level is solvable within budget |
| P2-T8 | Implement `FloodSolver` — greedy/BFS solver that finds a good (not necessarily optimal) solution | Need to set move budgets | TODO | Unit test: solver solves all test boards |

### Checkpoint P2 ✅
**Tests:** 15+ unit tests passing. Full game loop (generate → flood → check win/lose) works in code with zero UI.

---

## Phase 3: Basic Board Rendering
**Goal:** The board is visible on screen with colored cells. Tapping a color changes the board. Playable but ugly.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P3-T1 | Render 9×9 grid of `SKSpriteNode` cells in `GameScene`, colored by `FloodBoard` state | See the board | TODO | Simulator: 9×9 colored grid visible on game screen |
| P3-T2 | Add 5 color buttons below the board (simple colored circles in SwiftUI overlay) | Player needs to select colors | TODO | Simulator: 5 tappable color buttons visible |
| P3-T3 | Wire color button taps → `GameState.flood(color:)` → re-render board | Make the game playable | TODO | Simulator: tap a color → board updates |
| P3-T4 | Add move counter display (SwiftUI Text in top bar) | Player needs to see remaining moves | TODO | Simulator: move count decrements on each tap |
| P3-T5 | Implement win detection display: simple "You Won!" alert when board is complete | Player needs to know they won | TODO | Simulator: complete the board → win message |
| P3-T6 | Implement lose detection display: simple "Out of Moves" alert | Player needs to know they lost | TODO | Simulator: run out of moves → lose message |
| P3-T7 | Add "Restart" button that resets the current level | Player needs to retry | TODO | Simulator: restart → board resets to initial state |
| P3-T8 | Write UI test: launch → tap colors until board changes → verify move counter changes | Automated gameplay verification | TODO | UI test passes |

### Checkpoint P3 ✅
**Simulator:** Fully playable game. Ugly, no animations, but functional. Can win and lose.  
**Tests:** 1+ UI test passing. 15+ unit tests passing.

---

## Phase 4: Premium Visual Overhaul
**Goal:** Transform the flat grid into a visually stunning, premium-feeling game board. This is the biggest visual leap in the entire project — the board should look screenshot-worthy and App Store-ready after this phase.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P4-T1 | Create `FloodCellNode` (custom SKNode subclass) with layered rendering: base shadow, gradient body, top highlight, edge bevel, gloss dot — use generous corner radius (~30% of cell size) for soft, modern, touchable feel (iOS app icon shape) | Premium 3D raised cell look | TODO | Simulator: cells look raised, glossy, rounded |
| P4-T2 | Implement gradient rendering for each GameColor (use SKTexture or CIFilter for gradient fill). Each color uses its rich gradient pair from PRODUCT_SPEC Section 3.2 | Cells need gradient, not flat color | TODO | Simulator: each color shows rich gradient |
| P4-T3 | Implement color-matched soft glow/aura behind each cell — a subtle blurred halo that bleeds slightly beyond cell borders. Use SKEffectNode with Gaussian blur on an oversized colored layer, OR pre-render glow textures per color for performance. Cells should look like gemstones lit from within | Cells feel alive and luminous | TODO | Simulator: visible soft glow around each cell |
| P4-T4 | Implement cell shadow layer (soft blur, offset 2px down+right, color-matched shadow from PRODUCT_SPEC) | Depth illusion — cells float above background | TODO | Simulator: visible shadow beneath each cell |
| P4-T5 | Implement top highlight overlay (white-to-transparent gradient, top 30%) + edge bevel (white top/left, dark bottom/right) + gloss dot (8px white circle, top-left, 25% opacity) | Light simulation, button-like 3D edge, glass reflection | TODO | Simulator: cells appear lit from above with bevel and gloss |
| P4-T6 | Increase grid gap to ~4px between cells (transparent to dark background). Each cell should breathe and feel distinct | Visual breathing room, clean grid aesthetic | TODO | Simulator: cells have clear gaps, grid reads as a game board |
| P4-T7 | Implement dynamic gradient background: background shifts color to subtly match the dominant flood color (deeply desaturated and dark). Slow animated transition over 0.5s when flood color changes | Board feels immersive and alive | TODO | Simulator: background tint shifts as player floods |
| P4-T8 | Add ambient floating particles: tiny, barely-visible sparkle particles drift slowly across the background. Low birth rate, slow movement, fade in/out. Color-matched to dominant board color. Single SKEmitterNode | Depth and life without distraction | TODO | Simulator: subtle sparkles visible on dark background |
| P4-T9 | Implement flooded region idle animation: cells in the flood region have a very gentle breathing animation — slow 2% scale oscillation (1.0 → 1.02 → 1.0, 3-second cycle). Unconquered cells are static. This makes the flooded region feel like a living organism | Flooded area feels alive, creates desire to flood more | TODO | Simulator: flooded cells gently pulse, unconquered cells are still |
| P4-T10 | Redesign color buttons as floating glowing orbs: radial gradient (lighter center, darker edge) + outer glow halo + shadow beneath. Active/selected orb pulses gently. Buttons should look like they float above the UI | Premium button aesthetic that matches the board | TODO | Simulator: color buttons look like glowing spheres |
| P4-T11 | Add glassmorphism container for the board: semi-transparent frosted glass panel behind the grid using SwiftUI `.ultraThinMaterial` or equivalent. Subtle white border. Dark gradient background shows through softly | iOS-native premium feel, visual depth | TODO | Simulator: board sits on a frosted glass panel |
| P4-T12 | Ensure all 5 colors render correctly with full premium treatment (glow, gradient, shadow, bevel, corner radius) | Consistency across palette | TODO | Simulator: all colors look premium |
| P4-T13 | Performance test: 15×15 grid (225 cells × all layers + glow + particles) renders at 60fps. If glow is expensive, use pre-rendered cached textures per color instead of real-time blur | Must not lag on older devices | TODO | Instruments: 60fps on iPhone 12 equivalent |

### Checkpoint P4 ✅
**Simulator:** Board looks STUNNING. Cells are rounded, glowing, 3D. Background shifts with flood color. Floating particles add depth. Color buttons are glowing orbs on frosted glass. Screenshot-worthy — the kind of visual that makes someone stop scrolling in the App Store.

---

## Phase 5: Flood Animation
**Goal:** Tapping a color triggers a wave-based flood spread animation. The hero animation of the game.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P5-T1 | Implement staggered wave animation: cells animate in BFS distance order, 30ms offset per wave | Flood should look like liquid spreading | TODO | Simulator: flood visually spreads in waves |
| P5-T2 | Implement per-cell pop animation: scale 0.85 → 1.05 → 1.0 with spring easing | Each cell should "pop" as absorbed | TODO | Simulator: individual cells bounce when absorbed |
| P5-T3 | Implement color cross-fade on absorbed cells (old color → new color, 150ms) | Smooth color transition | TODO | Simulator: no hard color cuts, smooth blend |
| P5-T4 | Implement ripple ring effect radiating from flood boundary | Visual cue of flood edge expanding | TODO | Simulator: visible ripple at flood edge |
| P5-T5 | Implement large cluster particle burst (5+ cells: 8–12 sparkle dots) | Reward for good moves | TODO | Simulator: particles fire on large captures |
| P5-T6 | Ensure animation is non-blocking: player can plan next move during animation | Don't slow gameplay | TODO | Simulator: can tap next color while animation plays |
| P5-T7 | Performance test: wave animation on 15×15 board at 60fps | Animations must be smooth | TODO | Instruments: no frame drops |

### Checkpoint P5 ✅
**Simulator:** Flood spread looks and feels like liquid. Satisfying wave animation with pop, ripple, and particles.

---

## Phase 6: Touch Feedback & Haptics
**Goal:** Every interaction has tactile feedback. The game feels physical.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P6-T1 | Color button press animation: scale 0.88x (80ms), bounce back to 1.05x → 1.0x | Buttons feel like physical buttons | TODO | Simulator: visible press/release on button tap |
| P6-T2 | Haptic on color button tap: `UIImpactFeedbackGenerator(.light)` | Tactile confirmation | TODO | Device: feel haptic on tap |
| P6-T3 | Board cell touch highlighting: finger rests on cell → brighten + pulse ring | Board feels responsive | TODO | Simulator: hovering finger shows highlight |
| P6-T4 | Move counter tick animation: scale up 1.2x → 1.0x + flash | Draw attention to remaining moves | TODO | Simulator: counter bounces on each move |
| P6-T5 | Move counter color change: orange at ≤5 moves, red at ≤2 with pulse | Urgency signaling | TODO | Simulator: counter turns orange/red as moves decrease |
| P6-T6 | Disabled color button state: already-active color tap → soft haptic, no game action | Prevent accidental waste | TODO | Simulator: tapping same color → no move used |

### Checkpoint P6 ✅
**Simulator/Device:** Every tap feels responsive. Buttons press, cells highlight, counter animates.

---

## Phase 7: Win/Lose Sequences
**Goal:** The "Last Cluster" moment, Completion Rush, and lose sequence are fully implemented.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P7-T1 | Detect "last cluster" move: if flood(color) would complete the board, trigger special sequence | The hero moment needs detection | TODO | Unit test: detects winning move correctly |
| P7-T2 | Last Cluster animation: 500ms pause → dim board → rapid dam-break flood | The "oh... OH!" moment | TODO | Simulator: visible pause then rapid sweep |
| P7-T3 | Completion Rush Phase 1: board pulse (all cells scale 1.15x → 1.0x) | Victory breathing | TODO | Simulator: board breathes on win |
| P7-T4 | Completion Rush Phase 2: shimmer wave sweep (top-left to bottom-right light sweep) | Light celebration | TODO | Simulator: shimmer visible |
| P7-T5 | Completion Rush Phase 3: confetti burst (60–80 particles, all 5 colors, gravity arc) | Euphoric celebration | TODO | Simulator: confetti explodes |
| P7-T6 | Score card overlay: frosted glass card slides up with spring animation (moves, stars, next/replay buttons) | Results display | TODO | Simulator: score card appears after win |
| P7-T7 | Star rating calculation: ★ (solved) / ★★ (optimal+3) / ★★★ (optimal+1) | Performance feedback | TODO | Unit test: star ratings calculate correctly |
| P7-T8 | Star animation: stars pop in one by one with chime | Satisfying reveal | TODO | Simulator: stars animate sequentially |
| P7-T9 | Lose sequence: dim non-flooded cells, horizontal shake, overlay with retry/quit | Calm failure | TODO | Simulator: lose screen appears appropriately |
| P7-T10 | "Almost!" mechanic: ≤2 cells remaining on lose → special message + rewarded ad offer | Convert near-wins into ad views | TODO | Simulator: special message on close losses |

### Checkpoint P7 ✅
**Simulator:** Winning feels euphoric (confetti, stars, card). Losing feels gentle. The "last cluster" moment creates a genuine rush.

---

## Phase 8: Sound Design
**Goal:** Every interaction has designed sound. Adaptive ambient layer responds to game state.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P8-T1 | Create/source sound assets: cell absorption plip (pitched), button click, cluster whoosh, dam break rumble, win chime, lose tone, confetti sparkle, star chimes | All game sounds | TODO | Assets exist and play correctly |
| P8-T2 | Implement ascending pitch system: absorption plip pitch rises with BFS wave distance | Musical flood spread | TODO | Device: flood sounds like ascending scale |
| P8-T3 | Implement color button tap sounds (slightly different timbre per color) | Audio color identity | TODO | Device: each color sounds subtly different |
| P8-T4 | Implement dam-break sound sequence: silence → rumble → torrent → boom | Hero sound moment | TODO | Device: last cluster sounds powerful |
| P8-T5 | Implement Completion Rush audio: chord swell → arpeggio → sparkle burst → star chimes | Victory sounds euphoric | TODO | Device: win sequence sounds celebratory |
| P8-T6 | Implement adaptive ambient layer: sparse at start, builds with flood %, swells near completion | Game feels alive | TODO | Device: ambient responds to game progress |
| P8-T7 | Sound settings: global volume, SFX on/off, music on/off | Player control | TODO | Simulator: settings toggle audio correctly |
| P8-T8 | Ensure all sounds work with silent mode / Do Not Disturb | iOS compliance | TODO | Device: respects silent switch |

### Checkpoint P8 ✅
**Device:** Playing with sound on is noticeably better than sound off. The ascending flood tones are satisfying. The dam-break moment is powerful.

---

## Phase 9: Combo System
**Goal:** Consecutive efficient moves build a visual/audio combo that makes skilled play feel rewarding.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P9-T1 | Track combo state: consecutive moves absorbing 4+ cells → combo counter increments | Combo detection logic | TODO | Unit test: combo increments/resets correctly |
| P9-T2 | Combo ×2 visual: golden glow around flood boundary | First combo tier | TODO | Simulator: golden glow appears at ×2 |
| P9-T3 | Combo ×3 visual: intensified glow + spark particles trailing flood edge | Escalation | TODO | Simulator: sparks trail at ×3 |
| P9-T4 | Combo ×4+ visual: board saturation increase + subtle screen shake on wave | Power fantasy | TODO | Simulator: board intensifies at ×4+ |
| P9-T5 | Combo audio: reverb boost on absorption tones, bass throb at ×3+ | Audio escalation | TODO | Device: sound gets richer with combo |
| P9-T6 | Combo break: golden glow fades, "tink" sound | Gentle reset | TODO | Simulator: combo fades on weak move |
| P9-T7 | Combo score multiplier: star rating calculation factors in max combo | Reward skilled play | TODO | Unit test: combo affects star calculation |

### Checkpoint P9 ✅
**Simulator:** Building a combo feels genuinely exciting. The golden glow, particles, and audio escalation create a power fantasy.

---

## Phase 10: Progression & Retention Systems
**Goal:** Streak tracking, level packs with star-gating, onboarding levels, and the living background.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P10-T1 | Implement level data: 100 pre-generated levels with seeds, optimal solutions, move budgets, difficulty ratings | Game content | TODO | Unit test: all 100 levels are solvable |
| P10-T2 | Implement level select screen: grid of levels, star indicators, locked/unlocked state | Navigate levels | TODO | Simulator: level grid visible, can select levels |
| P10-T3 | Implement star persistence: save best star rating per level via Swift Data | Track progress across sessions | TODO | Simulator: stars persist after app restart |
| P10-T4 | Implement pack gating: Current pack requires 50 stars, etc. | Star-driven progression | TODO | Simulator: locked packs show star requirement |
| P10-T5 | Implement streak system: track daily play, persist streak count, show flame on home screen | Daily retention | TODO | Simulator: streak counter appears on home |
| P10-T6 | Implement onboarding levels 1–5: 3×3→4×4→5×5→7×7→9×9, generous moves, no tutorial text | Teach through play | TODO | Simulator: first 5 levels progressively introduce mechanics |
| P10-T7 | Implement living background: gradient shifts to match dominant flood color | Immersive feel | TODO | Simulator: background color follows flood color |
| P10-T8 | Implement "just one more" transition: score card → tap Next → seamless 600ms board shuffle to next level | Minimize friction between levels | TODO | Simulator: level transition is smooth, no menu |
| P10-T9 | Implement color theme system: default theme + 2 unlockable themes (unlock at 50 and 100 stars) | Cosmetic rewards | TODO | Simulator: themes change all colors on board |

### Checkpoint P10 ✅
**Simulator:** Full game progression works. Levels unlock. Stars accumulate. Streak tracks. Onboarding teaches without text. Background is alive.

---

## Phase 11: Daily Challenge & Share Card
**Goal:** One puzzle per day, same for all players. Shareable result card.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P11-T1 | Generate daily challenge board from date-seeded RNG (no server needed for v1.0) | Same puzzle for everyone | TODO | Unit test: same date → same board |
| P11-T2 | Daily Challenge mode: separate entry from home screen, shows today's date | Distinct mode | TODO | Simulator: daily challenge accessible |
| P11-T3 | Daily result persistence: save completion status, moves used, stars for each day | Track daily history | TODO | Simulator: yesterday's result saved |
| P11-T4 | Generate share card image: "Flood It Daily #N" + moves + stars + mini flood-path visualization | Viral sharing | TODO | Simulator: share card renders correctly |
| P11-T5 | Share sheet integration: one-tap share to iMessage/WhatsApp/Instagram | Easy sharing | TODO | Simulator: share sheet appears with card |
| P11-T6 | Daily streak integration: daily challenge completion counts toward streak | Unified streak | TODO | Unit test: completing daily increments streak |

### Checkpoint P11 ✅
**Simulator:** Daily challenge playable. Share card generates. Share sheet works.

---

## Phase 12: Monetization
**Goal:** Ads and IAPs integrated. Revenue-generating.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P12-T1 | Integrate Google AdMob SDK | Ad infrastructure | TODO | Compiles with AdMob |
| P12-T2 | Implement interstitial ads: show between level packs (not every level) | Revenue without annoyance | TODO | Simulator: interstitial appears at pack boundaries |
| P12-T3 | Implement rewarded video: "Watch ad for +3 moves" on lose, "Watch ad for hint" | High-value ad placement | TODO | Simulator: rewarded ad flow works |
| P12-T4 | Implement "Remove Ads" IAP ($2.99) via StoreKit 2 | Premium offering | TODO | Sandbox: purchase flow works |
| P12-T5 | Implement purchase persistence: ads disabled after purchase, survives reinstall | IAP must be reliable | TODO | Sandbox: purchase persists |
| P12-T6 | Implement "Restore Purchases" in settings | App Store requirement | TODO | Sandbox: restore works |

### Checkpoint P12 ✅
**Sandbox:** Ads appear. Rewarded video grants moves. IAP purchase removes ads.

---

## Phase 13: Polish & App Store Prep
**Goal:** App icon, launch screen, App Store screenshots, final testing. (Submission moved to P21.)

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P13-T1 | Design and set app icon (1024×1024, shows a colorful flood pattern) | App Store presence | TODO | Simulator: icon visible on home screen |
| P13-T2 | Create launch screen (simple logo on gradient) | Professional first impression | TODO | Simulator: launch screen appears |
| P13-T3 | Generate App Store screenshots (6.7" and 6.1" sizes) | App Store listing | TODO | Screenshots match required sizes |
| P13-T4 | Write App Store description and keywords | Discoverability | TODO | Copy reviewed |
| P13-T5 | Full regression test: play through levels 1–20, daily challenge, win/lose sequences, all animations | Nothing broken | TODO | Manual test on simulator + device |
| P13-T6 | Performance profiling: 60fps on all screens, memory usage < 150MB | Ship quality | TODO | Instruments: all metrics pass |
| P13-T7 | Archive, sign, upload to App Store Connect (same pipeline as ClassNotes: `xcodebuild archive` → `codesign` → `xcodebuild -exportArchive` with `-allowProvisioningUpdates`) | Ship it | TODO | Build uploaded to App Store Connect |
| P13-T8 | Verify build appears in TestFlight, distribute to Prashant for final review | Last check | TODO | TestFlight build installable on Prashant's device |

### Checkpoint P13 ✅
**TestFlight:** Complete app, ready for App Store review.

---

## Phase 14: Scoring System & Enhanced Juice
**Goal:** Add a full scoring system, tiered visual/haptic feedback, grid tap shortcut, idle shimmer, and near-miss lose screen. Every move should feel like it matters.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P14-T1 | `ScoreState` model: totalScore, calculateMoveScore(cellsAbsorbed, comboMultiplier, cascadeMultiplier), calculateEndBonus(movesRemaining, isOptimalPlusOne) | Scoring logic testable independently | TODO | Unit test: 12 cells at combo x3 = 720 pts |
| P14-T2 | Integrate ScoreState into GameState: update score in performFlood(), add moveScore/cellsAbsorbed to return type | Score tracked throughout game | TODO | Unit test: score accumulates, end bonus on win |
| P14-T3 | Score counter display in top bar (gold-tinted, .monospacedDigit alongside move counter) | Player sees score | TODO | Simulator: score visible, updates each move |
| P14-T4 | Counter pop animations: score 1.3x easeOutBack + gold flash; move counter 1.3x + gold on 10+ cells | Big moves feel impactful | TODO | Simulator: counters pop and flash |
| P14-T5 | Floating "+N cells" SKLabelNode at absorbed centroid, white, drifts up 40px/0.8s, fades out | Raw absorption feedback | TODO | Simulator: white number floats up |
| P14-T6 | Floating "+X pts" SKLabelNode 0.15s later, gold, 60px/1.0s. Larger + gold burst on 1.5x+ multiplier | Points visible | TODO | Simulator: gold text, bigger on bonuses |
| P14-T7 | Tiered haptics: <5=light, 5-15=medium, 15+=heavy+rigid. Wire to both color buttons and grid tap | Haptics scale with impact | TODO | Device: distinctly different |
| P14-T8 | Tiered particles: 10-19=ring scales 6x, 20+=ring+screen flash (15% white overlay, 0.15s) | Bigger floods explosive | TODO | Simulator: flash on 20+ |
| P14-T9 | Screen shake via SKCameraNode: 2-3px, 0.15s dampened, 20+ cells only | Visceral impact | TODO | Simulator: visible shake |
| P14-T10 | Grid tap shortcut: touch handling in GameScene, determine tapped cell's color, callback to GameView to execute flood | Grid tap works | TODO | Simulator: tap cell = flood that color |
| P14-T11 | Grid tap ghost preview: white 30% overlay on would-be-absorbed cells for 150ms, same-color = shake | Feed-forward cue | TODO | Simulator: preview flash |
| P14-T12 | Move counter color urgency: orange at ≤5 moves, red at ≤2 with aggressive pulse | Urgency signaling | TODO | Simulator: colors change |
| P14-T13 | Idle grid shimmer: diagonal light sweep after 5-10s idle, 15ms stagger per diagonal, 0.4s total | Board alive during pauses | TODO | Simulator: shimmer visible |
| P14-T14 | Near-miss lose screen: progress bar "Board 87% complete!", "Just 12 cells left!" | Drive retry impulse | TODO | Simulator: near-miss framing on loss |
| P14-T15 | Performance test: all new effects at 60fps on 15×15 | No degradation | TODO | Instruments: 60fps |

### Checkpoint P14 ✅
**Simulator:** Score counter visible and updating. Floating text on every move. Tiered particles/haptics/screen shake make big moves feel explosive. Grid tap works as shortcut. Idle shimmer keeps board alive. Near-miss lose screen drives retry.

---

## Phase 15: Cascade System
**Goal:** After a flood, automatically absorb newly-adjacent same-color cells in chain reactions. Cascades are the #1 variable reward mechanic — surprise jackpot moments.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P15-T1 | Cascade detection in FloodBoard: after flood(), check if newly connected region now touches more same-color cells not previously adjacent. Return cascade waves separately | Cascade logic | TODO | Unit test: cascade detected on prepared board |
| P15-T2 | Recursive cascade: keep checking after each cascade wave until stable state | Multi-chain support | TODO | Unit test: triple cascade on prepared board |
| P15-T3 | Integrate cascade into GameState.performFlood(): return cascadeWaves alongside regular waves | Full cascade data flow | TODO | Unit test: performFlood returns cascade data |
| P15-T4 | Cascade animation: each cascade wave plays 100ms after previous, escalating particle intensity, ascending pitch | Visual cascade chain | TODO | Simulator: cascade waves animate sequentially |
| P15-T5 | Cascade scoring: each wave 1.5x multiplier (wave 1=1x, wave 2=1.5x, wave 3=2.25x) | Escalating reward | TODO | Unit test: cascade score math correct |
| P15-T6 | "CASCADE x2!" / "CASCADE x3!" floating golden text on multi-chain reactions | Player sees cascade feedback | TODO | Simulator: cascade text visible |
| P15-T7 | Cascade sound: escalating plip tones + whoosh per wave, crescendo on long chains | Audio excitement | TODO | Device: cascades sound exciting |

### Checkpoint P15 ✅
**Simulator:** Cascades fire automatically after floods that create new adjacencies. Visual escalation (bigger particles, ascending pitch, golden text) makes cascades feel like jackpots. Score multiplies dramatically on long chains.

---

## Phase 16: Obstacle System — Models & Logic
**Goal:** All obstacle types implemented as pure logic, fully testable without visuals. BFS handles stones, voids, ice, countdowns, walls, portals, and bonus tiles.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P16-T1 | Extend cell model: add `CellType` enum — normal, stone, void, portal(pairId), countdown(movesLeft), ice(layers). Add optional `wallEdges: Set<Direction>` | Data model for all obstacles | TODO | Compiles, unit test: types construct |
| P16-T2 | Stone blocks: BFS skips stone cells, never change color, excluded from win check | Core obstacle | TODO | Unit test: flood stops at stones, win ignores stones |
| P16-T3 | Void cells: not part of playfield, excluded from all logic. Board shapes via void patterns | Shaped boards | TODO | Unit test: void cells excluded from flood and win |
| P16-T4 | Ice layers: flood passing over ice cell decrements layer. At 0 layers → normal cell | Multi-pass obstacle | TODO | Unit test: ice cracks, becomes normal after all layers |
| P16-T5 | Countdown cells: decrement each move. At 0 → scramble 3x3 area to random colors. Absorbed before 0 → defused | Urgency obstacle | TODO | Unit test: decrement, scramble, defuse all work |
| P16-T6 | Walls between cells: block flood propagation through wall edge even if colors match | Routing obstacle | TODO | Unit test: wall blocks flood between adjacent cells |
| P16-T7 | Portals: two cells treated as adjacent for BFS | Topology puzzle | TODO | Unit test: flood flows through portal pair |
| P16-T8 | Bonus tiles: x2/x3 multiplier, score multiplied when absorbed | Variable reward | TODO | Unit test: bonus tile multiplies move score |
| P16-T9 | Update FloodSolver to handle all obstacle types | Solver for budgets | TODO | Unit test: solver solves obstacle boards |
| P16-T10 | Comprehensive obstacle interaction tests: stone+ice, portal+wall, countdown+cascade, etc. | Edge cases | TODO | 10+ unit tests covering combinations |

### Checkpoint P16 ✅
**Tests:** All obstacle types work in pure logic. BFS respects stones, voids, walls, portals. Ice cracks. Countdowns tick. Bonus tiles multiply. Solver handles all types. 30+ new unit tests.

---

## Phase 17: Obstacle Rendering & Animation
**Goal:** Every obstacle type has a distinct, instantly recognizable visual treatment. Players understand obstacles through visuals alone — no tutorial text.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P17-T1 | Stone block rendering: gray textured cell, rough surface, no glow, clearly non-interactive | Stones visible | TODO | Simulator: stones look solid/immovable |
| P17-T2 | Void cell rendering: cell not rendered, dark bg shows through. Board shapes look natural | Shaped boards | TODO | Simulator: L/donut/diamond shapes look correct |
| P17-T3 | Ice layer rendering: translucent blue-white overlay, thicker for 2 layers. Crack animation + "crack" sound on layer removal | Ice visually satisfying | TODO | Simulator: ice cracks are satisfying |
| P17-T4 | Countdown cell rendering: number overlay, pulses red at 1. Explosion animation (red flash + scramble) at 0. "Defused!" text on absorption | Countdown dramatic | TODO | Simulator: countdown visible, explosion dramatic |
| P17-T5 | Wall rendering: thin dark line between cells where wall exists | Walls clear | TODO | Simulator: walls clearly visible between cells |
| P17-T6 | Portal rendering: swirling vortex effect (rotating gradient), particle trail when flood flows through | Portals magical | TODO | Simulator: portals visually distinct |
| P17-T7 | Bonus tile rendering: golden glow, "x2"/"x3" text overlay, gold explosion on absorption | Bonus = jackpot feel | TODO | Simulator: bonus tiles look exciting |
| P17-T8 | Performance test: 15x15 board with all obstacle types at 60fps | No lag | TODO | Instruments: 60fps |

### Checkpoint P17 ✅
**Simulator:** Every obstacle type is visually distinct and readable at a glance. Ice cracks are satisfying, countdowns are tense, portals feel magical, bonus tiles feel like jackpots.

---

## Phase 18: Level Data Overhaul
**Goal:** Redesign all 100 levels with the new obstacle progression and roller-coaster difficulty curve. Every level solvable, every obstacle introduced gradually.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P18-T1 | Extend LevelData: add obstacleConfig (stone positions, ice positions+layers, countdown positions+values, wall edges, portal pairs, bonus positions, void mask) | Level config supports obstacles | TODO | Compiles with new fields |
| P18-T2 | Board shape templates: rectangular, L-shape, donut, diamond, cross, heart, custom void masks | Non-rectangular levels | TODO | Unit test: shapes generate correctly |
| P18-T3 | Obstacle placement algorithm: place N stones/ice/etc. ensuring board remains solvable via solver | Solvable obstacle levels | TODO | Unit test: generated levels solvable |
| P18-T4 | Generate levels 1-20: onboarding + easy breathers (no obstacles, keep existing behavior) | Preserve onboarding | TODO | Unit test: levels 1-20 same as before |
| P18-T5 | Generate levels 21-30: stones + shaped boards | First obstacles | TODO | Unit test: stones present, solvable |
| P18-T6 | Generate levels 31-40: ice layers | Ice introduced | TODO | Unit test: ice present, solvable |
| P18-T7 | Generate levels 41-50: countdown cells + boss gauntlet | Urgency levels | TODO | Unit test: countdowns present, solvable |
| P18-T8 | Generate levels 51-65: walls + portals | Topology puzzles | TODO | Unit test: walls/portals present, solvable |
| P18-T9 | Generate levels 66-100: escalating combinations, expert, final boss gauntlet | Full progression | TODO | Unit test: all 100 levels solvable |
| P18-T10 | Difficulty roller coaster verification: chart follows sawtooth (easy-hard-easy pattern) | Not linear difficulty | TODO | Manual review + unit test: move budgets follow pattern |
| P18-T11 | Bonus tiles scattered across levels 15+ | Variable rewards | TODO | Unit test: bonus tiles in expected levels |

### Checkpoint P18 ✅
**Tests:** All 100 levels solvable with obstacles. Difficulty follows sawtooth curve. Obstacle introduction is gradual. Bonus tiles scattered for variable rewards.

---

## Phase 19: Win Celebration & Gold Rush Overhaul
**Goal:** The win sequence is the emotional climax. Upgrade it with a rolling score tally, gold coin rain, perfect clear badge, and visceral lose screen.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P19-T1 | Rolling score tally on win: remaining moves tick down (0.3s each), "+50" floats up, score counter rolls | Satisfying payoff | TODO | Simulator: tally animates |
| P19-T2 | Gold coin particles during tally: 3-4 gold sprites per tick, rain from top with gravity | Gold rush feel | TODO | Simulator: gold coins rain |
| P19-T3 | Tally speed cap: accelerate if many moves remain, cap total tally at 2s | Don't bore player | TODO | Simulator: long tallies speed up |
| P19-T4 | Perfect clear badge: "+500 PERFECT" gold text pulses in after tally | Reward optimal play | TODO | Simulator: badge visible on perfect clears |
| P19-T5 | Updated score card: final score (gold, prominent), moves, stars, best score for level | Score is centerpiece | TODO | Simulator: score dominates card |
| P19-T6 | Lose screen desaturation: non-flooded cells to grayscale over 0.5s | Visceral loss feel | TODO | Simulator: color drains on loss |
| P19-T7 | Lose screen final score display | Player sees progress | TODO | Simulator: score shown on lose card |

### Checkpoint P19 ✅
**Simulator:** Winning feels like a gold rush — coins rain, score tallies up, perfect badge pulses. Losing feels visceral — color drains, but near-miss framing drives retry.

---

## Phase 20: Full QA Playthrough & Bug Fix Cycle
**Goal:** Play the entire game like a real player. Find everything broken or unpolished. Fix it all. This is the final quality gate.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P20-T1 | **Code review playthrough**: Read every Swift file, identify all bugs and UX issues. | Find all real bugs | DONE | Output: `bugs.md` with 6 bugs |
| P20-T2 | **Create improvements.md**: Document UX improvements found during review. | Find all UX gaps | DONE | Output: `improvements.md` with 8 items |
| P20-T3 | **Fix all bugs**: Fixed all 6 bugs — obstacle config on level transition, playable cell counting, ambient audio race condition, StoreKit verification, combo feedback. | Zero known bugs | DONE | All 6 bugs FIXED, 198 tests pass |
| P20-T4 | **Implement improvements**: Back button, level label, disable buttons during animations, Done on final level, haptic prepare(). 3 items deferred. | Fix UX issues | DONE | 5/8 DONE, 3 DEFERRED |
| P20-T5 | **Add verification tests**: 8 new tests for bug fix verification (playableCellCount, shaped boards). | Test coverage | DONE | 198 tests, 0 failures |
| P20-T6 | **Release build verification**: Release configuration builds with 0 warnings. | Build quality | DONE | BUILD SUCCEEDED, 0 warnings |
| P20-T7 | **Edge case testing**: 9 edge case tests — obstacles, level 100, large board scoring, rapid floods, all-same-color, stones-only, combo multiplier. | Code quality | DONE | 198 tests, 0 failures |
| P20-T8 | **Final sign-off**: Updated bugs.md, improvements.md, and implementation plan. | Documentation | DONE | Both docs finalized |

### Phase 20 Rules
- Play in the actual iOS Simulator (iPhone 17 Pro), not just code review
- Think like a REAL PLAYER, not a developer — notice things that feel wrong even if the code is "correct"
- Every bug must be verified fixed in the simulator, not just in code
- `bugs.md` format: `BUG-001: [Description] | Severity: Critical/High/Medium/Low | Status: OPEN/FIXED | Fix: [what was done]`
- `improvements.md` format: `IMP-001: [Description] | Impact: High/Medium/Low | Status: TODO/DONE | Change: [what was done]`
- Files created at `/Users/prashant/Projects/FloodIt/bugs.md` and `/Users/prashant/Projects/FloodIt/improvements.md`

### Checkpoint P20 ✅
**Simulator:** All 100 levels playable. Zero known bugs. Every interaction feels polished. Game quality is App Store-ready.

---

## Phase 21: App Store Submission
**Goal:** Generate final screenshots, update store listing, archive, and upload to App Store Connect. The very last phase after all QA is complete.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P21-T1 | Generate final App Store screenshots (6.7" and 6.1" sizes) showing new features (obstacles, cascades, scoring, gold rush) | App Store listing | TODO | Screenshots match required sizes |
| P21-T2 | Update App Store description and keywords to highlight new features | Discoverability | TODO | Copy reviewed |
| P21-T3 | Archive, sign, upload to App Store Connect (`xcodebuild archive` → `codesign` → `xcodebuild -exportArchive` with `-allowProvisioningUpdates`) | Ship it | TODO | Build uploaded to App Store Connect |
| P21-T4 | Verify build in TestFlight, distribute to Prashant for final review | Last check | TODO | TestFlight build installable |

### Checkpoint P21 ✅
**TestFlight:** Complete app with obstacles, cascades, scoring, and enhanced juice — ready for App Store review.

---

## Summary: Phase Overview

| Phase | Focus | Tasks | Status |
|---|---|---|---|
| P1 | Project setup & skeleton | 8 | DONE |
| P2 | Core game logic | 8 | DONE |
| P3 | Basic board rendering | 8 | DONE |
| P4 | Premium visual overhaul (3D cells, glow, particles, glassmorphism, dynamic bg) | 13 | DONE |
| P5 | Flood animation | 7 | DONE |
| P6 | Touch feedback & haptics | 6 | PARTIAL (T1 done) |
| P7 | Win/lose sequences | 10 | DONE |
| P8 | Sound design | 8 | DONE |
| P9 | Combo system | 7 | DONE |
| P10 | Progression & retention | 9 | DONE |
| P11 | Daily challenge & share | 6 | DONE |
| P12 | Monetization | 6 | DONE |
| P13 | Polish & App Store prep | 8 | DONE |
| **P14** | **Scoring system & enhanced juice** | **15** | **TODO** |
| **P15** | **Cascade system** | **7** | **TODO** |
| **P16** | **Obstacle models & logic** | **10** | **TODO** |
| **P17** | **Obstacle rendering & animation** | **8** | **TODO** |
| **P18** | **Level data overhaul** | **11** | **TODO** |
| **P19** | **Win celebration & gold rush** | **7** | **TODO** |
| **P20** | **Full QA playthrough & bug fix cycle** | **8** | **DONE** |
| **P21** | **App Store submission** | **4** | **TODO** |
| **Total** | | **169 tasks** | |

---

## 8. Bug Tracker

| ID | Description | Severity | Phase | Status | Fix |
|---|---|---|---|---|---|
| — | No bugs yet | — | — | — | — |

Add bugs here as discovered during development. Format:
- **BUG-001:** [Description] | Severity: Critical/High/Medium/Low | Phase: P3 | Status: TODO/FIXED | Fix: [what was done]

---

## 9. Notes & Decisions

Track any architectural decisions, pivots, or learnings here:

- **2026-02-22:** GitHub repo created: `prashantkulk/flood-it-ios` (public)
- **2026-02-22:** Branch strategy: `main` only, no feature branches
- **2026-02-22:** Build tool: Claude Code CLI (Opus 4.6, Max subscription)
- **2026-02-22:** Workflow: build → test → commit → push → notify Prashant → wait for approval → next task
- **2026-02-22:** Rule: NEVER assume. Ask Prashant if any doubt.
- **2026-02-22:** Rule: Every task gets its own commit and push. No batching.
