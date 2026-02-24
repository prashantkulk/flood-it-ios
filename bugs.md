# Bugs Found — Phase 20 QA Review

## Summary
- **Total found:** 20
- **Total fixed:** 19 (BUG-1 through BUG-20, excluding BUG-16 which is a design decision)
- **Remaining open ideas:** BUG-16 (daily combo scoring)

---

### BUG-1: Level transition drops obstacle config [HIGH]
**File:** `GameView.swift` — `performLevelTransition(to:data:)`
**Description:** When advancing to the next level, the new board is generated using `FloodBoard.generateBoard(size:colors:seed:)` which ignores the level's `obstacleConfig`. This means levels 21+ lose all stones, ice, countdowns, walls, portals, bonus tiles, and shaped boards during level transitions. Only `resetGame()` correctly uses `FloodBoard.generateBoard(from: data)`.
**Impact:** All obstacles disappear when pressing "Next" after winning. Players who replay the level see obstacles, but advancing shows a plain board.
**Fix:** Replace manual board generation with `FloodBoard.generateBoard(from: data)`.
**Status:** FIXED

### BUG-2: floodCompletionPercentage ignores non-playable cells [MEDIUM]
**File:** `GameState.swift:134-137`
**Description:** `floodCompletionPercentage` divides flood region count by `gridSize * gridSize`, but shaped boards with voids/stones have fewer playable cells. On a 9x9 donut board with ~24 voids, the maximum achievable percentage is ~70%, making the near-miss lose screen ("75%+ complete") unreachable and misleading progress display.
**Impact:** Lose screen progress bar never shows high completion on shaped boards. Percentage shown to player is inaccurate.
**Fix:** Added `playableCellCount` computed property to `FloodBoard`. Both `floodCompletionPercentage` and `unfloodedCellCount` now use it as the denominator.
**Status:** FIXED

### BUG-3: unfloodedCellCount ignores non-playable cells [MEDIUM]
**File:** `GameState.swift:128-131`
**Description:** `unfloodedCellCount` returns `gridSize * gridSize - floodRegion.count`, counting voids and stones as "unflooded". On shaped boards, the "Almost!" mechanic (≤2 unflooded cells) can never trigger because voids inflate the count.
**Impact:** "SO CLOSE!" lose card variant never appears on boards with voids/stones. Players miss the extra-moves prompt even when genuinely close.
**Fix:** Uses `board.playableCellCount` instead of `gridSize * gridSize`.
**Status:** FIXED

### BUG-4: SoundManager ambient render thread race condition [LOW]
**File:** `SoundManager.swift:443-469`
**Description:** The `AVAudioSourceNode` render callback runs on the audio render thread but reads/writes `ambientEnabled`, `ambientTargetVolume`, `ambientVolume`, and `ambientPhases` without synchronization. These properties can be modified from the main thread via `setAmbientEnabled()` or `updateAmbientVolume()`.
**Impact:** Potential audio glitches or crackling during volume transitions. Very unlikely to crash but technically a data race.
**Fix:** Copy shared properties (`ambientEnabled`, `ambientTargetVolume`, `sampleRate`) at the start of each render cycle to minimize read window.
**Status:** FIXED

### BUG-5: StoreManager transaction listener uses unverified payload [LOW]
**File:** `StoreManager.swift:114`
**Description:** `listenForTransactions()` uses `result.payloadValue` which returns the transaction payload without signature verification. The `checkVerified()` helper exists but isn't used here. A manipulated transaction could bypass verification.
**Impact:** Minor security concern. In practice, on-device StoreKit verification is a best-effort measure — server-side verification is the real safeguard.
**Fix:** Changed to `guard case .verified(let transaction) = result` pattern matching for inline verification.
**Status:** FIXED

### BUG-7: App crashes when advancing to next level [CRITICAL]
**Description:** App crashes when tapping "Next" to move to the next level after winning.
**Status:** FIXED — Added `cancelLevelAnimations()` to GameScene; resets all stale animation callbacks on level transition.

### BUG-8: All levels are accessible without progression — level select needs complete redesign [HIGH]
**Description:** Users can jump to any level (e.g., level 49) without playing level 1. There's no linear progression enforcement. The level select screen is bland and shouldn't exist as a free-choice grid — users shouldn't have the option to choose levels at all. Progression should be linear (complete level N to unlock level N+1).
**Status:** FIXED — Removed level select screen; HomeView now shows "Continue Level N" that launches GameView directly. ProgressStore.currentLevel tracks progress in UserDefaults.

### BUG-9: Daily challenge UI elements overlap game area [HIGH]
**Description:** In daily challenge mode, the moves counter, hint bulb, settings icon, and other HUD elements overlap onto the game board area. Layout is broken.
**Status:** FIXED — Replaced hardcoded 56pt top padding with safe-area-respecting layout; added styled capsule date header above the HUD row.

