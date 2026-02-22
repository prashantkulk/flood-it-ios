# Flood It — Product Specification
**Version:** 1.1 (Revised — deeper retention & polish)  
**Date:** 2026-02-22  
**Status:** Pre-development  

---

## 1. Overview

**Flood It** is a single-player casual puzzle game for iOS. The premise is simple: a grid of colored cells, and you flood-fill from the top-left corner by tapping a color. Your flooded region expands to absorb all adjacent matching cells. Win by turning the entire board one color within a limited number of moves.

The gameplay ceiling is low — anyone understands it in 10 seconds. What makes the game compelling is not strategy depth but **visceral satisfaction**: the sound of cells being absorbed, the liquid ripple of color spreading across the board, the euphoric rush when the last cluster collapses and the whole grid floods in one sweep.

This spec defines not just what the game does, but **how it feels** — because for this game, feel IS the product.

---

## 2. Core Game Loop

### 2.1 Board Setup
- Grid: **9×9** cells (default). Larger grids (12×12, 15×15) unlock at higher difficulty tiers.
- Each cell is assigned one of **5 colors** at game start (randomized, seeded per level).
- The player "owns" all cells connected to the **top-left corner** that share the same color — this is the starting flood region.

### 2.2 A Turn
1. Player taps one of the **5 color buttons** at the bottom of the screen.
2. The player's flood region instantly changes to that color.
3. Any cells **adjacent** to the flood region that match the new color get absorbed into it.
4. Move counter decrements by 1.

### 2.3 Win / Lose Condition
- **Win:** The entire board becomes one color before moves run out.
- **Lose:** Moves run out with cells still unconquered.
- On win: **Completion Rush sequence** plays (see Section 5.4).
- On lose: Board gently shakes, cells dim, a "Try Again" overlay appears.

### 2.4 Difficulty = Move Limit
The same board can be easy or hard purely by changing the allowed number of moves. This is the core difficulty lever.
- Easy: generous move budget (board is solvable in many ways)
- Hard: tight budget (requires optimal or near-optimal play)
- Expert: minimum possible moves — the player must think several steps ahead

---

## 3. Visual Design Philosophy

### 3.1 The Aesthetic Direction
**"Liquid Glass"** — The board should feel like colored liquid trapped in frosted glass cells. Not flat. Not cartoon. Not realistic 3D. Something in between: a physical, tactile, satisfying material that responds to touch.

Think: the satisfying pop of pressing a key on a good keyboard, translated into a visual. Every interaction should feel like it has weight and give.

### 3.2 Color System
The 5 colors are NOT flat fills. Each color is a **rich gradient pair**:

| Color Name | Gradient (Light → Dark) | Shadow color |
|---|---|---|
| Coral | #FF6B6B → #C0392B | rgba(192,57,43,0.4) |
| Amber | #FFD93D → #E0A800 | rgba(224,168,0,0.35) |
| Emerald | #6BCB77 → #27AE60 | rgba(39,174,96,0.35) |
| Sapphire | #4D96FF → #1A6BC4 | rgba(26,107,196,0.4) |
| Violet | #C77DFF → #8E44AD | rgba(142,68,173,0.4) |

The background of each cell is the gradient. The top face has a subtle **inner highlight** (a 1px semi-transparent white border on the top and left edges) to simulate top-down lighting. This single detail transforms a flat square into something that looks physically raised.

### 3.3 The 3D Cell Effect
Each cell is rendered as a **raised platform** using layered visual elements:

**Layer 1 — Base shadow:** A soft blurred shadow beneath the cell, offset 2px down and 2px right. Color is the shadow color from the table above. This pushes the cell "up" from the background.

**Layer 2 — Cell body:** The gradient fill, full cell size.

**Layer 3 — Top highlight:** A very subtle white-to-transparent gradient overlay, covering the top 30% of the cell. This creates the illusion of light hitting the top surface.

**Layer 4 — Edge bevel:** A 1px white border on the top and left edges only (not bottom/right). Bottom and right have a 1px darker border (50% opacity of the shadow color). This is what makes a flat box look like a button.

**Layer 5 — Gloss dot:** A tiny circular white highlight (8px diameter, 25% opacity) in the top-left corner of the cell. Mimics a light reflection on a glossy surface.

