# Evidence: Leave delete-flush disposal bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- The leave path authorized disposal after canvas flush, then awaited recording delete queue flushing.
- A disposal during that second async boundary left the stale continuation free to finish the recording session and permanently release the shared playback controller.
- Component teardown independently starts session finish, delete flush, and playback release, so overlapping release paths could run concurrently.

## Change

- Added a disposal gate after delete-flush and before session teardown.
- Disposed leave continuations stop before recording session finish and playback release; component teardown fallback remains authoritative.
- Preserved canvas flush gating, normal cleanup order, reentrancy deduplication, and navigation behavior.

## Verification

* Strengthened focused replay: d02-editor-leave-reentrancy-bound.mjs (4/4), asserting tool flush → delete flush → disposal gate → session teardown ordering.
* Adjacent title-context replay: d02-title-commit-context-bound.mjs (4/4).
* Full Desktop Replay: REPLAY_FILES=362 PASSED=362 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.746 seconds; default in 52.414 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
