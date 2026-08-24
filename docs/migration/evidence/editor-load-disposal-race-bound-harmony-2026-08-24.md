# Evidence: Editor load disposal race bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `aboutToAppear()` invoked `loadPages()`; a synchronous `aboutToDisappear()` could set disposed and increment
  generation before the async function captured state.
- The old implementation captured stale generation first and returned because in-flight was already true,
  allowing initialization/publication to continue on the disposed component.
- Review also found that the prior viewport lifecycle change accidentally blocked the intentional teardown save.

## Change

- Reject load entry when disposed before setting in-flight/loading state.
- Require combined disposal/generation validity after pages publication before background loading and later UI.
- Allow the explicit teardown viewport save despite disposal while keeping debounced saves fully gated.

## Verification

- Focused replay: docs/migration/replays/d02-editor-load-disposal-race-bound.mjs (4/4).
- Regression replay: docs/migration/replays/d02-viewport-save-lifecycle-bound.mjs (5/5).
- Adjacent editor load/initialization replays passed 5/5 and 4/4; viewport regression passed 5/5.
- Full Desktop Replay: REPLAY_FILES=334 PASSED=334 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 13.154 seconds; default in 58.284 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