All 5 layers are rendered in SpriteKit as a custom `FloodCell` SKSpriteNode subclass. No actual 3D engine is needed — this is pure 2D compositing that reads as 3D.

### 3.4 Inner Glow / Soft Neon Aura
Each cell emits a subtle, color-matched glow that bleeds slightly beyond its borders — like a gemstone lit from within. This is NOT harsh neon. It's a soft, warm halo that gives the entire board a luminous quality. Implemented via SKEffectNode with Gaussian blur on an oversized colored layer behind each cell, or pre-rendered glow textures per color for performance.

### 3.5 Cell Shape
Cells use a **generous corner radius** (~30% of cell size). This creates a soft, modern, touchable feel — like iOS app icons. Not sharp squares. Rounded, friendly, premium.

### 3.6 Grid Gaps
~4px gaps between cells, transparent to the dark background beneath. This breathing room makes each cell feel distinct, the dark gaps create a natural grid, and the glow effect from adjacent cells subtly overlaps in the gap space, creating visual richness.

### 3.7 Glassmorphism Board Container
The grid sits on a **frosted glass panel** — a semi-transparent blurred container with a subtle white border (1px, 15% opacity). The dark gradient background shows through softly. This is the iOS design language (Control Center, widgets). SwiftUI `.ultraThinMaterial` or equivalent.

### 3.8 Dynamic Gradient Background
The background is NOT static. It's a slowly-shifting gradient that responds to the dominant flood color:
- At game start: neutral dark gradient (dark navy to charcoal)
- As the flood grows: background subtly shifts to match the flood color (deeply desaturated, dark)
- At 80%+ flood: background is clearly tinted, creating an immersive "inside the color" feeling
- Transition: 0.5s animated shift when the dominant color changes

### 3.9 Ambient Floating Particles
Tiny, barely-visible sparkle particles drift slowly across the background — like dust motes in a sunbeam. Low birth rate (~3-5 per second), slow movement, fade in and out. Color-matched to dominant board color. Single `SKEmitterNode`. Adds depth and life without distraction.

### 3.10 Flooded Region Breathing Animation
Cells in the player's flood region have a gentle idle animation — a slow, continuous 2% scale oscillation (1.0 → 1.02 → 1.0, 3-second cycle). Unconquered cells remain static. This makes the flooded region feel like a living organism, and creates a subconscious visual contrast that drives the desire to flood more.

### 3.11 Color Buttons as Floating Orbs
The 5 color buttons are NOT flat circles. They are **glowing orbs** — spheres with:
- Radial gradient (lighter center, darker edge)
- Outer glow halo (color-matched, soft blur)
- Drop shadow beneath (floating above the UI)
- Active/selected orb pulses gently (1.0 → 1.05 → 1.0, 1.5s cycle)
- Tap state: squish + bounce as defined in Section 4.1

---

## 4. Touch Interaction & Feedback

### 4.1 Tapping a Color Button
The color buttons at the bottom are circular and also use the 3D raised style.

**On tap — 4-phase response:**
1. **Press** (0–80ms): Button scales down to 0.88x. Shadow shrinks. The "depth" visually compresses, like a physical button being pushed.
2. **Color broadcast** (80ms): The flood region begins changing color. The button holds the pressed state.
3. **Release bounce** (80–160ms): Button springs back to 1.0x with a slight overshoot to 1.05x, then settles. Spring animation, not linear.
4. **Haptic** (at 80ms): Light impact haptic fires (`UIImpactFeedbackGenerator` style `.light`). Not intrusive, just confirmation.

