# Evidence: Original Math commit stale bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- Functions: `confirmMathInsert()`, `confirmMathEditing()` (LaTeX edit path)
- Before: durable success could push undo, mutate/close the Math editor, update bookkeeping/UI, and notify even when only part of the final UI update was guarded.

## Change

- Both success continuations now check `isHistoryPageContextCurrent(generation, pageId)` immediately after durable commit and before all local effects.
- Stale durable successes return with a diagnostic log; no undo push, editor-state mutation, render, or notification occurs.
- Catch handlers remain current-context-only for failure UI, while `finally` always resets busy flags.

## Verification

- Focused replay: `docs/migration/replays/d02-original-math-commit-stale-bound.mjs`.
- No simulator, virtual machine, physical device, or Hypium execution.
- Full Desktop Replay: `REPLAY_FILES=310 PASSED=310 FAILED_FILES=0`.
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 14 s 31 ms; main BUILD SUCCESSFUL in 3 s 288 ms (20 seconds total).