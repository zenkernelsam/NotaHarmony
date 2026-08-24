# Evidence: Page history lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `NoteCanvasView.performHistory()` page-action branch advanced the runtime stack whenever
  `onApplyPageHistory()` resolved true, even after editor disposal or a page-load reset.
- `NotePage.applyPageHistory()` awaited durable title, metadata, page-settings, background, reorder,
  add-page and delete-page operations before mutating local publication state without rechecking disposal.
- Existing ADR-0289 covered deferred element/group history but not these note/page-level actions.

## Change

- Captured `pageHistoryGeneration` at invocation; stale successful continuations cannot call
  `commitHistory()`.
- Added explicit disposal checks after every major durable await in page-history application.
- Stale success returns false from NotePage while durable database results remain authoritative.
- Kept unconditional `historyBusy` reset and existing rejection/cancel behavior.

## Verification

- Focused replay: docs/migration/replays/d02-page-history-lifecycle-bound.mjs.
- Adjacent replay: docs/migration/replays/d02-deferred-history-moves-page-bound.mjs (9/9).
- Full Desktop Replay: REPLAY_FILES=324 PASSED=324 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.261 seconds; default in 56.231 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
