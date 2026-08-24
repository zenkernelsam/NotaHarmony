# Evidence: Title and leave context bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `performLeaveEditor()` awaited canvas flush, then unconditionally flushed tools and recording resources and called `router.back()`.
- A disposal during the flush await could therefore make a late continuation operate on disposed controllers.
- `commitTitle()` awaited durable title persistence, checked only disposal, and then published title/history even if the user had switched to another page; the cross-page undo action could trigger a Canvas page load.

## Change

- Added a post-flush disposal gate before tool/recording cleanup and navigation.
- Added a selected-page identity gate after title persistence. On mismatch, the continuation materializes only the durable title and skips action mutation and history publication.
- Preserved normal title publication, undo push, leave cleanup order, and all existing guards.

## Verification

* Strengthened focused replay: d02-editor-leave-reentrancy-bound.mjs (3/3), asserting post-flush disposal gating.
* New adjacent replay: d02-title-commit-context-bound.mjs (4/4), asserting dispose → identity → materialized-only stale path ordering.
* Full Desktop Replay: REPLAY_FILES=362 PASSED=362 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.674 seconds; default in 50.195 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
