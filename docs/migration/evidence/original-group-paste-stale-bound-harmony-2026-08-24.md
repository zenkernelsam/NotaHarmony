# Evidence: Original Group Paste stale bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- Function: `applyOriginalGroupClipboardPaste()`
- Before: success callback guarded UI installation but unconditionally called `strokeClipboard.commitPreparedPaste()`, `undoRedo.push()`, history revision assignment, and `notifyUndoRedo()` after a stale/disposed page transition.

## Change

- Success callbacks now check `isHistoryPageContextCurrent(generation, pageId)` before every editor-side effect.
- Stale durable successes return after logging; clipboard commit, undo stack mutation, UI installation, and notification are skipped.
- Failure and `finally` semantics remain bounded: current-context-only save-failure UI and unconditional `historyBusy` reset.

## Verification

- Focused replay: `docs/migration/replays/d02-original-group-paste-stale-bound.mjs`.
- No simulator, virtual machine, physical device, or Hypium execution.

- Full Desktop Replay: `REPLAY_FILES=309 PASSED=309 FAILED_FILES=0`.
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 14 s 210 ms; main BUILD SUCCESSFUL in 3 s 356 ms (20 seconds total).