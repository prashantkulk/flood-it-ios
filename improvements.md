# UX Improvements — Phase 20 QA Review

## Summary
- **Total found:** 8
- **Total implemented:** 5
- **Deferred:** 3

---

### IMP-1: No back button on GameView [MEDIUM]
**Description:** GameView has no explicit back/close button. Players can only leave via the system back gesture or by quitting from the lose/win card. During active gameplay, there's no way to return to level select without restarting.
**Fix:** Added a back chevron button in the top bar, left of the moves counter.
**Status:** DONE

### IMP-2: Settings dismiss via tap-outside inconsistent with Done button [LOW]
**Description:** The settings overlay can be dismissed by tapping outside OR pressing Done. Both are fine, but the tap-outside dismiss doesn't animate cleanly if the user taps rapidly.
**Fix:** Minor — acceptable as-is.
**Status:** DEFERRED

### IMP-3: Color buttons remain active during win/lose animations [LOW]
**Description:** While the win or lose animation plays (before the card appears), color buttons are still tappable. Tapping during animation could trigger another flood move, though `gameStatus` check in `performFlood` prevents state mutation after game ends.
**Fix:** Added `.disabled(gameState.gameStatus != .playing || isWinningMove)` to each color button.
**Status:** DONE

### IMP-4: No level number shown during gameplay [LOW]
**Description:** During gameplay, there's no indication of which level the player is on. They see moves, score, and buttons, but not "Level 42".
**Fix:** Added a subtle "Lv. N" label in the top bar between moves counter and score.
**Status:** DONE

### IMP-5: Win card "Next" button goes past level 100 [LOW]
**Description:** On level 100 (the final level), the win card shows "Next" button which calls `advanceToNextLevel()`. This correctly handles `nil` from `LevelStore.level(101)` by dismissing, but showing "Next" when there's no next level is confusing UX.
**Fix:** Changed to three-way branch: daily challenge → Share/Done, has next level → Next/Replay, final level → Done/Replay.
**Status:** DONE

### IMP-6: Daily challenge board regenerated on each DailyChallengeEntryView init [LOW]
**Description:** `DailyChallenge.moveBudget(for:)` calls `generateBoard()` then `solveMoveCount()`, which is expensive. It's called during DailyChallengeEntryView init AND again in GameView init. The board is generated twice.
**Fix:** Cache the daily challenge board/budget or pass them through.
**Status:** DEFERRED

### IMP-7: Haptic feedback generators created as stored properties [LOW]
**Description:** `GameView` creates 5 `UIImpactFeedbackGenerator` instances as stored properties. These should be created once and reused, which they are, but `prepare()` is never called. Calling `prepare()` before `impactOccurred()` reduces latency.
**Fix:** Added `.prepare()` calls for all 5 haptic generators in the view's `onAppear`.
**Status:** DONE

### IMP-8: Missing accessibility labels on game elements [LOW]
**Description:** While accessibility identifiers are present for UI testing, there are no accessibility labels or hints for VoiceOver users. Color buttons, moves counter, and score are not labeled for screen readers.
**Fix:** Add `.accessibilityLabel()` to key interactive elements.
**Status:** DEFERRED
