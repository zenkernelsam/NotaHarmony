# Evidence: Canvas load failure lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `aboutToDisappear()` sets `lifecycleActive=false` without incrementing `pageLoadGeneration`.
- The initial `loadNoteData()` catch only compared the captured generation before calling local failure
  reset and `reportLoadFailure()`.
- A late initial-load exception after disposal could therefore clear canvas state and show a stale toast.

## Change

- Added a `lifecycleActive` check after the generation gate and before local failure publication.
- Disposed-editor failures skip `enterLoadFailureState()` and `reportLoadFailure()`.
- Same-generation `finally` still clears `dataLoading`; success and page-switch paths are unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-canvas-load-failure-lifecycle-bound.mjs (5/5).
- Adjacent replays: page history 12/12, clipboard probe 4/4, deferred history 9/9.
- Full Desktop Replay: REPLAY_FILES=331 PASSED=331 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 10.249 seconds; default in 52.878 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
