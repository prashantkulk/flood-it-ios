# Bugs Found — Phase 20 QA Review

## Summary
- **Total found:** 6
- **Total fixed:** 0
- **Remaining:** 6

---

### BUG-1: Level transition drops obstacle config [HIGH]
**File:** `GameView.swift` — `performLevelTransition(to:data:)`
**Description:** When advancing to the next level, the new board is generated using `FloodBoard.generateBoard(size:colors:seed:)` which ignores the level's `obstacleConfig`. This means levels 21+ lose all stones, ice, countdowns, walls, portals, bonus tiles, and shaped boards during level transitions. Only `resetGame()` correctly uses `FloodBoard.generateBoard(from: data)`.
**Impact:** All obstacles disappear when pressing "Next" after winning. Players who replay the level see obstacles, but advancing shows a plain board.
**Fix:** Replace manual board generation with `FloodBoard.generateBoard(from: data)`.
**Status:** UNFIXED

### BUG-2: floodCompletionPercentage ignores non-playable cells [MEDIUM]
**File:** `GameState.swift:134-137`
**Description:** `floodCompletionPercentage` divides flood region count by `gridSize * gridSize`, but shaped boards with voids/stones have fewer playable cells. On a 9x9 donut board with ~24 voids, the maximum achievable percentage is ~70%, making the near-miss lose screen ("75%+ complete") unreachable and misleading progress display.
**Impact:** Lose screen progress bar never shows high completion on shaped boards. Percentage shown to player is inaccurate.
**Fix:** Count only playable (non-void, non-stone) cells as the denominator.
**Status:** UNFIXED

### BUG-3: unfloodedCellCount ignores non-playable cells [MEDIUM]
**File:** `GameState.swift:128-131`
**Description:** `unfloodedCellCount` returns `gridSize * gridSize - floodRegion.count`, counting voids and stones as "unflooded". On shaped boards, the "Almost!" mechanic (≤2 unflooded cells) can never trigger because voids inflate the count.
**Impact:** "SO CLOSE!" lose card variant never appears on boards with voids/stones. Players miss the extra-moves prompt even when genuinely close.
**Fix:** Subtract non-playable cells from the total.
**Status:** UNFIXED

### BUG-4: SoundManager ambient render thread race condition [LOW]
**File:** `SoundManager.swift:443-469`
**Description:** The `AVAudioSourceNode` render callback runs on the audio render thread but reads/writes `ambientEnabled`, `ambientTargetVolume`, `ambientVolume`, and `ambientPhases` without synchronization. These properties can be modified from the main thread via `setAmbientEnabled()` or `updateAmbientVolume()`.
**Impact:** Potential audio glitches or crackling during volume transitions. Very unlikely to crash but technically a data race.
**Fix:** Use `OSAtomicAdd` or make the shared properties atomic, or copy values at the start of each render cycle.
**Status:** UNFIXED

### BUG-5: StoreManager transaction listener uses unverified payload [LOW]
**File:** `StoreManager.swift:114`
**Description:** `listenForTransactions()` uses `result.payloadValue` which returns the transaction payload without signature verification. The `checkVerified()` helper exists but isn't used here. A manipulated transaction could bypass verification.
**Impact:** Minor security concern. In practice, on-device StoreKit verification is a best-effort measure — server-side verification is the real safeguard.
**Fix:** Use `try? checkVerified(result)` instead of `result.payloadValue`.
**Status:** UNFIXED

### BUG-6: Combo thresholds off-by-one vs UI feedback [LOW]
**File:** `GameView.swift:753,799` vs `GameState.swift:100-107`
**Description:** Combo glow and audio trigger at `comboCount >= 3`, but `comboCount` uses 1-based counting (first big absorption = 1). The combo multiplier activates at `comboCount >= 2`. This means players get a score multiplier at 2 consecutive absorptions but no visual feedback until 3. The gap between mechanical benefit and visual feedback could confuse players.
**Impact:** Players don't see combo visuals for their first multiplied combo. Not a crash, but inconsistent feedback.
**Fix:** Show combo glow at `comboCount >= 2` to match when the multiplier activates.
**Status:** UNFIXED
