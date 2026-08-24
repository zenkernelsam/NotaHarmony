# Evidence: Partial erase and photo insert stale bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- Functions: `commitOriginalPartialErase()`, `insertOriginalPhotos()`
- Before: success-side guards covered element installation but not undo/history mutations, notification, or all preview bookkeeping.

## Change

- Both success continuations now check current lifecycle/page context immediately after durable commit and before local editor effects.
- Stale successes log that durable history remains available; partial erase returns early and photo insertion returns its durable count without UI/history publication.
- Existing failure-context behavior and unconditional `finally` cleanup remain unchanged.

## Verification

- Focused replay: `docs/migration/replays/d02-partial-erase-photo-stale-bound.mjs`.
- No simulator, virtual machine, physical device, or Hypium execution.
- Full Desktop Replay: `REPLAY_FILES=311 PASSED=311 FAILED_FILES=0`.
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 14 s 548 ms; main BUILD SUCCESSFUL in 3 s 283 ms (20 seconds total).