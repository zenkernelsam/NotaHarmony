# Evidence: Library initialization failure disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- Successful initData continuations checked both `pageActive` and the expected lifecycle generation.
- The outer failure continuation set loading/error UI and showed a retry toast before logging.
- A late exception after navigation or recreation could therefore publish stale library state.

## Change

- Moved durable diagnostic logging to the start of the outer catch.
- Added the existing lifecycle gate before loading/error publication and the retry toast.
- Stale failures now return without UI publication.

## Verification

- Focused replay: docs/migration/replays/d02-library-init-failure-disposal-bound.mjs (4/4).
- Adjacent replays: library mutation failures 6/6 and preference writes 6/6.
- Full Desktop Replay: REPLAY_FILES=343 PASSED=343 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.421 seconds; default in 52.340 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
