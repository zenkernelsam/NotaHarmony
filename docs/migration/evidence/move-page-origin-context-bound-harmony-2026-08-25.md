# Evidence: Move page origin context bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- Page reordering captured the selected page and target index before awaiting durable persistence.
- The user could switch pages while `reorderPages()` was pending.
- After disposal authorization alone, the stale continuation published the captured order, restored the old target index, and pushed undo history whose origin no longer matched navigation.

## Change

- Added an origin gate after persistence: continue only when the parent's current page remains the originally selected page.
- Stale continuations keep the durable order but publish neither page order/index nor undo history.
- The accepted path retains the existing order publication, index assignment, and history push.

## Verification

* Focused replay: docs/migration/replays/d02-page-operation-disposal-bound.mjs (15/15), asserting disposal → origin gate → order publication ordering.
* Adjacent failure-bound replay: d02-page-operation-failure-disposal-bound.mjs (3/3).
* Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.660 seconds; default in 50.034 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
