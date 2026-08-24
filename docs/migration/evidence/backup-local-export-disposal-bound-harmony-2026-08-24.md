# Evidence: Backup local export disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `BackupPage.exportAllLocal()` checked staleness once after fetching notes.
- The per-note loop awaited `NoteExporter.exportToFile()`, which can open the system save picker, without a pre-await lifecycle guard.
- The same loop also published `exported++` and the final toast after each await without checking whether the page had been replaced or disposed.

## Change

- Added an `isStale(lifecycleGeneration)` guard immediately before every export await.
- Added the same captured-generation guard immediately after every export await.
- Stale continuations now return before counting success, starting another picker/export, or publishing the final result.
- Busy/status cleanup and operation-lease release remain in the existing `finally`; active-page behavior and user cancellation are unchanged.

## Actual verification

- Focused replay: docs/migration/replays/d02-backup-local-export-disposal-bound.mjs (5/5).
- Adjacent replay: docs/migration/replays/d02-backup-failures-disposal-bound.mjs (5/5).
- Full Desktop Replay: REPLAY_FILES=349 PASSED=349 FAILED_FILES=0 (actual repository count).
- Dual HAP static build succeeded after clean: ohosTest in 13.092 seconds; default in 71.221 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
