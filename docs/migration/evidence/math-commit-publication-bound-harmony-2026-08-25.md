# Evidence: Math commit publication bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- Both Math insert and LaTeX-update continuations already returned after a stale page, preserving the durable commit.
- The stale return happened only before in-memory publication; the code still called `undoRedo.push(...)` on the disposed view instance and later invoked global `notifyUndoRedo()`.
- Photo insert was reviewed as an adjacent candidate; its existing stale guard already preceded both history push and notification.

## Change

- Construct the post-commit Math undo action only after `isHistoryPageContextCurrent()` passes.
- Move `notifyUndoRedo()` inside the same current-page branch so no stale success can publish undo state.
- Preserve existing editor cleanup, durable history, failure logging, busy cleanup, and active-page behavior.

## Verification

- Focused replay: docs/migration/replays/d02-math-commit-publication-bound.mjs (8/8).
- Strengthened adjacent replay: d02-original-math-commit-stale-bound.mjs (8/8).
- Full Desktop Replay: REPLAY_FILES=358 PASSED=358 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 13.529 seconds; default in 51.508 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