### 4.2 Tapping an Already-Active Color
If the player taps the color already flooding, nothing happens gameplay-wise. The button does the press/release animation anyway (it's satisfying), and a gentle "dull" haptic fires (`UIImpactFeedbackGenerator` style `.soft`).

### 4.3 Cell Touch Highlighting (Idle Board)
When the player's finger **rests on the board** (not the color buttons), the cell under their finger:
- Brightens slightly (brightness +15%)
- Shows a pulsing white ring around its edge (subtle, like a selection indicator)
- Adjacent cells dim slightly to 85% brightness, creating a "focus" halo effect

This makes the board feel responsive even when browsing, not just when tapping.

---

## 5. Animations

### 5.1 The Flood Spread Animation
This is the hero animation of the game. It must feel like **liquid spreading through a maze**, not like instant fill.

**How it works technically:**
The flood algorithm (BFS from the flood region boundary) already computes which cells will be absorbed in this move and in what order (by distance from the current boundary). This order is used to stagger the animation.

**Animation sequence:**
1. The player taps. The color buttons flash.
2. The flood region immediately changes to the new color (the owned cells).
3. Newly absorbed cells animate in **waves**: cells at distance 1 from the flood boundary animate first, then distance 2, then distance 3, etc. Each wave is offset by ~30ms.
4. Each newly absorbed cell does a **pop-in**: it scales from 0.85x to 1.05x to 1.0x (spring bounce) while simultaneously transitioning its color from old to new via a cross-fade.
5. A subtle **ripple ring** radiates outward from the flood boundary as each wave fires — like a water ripple emanating from the flood edge.
6. If a large cluster is absorbed (5+ cells), a brief **particle burst** fires from the cluster center: 8–12 small sparkle dots scatter and fade in the new color.

Total animation duration: 0.3–0.6 seconds depending on how many cells are absorbed. The player can already be thinking about their next move while this plays.

### 5.2 Move Counter Tick
Each time a move is made, the move counter:
- Briefly scales up to 1.2x, then snaps back to 1.0x
- Flashes white for 80ms
- Color transitions to orange when ≤5 moves remain, and red when ≤2 moves remain (with a more aggressive pulse)

### 5.3 The "Last Cluster" Moment
When the player makes a move that will clear the board in one sweep — even before the animation plays — the game **detects** this is the winning move. A special sequence fires:

1. A half-second **pause** before the flood fills.
2. The entire board dims to 60% brightness.
3. Then the flood rips across the entire remaining board with a fast wave — cells absorbing in rapid BFS order, no stagger. It feels like a dam breaking.
4. Immediately transitions into the Completion Rush.

This pause-then-rush creates the "oh... OH!" moment that makes the game feel good.

### 5.4 Completion Rush (Win Sequence)
The winning state is the most important UX moment in the game. It must feel **euphoric**.

**Full sequence (total ~2.5 seconds):**

**Phase 1 — Board pulse (0–400ms):**  
All cells on the board simultaneously pulse to 1.15x scale and back. The entire board "breathes" once, like it's proud of itself. A soft chime plays.

**Phase 2 — Color wave (400–900ms):**  
A shimmer wave sweeps across the board from top-left to bottom-right. Each cell briefly lightens to near-white and then returns to the flood color. It looks like a light is being swept across the surface.

**Phase 3 — Burst (900ms):**  
The board background flashes white (20ms), then a confetti explosion erupts from behind the board. 60–80 confetti pieces in all 5 game colors shoot upward and arc outward under simulated gravity, rotating as they fall. SpriteKit's `SKEmitterNode` handles this natively.

**Phase 4 — Score card (1200ms):**  
A frosted glass card slides up from the bottom of the screen with a spring animation. Shows:
- "Solved! ✓" in large bold text
- Moves used / moves allowed (e.g., "14 / 22")
- Star rating (1–3 stars based on efficiency)
- Best score for this board (if replaying)
- "Next" button (primary) and "Replay" button (secondary)

The stars animate in one by one with a pop effect and a chime note each (do, mi, sol).

### 5.5 Lose Sequence
Intentionally less dramatic — failure should feel calm, not punishing:
1. All non-flooded cells fade to 40% opacity and desaturate slightly.
2. The board gently shakes horizontally (3 cycles, 4px amplitude, 300ms total).
3. A simple overlay slides in: "Out of moves" in medium text, with "Try Again" and "Quit" buttons.
4. Haptic: `UINotificationFeedbackGenerator` style `.error` (the standard iOS error buzz).

---

## 6. Game Modes

### 6.1 Classic
Standard 9×9 grid. Fixed move budget per level. 500+ hand-seeded levels organized into difficulty packs:
- **Splash** (levels 1–50): Easy. 9×9. Generous moves. Great for onboarding.
- **Current** (51–150): Medium. 9×9. Moderate moves.
- **Torrent** (151–300): Hard. 12×12. Tighter moves.
- **Tsunami** (301–500): Expert. 15×15. Minimum viable moves.

### 6.2 Daily Challenge
One puzzle per day, same for all players worldwide. Share your result as a score card image (moves used, time, star rating). This is the social/viral loop. New puzzle unlocks at midnight local time.

### 6.3 Endless / Zen Mode
No move limit. Procedurally generated boards. Play at your own pace. No win/lose — just the satisfaction of completing the board. Good for relaxation. Monetized differently (see Section 8).

---

## 7. Difficulty Progression Design

### 7.1 Board Complexity Factors
For any given grid size, difficulty is controlled by:
1. **Move budget** — fewer allowed moves = harder
2. **Color count** — 5 colors is standard; 6 colors (harder to strategize)
3. **Cluster distribution** — many small scattered clusters = harder than a few large blobs
4. **Board size** — larger boards have longer chains of dependency

### 7.2 Level Generation
Levels are pre-solved by a solver algorithm that finds the optimal (minimum-move) solution. The allowed move budget is then set to:
- Easy: optimal + 8 moves
- Medium: optimal + 4 moves
- Hard: optimal + 2 moves
- Expert: optimal + 0 or 1 move

This ensures every level is always solvable, while hard levels require near-perfect play.

---

## 8. Monetization

**Free to play, with tasteful monetization:**

| Feature | Free | Paid |
|---|---|---|
| Classic levels 1–50 | ✓ | ✓ |
| Classic levels 51+ | — | ✓ unlock via IAP or ads |
| Daily Challenge | ✓ | ✓ |
| Hints (show best next move) | 3 free/day | Unlimited |
| Undo last move | 3 free/day | Unlimited |
| Zen Mode | ✓ (limited) | Unlimited |
| Remove ads | — | $2.99 IAP |
| Color themes (premium palettes) | 2 free | 8 premium packs |

**Ad format:** Interstitial between level packs (not between every level). Rewarded video for extra hints. No banners — they cheapen the aesthetic.

---

## 9. Technical Stack

| Layer | Technology |
|---|---|
| Game board & animations | SpriteKit |
| UI chrome (menus, overlays, settings) | SwiftUI |
| Persistence (scores, unlocks) | Swift Data (local) |
| Daily Challenge sync | Firebase Firestore |
| Analytics | Firebase Analytics |
| Ads | Google AdMob |
| Haptics | UIKit `UIImpactFeedbackGenerator` |
| Particles | SpriteKit `SKEmitterNode` |

### Why SpriteKit over SwiftUI for the board?
SwiftUI's animation system is not designed for per-cell BFS-wave animations with staggered timing on 81–225 cells simultaneously. SpriteKit gives direct control over per-node animation timing, particle systems, and render loop, which is exactly what the flood spread animation requires.

---

## 10. Screens & Navigation

```
Splash Screen (logo + loading)
    ↓
Home Screen
    ├── Play (→ Level Select)
    │       ├── Classic Packs (Splash / Current / Torrent / Tsunami)
    │       ├── Daily Challenge
    │       └── Zen Mode
    ├── Settings
    │       ├── Sound on/off
    │       ├── Haptics on/off
    │       ├── Color theme
    │       └── Restore purchases
    └── Stats
            ├── Levels completed
            ├── Best scores
            └── Daily challenge streak
```

**Game Screen layout (portrait):**
- Top bar: level name, move counter, settings icon
- Board: centered, square, fills most of the screen
- Bottom: 5 color buttons + undo button

---

## 11. MVP Scope (v1.0)

For the first shipped version, scope down to:
- Classic mode only (levels 1–100)
- 9×9 board only
- 5 colors
- Full animation system (this is non-negotiable — it's the product)
- Basic monetization: ads + "Remove Ads" IAP
- No Daily Challenge, no Zen Mode (v1.1)
- No social sharing (v1.1)

**Estimated build time with Claude Code:** 3–4 weeks for a polished v1.0.

---

## 12. What Makes This Version Different

Every Flood It clone on the App Store is a flat, lifeless grid. Ours differentiates on:
1. **The 3D raised cell aesthetic** — nobody has done this well on iOS
2. **The flood spread animation** — liquid ripple, not instant fill
3. **The Completion Rush** — the win moment is a proper celebration
4. **Haptics** — every touch has physical feedback
5. **The "last cluster" pause** — the dam-break moment is intentionally designed

The game itself is old. The experience is new.

---

## 13. Sound Design — The Invisible 50%

Sound is not optional. It's the difference between "that was fine" and "I can't stop playing." Every great casual game has a sound identity that lives in your head.

### 13.1 The Sonic Palette
The game's sound should feel like **water + glass + chimes**. Organic, clean, musical. NOT 8-bit. NOT cartoon. Think: a xylophone played underwater.

### 13.2 Core Sounds

**Cell absorption (flood spread):**  
Each cell that gets absorbed plays a very short pitched tone — a soft "plip" like a water droplet hitting glass. The pitch **rises with each wave** of the BFS flood. Wave 1 = C4, Wave 2 = D4, Wave 3 = E4, Wave 4 = F4, etc. This means a big flood creates an ascending musical scale — the bigger the capture, the more musical and satisfying it sounds. Players won't consciously notice this, but it feels incredible. The ascending pitch creates an emotional arc: it literally sounds like things are getting better.

**Color button tap:**  
A clean, muted click — like a mechanical keyboard switch but softer. Slightly different timbre per color (warmer click for Coral, crisper for Sapphire). This subconsciously teaches players to associate colors with sounds.

**Large cluster absorption (5+ cells):**  
The ascending "plip" scale, but with a richer reverb tail and a subtle chord swell underneath. A quick, breathy "whoooosh" pans across from where the cluster was to the flood center.

**The "Last Cluster" dam break:**  
Dead silence for the 500ms pause. Then: a low rumble that builds rapidly (0.5s), followed by a cascading waterfall of plip tones in rapid-fire (no musical scale, just a torrent of sound), ending with a satisfying deep "boom" that has reverb tail. This is the hero sound moment.

**Completion Rush:**  
Phase 1 (board pulse): A warm major chord swell — C major — held for 400ms.  
Phase 2 (shimmer wave): A delicate arpeggio runs up (C-E-G-C5-E5) as the light sweeps.  
Phase 3 (confetti): A bright, joyful "sparkle burst" — think the Mario coin sound but more organic. Then a gentle rain of tiny sparkle tones as confetti falls.  
Phase 4 (score card): Each star plays an ascending chime (do, mi, sol). 3 stars plays the full triad and adds a subtle crowd-cheer sample (1s, low in mix).

**Lose sequence:**  
A single, soft, descending tone. Not harsh — melancholic but gentle. Like a sigh, not a buzzer.

**Menu navigation:**  
Soft taps. Each menu item makes a very quiet tonal click on hover/selection. The home screen has a gentle ambient background — a slowly evolving pad with occasional water droplet sounds. Creates mood immediately.

### 13.3 Dynamic Music Layer
The game doesn't have a "soundtrack" in the traditional sense. Instead, it has an **adaptive ambient bed** that responds to game state:

- **Board mostly empty (start):** Very quiet, sparse ambient pad. A few notes every few seconds.
- **Board 30-60% flooded:** More musical elements layer in — a gentle rhythmic pulse, occasional melodic fragments.
- **Board 60-90% flooded:** Fuller sound. The ambient becomes warmer, more hopeful. The player subconsciously feels momentum.
- **Board 90%+ flooded (almost winning):** The ambient swells slightly, creating tension. Higher register. The player feels "I'm so close."
- **Zen Mode:** A separate, continuous ambient track — lo-fi, warm, no urgency. Think spa music with character.

This adaptive audio makes the game feel alive. Players will play with sound on because it enhances the experience, not despite the soundtrack.

---

## 14. The Addiction Framework — Why Players Come Back

This is the most critical section. Beautiful visuals and satisfying animations get players to play once. The following systems get them to play 100 times.

### 14.1 The "Just One More" Transition
The gap between levels must be **frictionless**. When the score card appears after a win:
- The "Next" button is the biggest, most prominent UI element
- Tapping "Next" immediately begins loading the next board behind a 600ms transition (board tiles scatter/shuffle to reveal the new layout)
- There is ZERO loading screen, ZERO menu navigation between levels
- The player's thumb never has to move — "Next" is always in the same position

The average session should be 8–12 levels. If we achieve this, retention is solved.

### 14.2 The Streak System
- A running counter of consecutive days the player has completed at least one level
- Displayed prominently on the home screen as a flame icon + number
- Losing a streak after 7+ days triggers a "Streak Shield" offer: watch a rewarded ad to protect the streak
- At streak milestones (7, 14, 30, 60, 100 days), the player unlocks a cosmetic reward (color theme, board style)

This mechanic single-handedly drives daily retention. It works for Duolingo, Wordle, Snapchat — it works for us.

### 14.3 The Combo System
This is NEW — no Flood It clone has this.

**How it works:**  
If the player makes 3 consecutive "efficient" moves (moves that absorb 4+ cells each), a **combo counter** activates:

- **Combo ×2:** A golden glow appears around the flood boundary. The absorption sound gains a reverb boost. Score multiplier ×2 (score is used for leaderboards/stars).
- **Combo ×3:** The glow intensifies. Particles trail behind the flood edge like sparks. Sound adds a subtle bass throb. ×3 multiplier.
- **Combo ×4+:** The entire board's color saturation increases. The flood spread speed increases by 20%. A faint screen shake on each absorption wave. ×4+ multiplier. The player feels powerful.

**Breaking a combo:** If a move absorbs fewer than 4 cells, the combo resets. The golden glow fades with a soft "tink" sound. No punishment — it just stops.

**Why this works:** It gives skilled players a reason to think strategically about move ORDER, not just which color to pick. It adds a layer of depth without adding complexity. And the escalating visual/audio feedback creates a "power fantasy" moment that players chase.

### 14.4 Star Rating System
Every level awards 1–3 stars based on efficiency:
- ★ (Bronze): Solved within move budget
- ★★ (Silver): Solved within optimal + 3 moves
- ★★★ (Gold): Solved within optimal + 1 move or fewer

Stars are the primary progression currency. They unlock new level packs:
- Splash pack: Free
- Current pack: Requires 50 stars
- Torrent pack: Requires 150 stars
- Tsunami pack: Requires 350 stars

This creates a natural reason to replay old levels for better scores — the player WANTS 3 stars to unlock the next pack.

### 14.5 The "Almost!" Mechanic
When the player loses with ≤2 cells remaining (SO close!), a special lose screen appears:
- "SO CLOSE! Just 2 cells left!"
- The remaining unconquered cells pulse/glow red, taunting
- An offer: "Watch an ad for +3 moves" (rewarded video)
- This converts at extremely high rates because the loss aversion is maximal

### 14.6 The Daily Challenge & Social Loop
(Moved from v1.1 to v1.0 — this is too important for retention to defer)

**Daily Challenge:**
- One board per day, same for all players worldwide
- After completing, player sees a **share card** that shows:
  - "Flood It Daily #47"
  - Moves used / max allowed
  - Star rating
  - A small visual representation of their flood path (a 5×5 mini-grid showing color order)
- Share to iMessage, WhatsApp, Instagram Stories
- This is the Wordle-like viral loop

**Weekly Leaderboard:**
- Anonymous, aggregated — shows the player's rank among all daily challenge players
- "You did better than 73% of players today"
- No accounts needed — uses a device fingerprint for the leaderboard

### 14.7 Unlockable Color Themes
Color themes are cosmetic — they change the 5 gradient pairs used in the game. They're the primary reward currency.

Themes unlock via:
- Star milestones (50, 100, 200 stars)
- Streak milestones (7, 14, 30 days)
- Completing packs
- One-time IAP

Example themes:
- **Ocean** (teals, blues, foam whites)
- **Sunset** (oranges, pinks, deep purples)
- **Neon** (electric pink, cyan, lime, hot yellow, bright purple)
- **Earth** (terracotta, olive, sand, clay, deep brown)
- **Monochrome** (5 shades of grey — surprisingly satisfying)
- **Candy** (pastel pink, mint, lavender, peach, baby blue)
- **Diwali** (gold, saffron, deep red, royal blue, emerald — festive, premium feel)

Each theme also subtly changes the board background and the particle colors during animations. This makes each theme feel like a different experience, not just a reskin.

---

## 15. Onboarding — The First 60 Seconds

The first experience must be perfect. No tutorial screens. No text walls. Learn by doing.

**Level 1 (3×3 board, 3 colors, very generous moves):**  
The board appears. No instructions. The 3 color buttons at the bottom gently pulse. When the player taps any color, the flood happens with FULL animation and sound. The game teaches itself — "oh, I tap a color and it spreads."

**Level 2 (4×4 board, 3 colors):**  
Slightly bigger. Player naturally gets it.

**Level 3 (5×5 board, 4 colors):**  
A new color appears — it briefly glows to draw attention.

**Level 4 (7×7 board, 4 colors):**  
First real challenge. Move limit introduced with a subtle "13 moves left" counter that wasn't visible before. It just appears — no explanation needed.

**Level 5 (9×9 board, 5 colors):**  
Full game. All 5 colors. This is the standard experience from here on.

**Key principle:** The onboarding IS the first 5 levels. There are zero pop-ups, zero "Got it!" buttons, zero tutorial overlays. Everything is discoverable through play. The only text that appears is the level number and the move counter. Respect the player's intelligence.

---

## 16. The Board Background — Not Just a Color

The board sits on a background that is NOT static. It's a **living gradient** that responds to game state:

- At game start: A neutral dark gradient (dark navy to charcoal)
- As the flood grows: The background slowly shifts to match the flood color, but deeply desaturated and dark. If you're flooding blue, the background becomes a very deep, dark blue.
- At 80%+ flood: The background is clearly tinted in the flood color, creating an immersive feeling of being "inside" the color.
- On win: The background brightens dramatically during the Completion Rush — the whole screen becomes the flood color for a moment before settling.

This subtle effect makes the game feel more alive and immersive than any static background could.

---

## 17. Revised MVP Scope (v1.0)

After deep review, the MVP must include more than originally planned. The addiction loop IS the product.

**v1.0 (Must-have):**
- Classic mode: levels 1–100 (9×9 board only)
- Full animation system (flood spread, completion rush, last cluster moment)
- Full sound design (adaptive audio, cell absorption tones, all SFX)
- Haptics on all interactions
- Combo system
- Star rating (1–3 stars per level)
- Streak system (daily flame counter)
- Daily Challenge (1 board/day, share card)
- 3 color themes (default + 2 unlockable)
- Onboarding levels 1–5 (no tutorial screens)
- Ads (interstitial between packs, rewarded for hints/undo)
- "Remove Ads" IAP ($2.99)
- Living background gradient

**v1.1 (Fast follow, 2 weeks after launch):**
- Zen Mode
- 5 more color themes
- Weekly leaderboard
- Level packs 2–4 (Current, Torrent, Tsunami)
- 12×12 and 15×15 boards

**v2.0 (Major update):**
- Board editor (create and share custom boards)
- Social features (friend challenges)
- Seasonal events (Diwali theme, Christmas theme)
- Apple Watch complication (show daily challenge status)

**Estimated build time for revised v1.0:** 4–5 weeks with Claude Code. The sound design and combo system add ~1 week over the original estimate, but they're the difference between a forgettable game and one people talk about.

---

## 18. The Emotional Arc of a Session

This is the design intent for how a player should FEEL during a 10-minute session:

1. **Opening the app** → Warm, inviting ambient sound. The flame streak greets them. "Day 23 🔥". They feel: I'm a person who plays this every day.

2. **Starting a level** → The board appears. Colorful but orderly. They feel: This is manageable. I can do this.

3. **First few moves** → Cells absorb. The ascending plip tones play. They feel: Satisfying. I'm making progress.

4. **Mid-game** → Board is 40-60% flooded. Combo builds. Golden glow. They feel: I'm in the zone. I'm good at this.

5. **Late game (tight moves)** → Move counter turns orange. Ambient swells. They feel: Tension. Can I make it?

6. **The last cluster moment** → Pause. Dim. Dam break. They feel: RUSH. Pure dopamine.

7. **Completion Rush** → Confetti, chimes, stars. They feel: Euphoria. I'm awesome.

8. **Score card** → "Next" button stares at them. They feel: Just one more.

This arc repeats. Each level is a 60-90 second micro-story with a beginning, middle, tension, and climax. That's what makes it addictive — not the puzzle mechanics, but the emotional rhythm.
