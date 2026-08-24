# Evidence: Paste enqueue failure context bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- Ordinary clipboard paste enqueued its durable save synchronously and toasted any enqueue exception.
- The same path already gated late flush failures with the combined history-page context predicate.
- A stale/disposed enqueue failure could therefore toast the old Canvas without publishing state.

## Change

- Added the existing history-page context gate before `reportSaveFailure` in the synchronous enqueue catch.
- Stale failures return before UI publication; live-page toast semantics are unchanged.
- Deferred flush gating remains unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-ordinary-paste-enqueue-context-bound.mjs (4/4).
- Adjacent replays: canvas load failure 5/5 and partial erase context 5/5.
- Full Desktop Replay: REPLAY_FILES=340 PASSED=340 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 10.125 seconds; default in 55.084 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