### BUG-10: Home screen is ugly — plain black with white text, needs complete redesign [HIGH]
**Description:** Home screen is just black background with white font. Looks terrible and uninviting. Needs a complete visual overhaul — should be beautiful and appealing with 3D components, rich visuals, animations, and a modern premium UI experience that matches the quality of the game board itself.
**Status:** FIXED — Complete HomeView rewrite: animated dark navy gradient, 18 floating color particles, glow title with dual-layer shadow, gradient card "Level N" button with pulse, streak flame badge.

### BUG-11: Undo and hint (bulb) buttons are broken and confusing [MEDIUM]
**Description:** Undo and bulb (hint) buttons don't work when tapped. Undo should be removed entirely — not needed. The bulb icon is not intuitive at all; users have no idea what it does. If hint functionality is kept, it needs a clearer icon/label, but the button must actually work first.
**Status:** FIXED — Removed undo entirely; hint uses `questionmark.circle.fill` icon with count badge (3 hints/level), works without ad gate, pulses gold for 2s.

### BUG-13: Obstacle cells (black grid) are confusing and unappealing [HIGH]
**Description:** Some levels show a black grid which appears to be an obstacle (void/stone cells). This is extremely confusing — there's no visual cue explaining what it is or how it affects gameplay. Obstacles need to be visually appealing, intuitive, and self-explanatory. Players should immediately understand what an obstacle does just by looking at it, without any tutorial.
**Status:** FIXED — Stones get X mark (blocked), ice gets snowflake crystal lines, countdown gets urgency gradient + ⏱/💣 icon, portals get pulsing colored ring border, bonus tiles get 5-pointed star, voids show as dark recessed tile instead of invisible gap.

### BUG-16: Daily challenge needs time+moves combo scoring [MEDIUM]
**Description:** Daily challenge should combine time AND moves for a richer scoring system. Ideas:
- Give a time limit (e.g., 60s) plus move limit for daily challenge.
- **Time bonus scoring:** Finishing faster = more points. E.g., finish in 50s out of 60s → 10 bonus seconds × multiplier.
- Scoring formula could be: base score (cells/moves) + time bonus (seconds remaining × points) + combo bonuses.
- This makes daily challenge more competitive — two players who both solve it can still compare who was faster.
- Leaderboard becomes more meaningful when score reflects both efficiency (fewer moves) AND speed (less time).
- Creates urgency that the move-only system lacks.
**Status:** OPEN (idea — needs design decision)

### BUG-15: No time pressure — game lacks adrenaline rush [HIGH]
**Description:** Currently levels only have a move limit, which doesn't create urgency or adrenaline. Consider adding a time-based mode or timer alongside moves:
- **Timer mode:** Complete the level within 60s (or varying per level). Creates real-time pressure.
- **Urgency UI:** When time is low (e.g., ≤5 seconds), flash the screen edges red, pulse the timer, intensify background music, shake subtly — signal "HURRY UP" visually and audibly.
- **Adrenaline design:** The last 10 seconds should feel like a heart-pounding rush. Screen tints, heartbeat sound, timer grows larger and pulses red.
- This creates the competitive/anxious feeling that makes players' palms sweat and drives replays.
- Could be a separate "Blitz" mode or integrated into later levels as difficulty increases.
**Status:** FIXED — Timer added for levels 10+: levels 10-30→120s, 31-60→90s, 61-80→75s, 81-100→60s, daily→90s. HUD shows clock icon + countdown; orange at ≤15s, red+pulse at ≤5s; time-up triggers lose screen showing "Time's Up!".

### BUG-14: Levels are too easy — no real challenge or risk of losing [CRITICAL]
**Description:** Played several levels and kept winning every time. There's no sense of challenge or risk of losing. The game feels boring because there's no tension. Move budgets are too generous. Needs rethinking:
- Tighter move budgets so players actually lose and need to retry.
- Levels should have a narrow path to victory — one good strategy wins, but wrong early choices lead to losing.
- Players need to feel the tension of "can I solve this?" not just autopilot through every level.
- The difficulty curve needs real teeth — early levels can be easy for onboarding, but by level 10+ players should be losing sometimes.
**Status:** FIXED — Move budgets tightened: onboarding +5, easy 6-15 +3, easy-mid 16-20 +2, stones 21-30 +2, ice 31-40 +1, countdown/portal/wall 41-65 +1 (breathers +2), expert 66-100 +0 or +1.

### BUG-12: HUD (Moves, Lv, Score) looks outdated and unclear — needs complete revamp [HIGH]
**Description:** The top bar showing "Moves", "Lv", and score looks extremely plain and dated — like decades-old technology. "Moves" is not clear to users (moves remaining? moves made?). The whole in-game HUD needs a complete visual revamp. Proposed changes:
- **Level start:** Show a brief level intro splash with the level number and available moves (e.g., "Level 23 — 18 moves") before gameplay begins.
- **During gameplay:** Minimal, beautiful HUD — just moves remaining, shown clearly.
- **Level end:** Show score with crazy celebratory animations, not just static text.
- The current design is too plain for anyone to want to keep playing. Needs modern, polished, premium feel throughout.
**Status:** FIXED — Minimal 3-column HUD: back+level (left), move counter (center), score+hint+gear+restart (right). Level intro splash shows "Level N / N moves" with fade in/out. Hint uses question mark with gold pulse.

