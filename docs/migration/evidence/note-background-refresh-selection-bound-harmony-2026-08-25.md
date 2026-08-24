# Evidence: Note background refresh selection bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- Background application persisted the note metadata and then awaited a fresh page-list query before publishing selection.
- The Canvas receives selection through a watched prop, so publication after the second await could interrupt a page switch started by the user during that wait.
- The stale background continuation therefore pulled navigation back to its original target even though durable persistence had already completed.

## Change

- After disposal authorization, restore selection to the original target before issuing the async page-list refresh.
- Preserve the existing post-refresh disposal guard, materialized-background publication, history push, failure handling, and durable semantics.

## Verification

* Focused replay: docs/migration/replays/d02-page-operation-disposal-bound.mjs (12/12), now asserting update → early target reselection → page refresh ordering.
* Adjacent failure-bound replay: d02-page-operation-failure-disposal-bound.mjs (3/3).
* Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.516 seconds; default in 50.329 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
