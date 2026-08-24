# Evidence: Add page origin context bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `addPage()` captured the originating page, created a durable page, and awaited persistence.
- A user could switch pages while that await was pending.
- After disposal authorization alone, the stale continuation republished the new-page selection and an undo action whose recorded origin no longer matched navigation.

## Change

- Added an origin gate after persistence: continue only if the parent's current page is still `selectedBefore`.
- Stale continuations keep the durable new page but publish neither UI state nor undo history.
- On the accepted path, publication now sets the index from the updated list length instead of assigning twice.

## Verification

* Focused replay: docs/migration/replays/d02-page-operation-disposal-bound.mjs (14/14), asserting disposal → origin gate → selection/action ordering and list-length selection.
* Adjacent failure-bound replay: d02-page-operation-failure-disposal-bound.mjs (3/3).
* Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.796 seconds; default in 53.822 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
