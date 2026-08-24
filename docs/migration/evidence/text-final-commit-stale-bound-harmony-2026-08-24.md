# Evidence: Text final commit stale bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- Function: `onTextCommit()`
- Before: after `previewOriginalTextEdit()` the guard checked editing element identity and
  `isHistoryPageContextCurrent()`, but not whether a newer final commit had superseded this invocation.
- `aboutToDisappear()` can start the final commit asynchronously; the stale continuation could mutate and save.

## Change

- Added per-invocation text commit generation.
- Required current generation in addition to element identity, page generation/page ID, and lifecycle activity.
- Stale original-text continuations return before replacement, history publication, persistence, or render.

## Verification

- Focused replay: `docs/migration/replays/d02-text-final-commit-stale-bound.mjs` (6/6).
- Full Desktop Replay: `REPLAY_FILES=318 PASSED=318 FAILED_FILES=0`.
- Existing `d02-original-text-commit-page-bound.mjs` was strengthened to require the commit-generation guard (5/5).
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 11 s 608 ms; main BUILD SUCCESSFUL in 51 s 953 ms.
- No simulator, virtual machine, physical device, or Hypium execution.