---

### BUG-6: Combo thresholds off-by-one vs UI feedback [LOW]
**File:** `GameView.swift:753,799` vs `GameState.swift:100-107`
**Description:** Combo glow and audio trigger at `comboCount >= 3`, but `comboCount` uses 1-based counting (first big absorption = 1). The combo multiplier activates at `comboCount >= 2`. This means players get a score multiplier at 2 consecutive absorptions but no visual feedback until 3. The gap between mechanical benefit and visual feedback could confuse players.
**Impact:** Players don't see combo visuals for their first multiplied combo. Not a crash, but inconsistent feedback.
**Fix:** Changed combo glow and audio thresholds from `>= 3` to `>= 2` to match score multiplier activation.
**Status:** FIXED

### BUG-17: Sound is terrible — flat, mono, dull, feels like 1930s [CRITICAL]
**Description:** All game sounds are flat and uninteresting. The synthesized audio sounds mono and lifeless. Needs a complete sound overhaul:
- Sounds need to feel 3D, rich, layered — not flat sine waves
- Multi-flood/cascade moments should sound EXCITING — escalating, dramatic, rewarding
- Level completion sound is bland and forgettable — needs to be a dopamine hit
- Take inspiration from Candy Crush Saga and other top-rated casual games for sound design
- Consider using pre-recorded high-quality sound samples instead of pure synthesis
- Every interaction should sound satisfying and premium
**Status:** FIXED — Added AVAudioUnitReverb (smallRoom, 18% wet) in signal chain. playPlip now layers sine + triangle + transient click. playWinChime upgraded to Cmaj7 (C4+E4+G4+B4) with harmonic body. playChordSwell uses full Cmaj7 + triangle. playArpeggio plays 7 rising notes (C4→G5) with harmonics. playConfettiSparkle plays 16 notes across C5–C7. playCascadeWhoosh escalates per round with noise+sine+triangle + bass stab at round 2+. playCascadeBassSwell adds triangle growl layer.

### BUG-18: Weird background ambient sound always playing — feels like a bug [HIGH]
**Description:** There's a constant background ambient sound that plays whenever the app is open. It sounds unintentional/buggy rather than atmospheric. Either fix it to sound intentional and pleasant, or remove it entirely. If keeping ambient audio, it should be subtle, beautiful, and clearly part of the game's atmosphere — not a droning noise.
**Status:** FIXED — Default disabled (ambientEnabled = false); max volume lowered to 0.15 (was 0.4); fixed buzzy AM by replacing `phases[idx] * modRate` (was ~10–20 Hz tremolo) with separate lfoPhases array advancing at 0.07–0.11 Hz (slow breathing); added one-pole low-pass filter (1200 Hz cutoff) for warmth; volume ramps per-sample to avoid zipper noise.

### BUG-19: Grid cells look 2D — need full 3D effect like Candy Crush Saga [HIGH]
**Description:** The board cells/squares look flat and 2D despite the layered rendering. They need a much more pronounced 3D effect:
- Look at Candy Crush Saga's grid — cells look like actual 3D candy pieces with depth, shine, and physicality
- Cells should have strong highlights, deep shadows, and feel like you could pick them up
- Add more dramatic lighting — glossier, shinier, more reflective
- Edge cells of the flood region should "jump" or bounce after a large flood (5+ cells) — like they're celebrating
- The overall board should look premium and modern, not flat
**Status:** FIXED — Highlight opacity 0.38→0.40, coverage narrowed to top 15% (was 35%) for crisper rim light. Body gradient uses 3-stop very-bright→light→dark (top boosted ×1.35) for steeper falloff. Shadow offset 2px→3px, alpha 0.7→0.75. Gloss dot radius ×0.09→×0.15 (≈10px), alpha 0.25→0.40. Edge cells of flood region bounce with scale 1.14→0.94→1.0 after 5+ cell floods (bounceFloodEdgeCells).

### BUG-20: Level completion celebration is weak — needs major improvement [HIGH]
**Description:** The end-of-level celebration (sweep/confetti) is underwhelming and boring. Needs to be a genuinely exciting moment:
- Study how Candy Crush Saga and similar top games celebrate level completion
- The celebration should make the user feel AMAZING — "I did it!"
- More dramatic visual effects: bigger confetti, screen-wide effects, color explosions
- The score reveal should feel like a slot machine jackpot
- Stars should have more weight and ceremony when they appear
- Consider fireworks, screen flash, dramatic pause before reveal
- This is THE moment that drives "just one more level" — it must be perfect
**Status:** FIXED — runCompletionRush now opens with 90% white flash + 300ms dramatic pause. Added completionRushStadiumWave (cells bounce outward from center at 40ms/ring). Confetti upgraded to 120–140 pieces (was 60–80) with 1-in-4 long ribbons, 3s lifetime, staggered launch wave. Added spawnFirework with 28–38 burst particles + ring flash; triggerFireworks() fires 5 fireworks at 350ms intervals for 3-star completions (called from GameView after last star chime).
