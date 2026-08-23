# Evidence: Original paste reservation disposal bound

Date: 2026-08-23 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- Function: `pasteClipboard()`
- Before: success checked only generation/page/loading state; catch always invoked `reportSaveFailure(e)`.
- `isHistoryPageContextCurrent()` already requires `lifecycleActive`, matching generation, loaded/current page ID, successful load, and no active reload/failure.

## Change

- Success now uses `!this.isHistoryPageContextCurrent(generation, pageId)` as its return guard.
- Failure publication and detailed current-context log are gated by the same predicate.
- Stale failures use an explicit stale log branch.
- `finally { this.historyBusy = false; }` remains outside context gating.

## Verification

- Focused replay: `docs/migration/replays/d02-original-paste-reservation-disposal-bound.mjs` -> `D02_ORIGINAL_PASTE_RESERVATION_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0`.
- No simulator, virtual machine, physical device, or Hypium execution.
- Full Desktop Replay: `REPLAY_FILES=307 PASSED=307 FAILED_FILES=0`.
- Dual HAP static build results recorded in commit message.
- No emulator, virtual machine, physical device, or Hypium execution.
