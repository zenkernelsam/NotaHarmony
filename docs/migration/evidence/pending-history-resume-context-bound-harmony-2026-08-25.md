# Evidence: Pending history resume context bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- Cross-page history stored `pendingHistoryDirection` and resumed automatically when target page data finished loading.
- The old resume path only checked that the direction was non-zero.
- It therefore did not distinguish a disposed editor, failed load, active command, or identity mismatch before starting another durable history move.

## Change

- Added lifecycle, loaded-health, and busy authorization before consuming a pending move; invalid context clears it.
- Added current-page identity agreement. A page mismatch keeps the pending direction for a matching reload instead of executing immediately.
- Preserved the normal cross-page undo/redo continuation after successful page load.

## Verification

* New focused replay: docs/migration/replays/d02-pending-history-resume-context-bound.mjs (5/5), asserting direction → lifecycle/busy gate → identity gate → direction consumption ordering.
* Adjacent replay: d02-page-history-lifecycle-bound.mjs (12/12).
* Full Desktop Replay: REPLAY_FILES=361 PASSED=361 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.730 seconds; default in 50.594 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
