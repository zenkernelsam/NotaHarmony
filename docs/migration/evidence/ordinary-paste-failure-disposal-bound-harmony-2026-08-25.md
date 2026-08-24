# Evidence: Ordinary paste failure disposal bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- reportSaveFailure() publishes a user-facing toast and has no internal disposal guard.
- The ordinary paste success continuation cleared saveFailed without checking lifecycleActive.
- The failure continuation repeated page/load predicates but omitted lifecycleActive, so a disposed editor could still receive a late paste-save toast.

## Change

- Reused isHistoryPageContextCurrent(persistedGeneration, persistedPageId) in both deferred continuations.
- Kept the durable stale-failure hilog before the shared context guard.
- Left synchronous queue failures, clipboard commit checks, state publication, history, rendering, and image refresh unchanged.

## Actual verification

- Focused replay: docs/migration/replays/d02-ordinary-paste-failure-disposal-bound.mjs (6/6).
- Full Desktop Replay: REPLAY_FILES=356 PASSED=356 FAILED_FILES=0 (actual repository count).
- Dual HAP static builds succeeded after clean: ohosTest in 11.129 seconds; default in 55.324 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
