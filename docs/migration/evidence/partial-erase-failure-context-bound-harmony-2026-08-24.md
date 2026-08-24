# Evidence: Partial erase failure context bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- Successful partial-erase commits already required the combined history-page context predicate.
- The persistence rejection continuation toasted `reportSaveFailure` and logged without that predicate.
- The same continuation later invoked the local snapshot fallback only behind the predicate.
- A late rejection could therefore rebuild disposed/stale ink and toast a stale Canvas.

## Change

- Moved diagnostic logging before UI publication in the rejection continuation.
- Added the existing history-page context gate before `reportSaveFailure`.
- The local snapshot fallback remains behind the same gate; preview cleanup stays unconditional.

## Verification

- Focused replay: docs/migration/replays/d02-partial-erase-failure-context-bound.mjs (5/5).
- Adjacent replays: canvas load failure 5/5 and canvas load/switch disposal 5/5.
- Full Desktop Replay: REPLAY_FILES=339 PASSED=339 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.862 seconds; default in 53.928 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
