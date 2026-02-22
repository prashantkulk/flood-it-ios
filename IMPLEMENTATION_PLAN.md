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

## Phase 4: The 3D Cell Aesthetic
**Goal:** Cells look like raised 3D platforms with gradients, shadows, highlights, and bevels.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P4-T1 | Create `FloodCellNode` (custom SKNode subclass) with layered rendering: base shadow, gradient body, top highlight, edge bevel, gloss dot | The premium visual that differentiates the app | TODO | Simulator: cells look raised/3D |
| P4-T2 | Implement gradient rendering for each GameColor (use SKTexture or CIFilter for gradient fill) | Cells need gradient, not flat color | TODO | Simulator: each color shows rich gradient |
| P4-T3 | Implement cell shadow layer (soft blur, offset, color-matched) | Depth illusion | TODO | Simulator: visible shadow beneath each cell |
| P4-T4 | Implement top highlight overlay (white-to-transparent gradient, top 30%) | Light simulation | TODO | Simulator: cells appear lit from above |
| P4-T5 | Implement edge bevel (white top/left border, dark bottom/right) | Button-like 3D edge | TODO | Simulator: cells have subtle bevel |
| P4-T6 | Implement gloss dot (small white circle, top-left corner) | Glass-like reflection | TODO | Simulator: tiny highlight visible |
| P4-T7 | Ensure all 5 colors render correctly with full 3D treatment | Consistency across palette | TODO | Simulator: all colors look premium |
| P4-T8 | Performance test: 15×15 grid (225 cells × 5 layers) renders at 60fps | Must not lag on older devices | TODO | Instruments: 60fps on iPhone 12 equivalent |

### Checkpoint P4 ✅
**Simulator:** Board looks visually stunning. Cells appear raised, glossy, and physical. Screenshot-worthy.

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
**Goal:** App icon, launch screen, App Store screenshots, final testing, submission.

| ID | Task | JTBD | Status | Verify |
|---|---|---|---|---|
| P13-T1 | Design and set app icon (1024×1024, shows a colorful flood pattern) | App Store presence | TODO | Simulator: icon visible on home screen |
| P13-T2 | Create launch screen (simple logo on gradient) | Professional first impression | TODO | Simulator: launch screen appears |
| P13-T3 | Generate App Store screenshots (6.7" and 6.1" sizes) | App Store listing | TODO | Screenshots match required sizes |
| P13-T4 | Write App Store description and keywords | Discoverability | TODO | Copy reviewed |
| P13-T5 | Full regression test: play through levels 1–20, daily challenge, win/lose sequences, all animations | Nothing broken | TODO | Manual test on simulator + device |
| P13-T6 | Performance profiling: 60fps on all screens, memory usage < 150MB | Ship quality | TODO | Instruments: all metrics pass |
| P13-T7 | Archive, sign, upload to App Store Connect | Ship it | TODO | Build uploaded |
| P13-T8 | TestFlight distribution to Prashant for final review | Last check | TODO | TestFlight build available |

### Checkpoint P13 ✅
**TestFlight:** Complete app, ready for App Store review.

---

## Summary: Phase Overview

| Phase | Focus | Tasks | Tests Added |
|---|---|---|---|
| P1 | Project setup & skeleton | 8 | 3 unit |
| P2 | Core game logic | 8 | 12+ unit |
| P3 | Basic board rendering | 8 | 1 UI |
| P4 | 3D cell aesthetic | 8 | 1 perf |
| P5 | Flood animation | 7 | 1 perf |
| P6 | Touch feedback & haptics | 6 | — |
| P7 | Win/lose sequences | 10 | 2 unit |
| P8 | Sound design | 8 | — |
| P9 | Combo system | 7 | 2 unit |
| P10 | Progression & retention | 9 | 1 unit |
| P11 | Daily challenge & share | 6 | 2 unit |
| P12 | Monetization | 6 | — |
| P13 | Polish & submission | 8 | 1 regression |
| **Total** | | **99 tasks** | **25+ tests** |

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
