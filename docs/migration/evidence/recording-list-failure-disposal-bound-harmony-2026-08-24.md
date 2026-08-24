# Evidence: Recording list failure disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- The success continuation already checked `editorDisposed || generation !== recordingLoadGeneration`.
- The catch checked only generation, then cleared recordings, rebuilt the timeline, and showed a toast.
- A synchronous list failure or same-tick generation update could therefore publish stale empty state to a
  disposed NotePage.

## Change

- Applied the same disposal-plus-generation guard at the start of the failure continuation.
- Stale or disposed failures no longer reset recordings, rebuild the timeline, or show a toast.
- Same-generation `finally` cleanup and the success contract remain unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-recording-list-failure-disposal-bound.mjs (5/5).
- Adjacent recording lifecycle replays passed 9/9, 2/2, 2/2, 3/3, and 2/2.
- Full Desktop Replay: REPLAY_FILES=332 PASSED=332 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.959 seconds; default in 53.257 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
