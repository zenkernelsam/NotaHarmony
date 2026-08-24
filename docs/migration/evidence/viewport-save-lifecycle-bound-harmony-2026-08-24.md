# Evidence: Viewport save lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `scheduleViewportSave()` debounced writes by 500 ms; disposal canceled the timer but did not invalidate a
  callback that had already entered the save continuation.
- `saveViewportState()` initialized the database and wrote global view state without lifecycle or generation
  checks, so a stale write could overwrite a newer editor viewport.

## Change

- Capture `pageLoadGeneration` when scheduling the debounce and pass it to the save call.
- Require active lifecycle and matching generation before database initialization and durable write.
- The direct teardown call remains lifecycle-gated without generation; failure logging is unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-viewport-save-lifecycle-bound.mjs (5/5).
- Adjacent replays: canvas load failure 5/5 and page history lifecycle 12/12.
- Full Desktop Replay: REPLAY_FILES=333 PASSED=333 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 11.892 seconds; default in 61.781 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
