# Evidence: Recording pending publish disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `startCommit().finally()` intentionally removes pending ids, unregisters the commit, and calls publish even after page disposal.
- The page failure listener logged first and checked `editorDisposed`; the normal pending listener did not.
- Therefore a late post-commit publish could assign stale pending ids and rebuild the old editor timeline.

## Change

- Added an `editorDisposed` guard at the start of the normal pending-delete listener.
- Stale controller publications now return without state mutation or timeline rebuild.
- Controller cleanup and publication ordering, active undo behavior, commit refresh, and existing failure-toast guards remain unchanged.

## Actual verification

- Focused replay: docs/migration/replays/d02-recording-pending-publish-disposal-bound.mjs (4/4).
- Adjacent replays: d02-recording-commit-delete-disposal-bound.mjs (2/2), d02-recording-delete-failure-disposal-bound.mjs (3/3), and d02-recording-delete-request-disposal-bound.mjs (3/3).
- Full Desktop Replay: REPLAY_FILES=353 PASSED=353 FAILED_FILES=0 (actual repository count).
- Dual HAP static build succeeded after clean: ohosTest in 10.795 seconds; default in 67.354 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.