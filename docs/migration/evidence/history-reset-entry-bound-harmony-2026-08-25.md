# Evidence: History reset entry bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `resetPersistentHistory()` checked busy and required state internally, but the dialog confirmation callback invoked it directly.
- A late confirmation could execute after disposal or after another history command started, bypassing the click-time gate.
- The existing post-await disposal guard already protected the successful continuation; the missing boundary was entry authorization.

## Change

- Added `requestPersistentHistoryReset()` as the sole dialog action target.
- It checks `lifecycleActive`, `historyRecoveryRequired`, both busy flags, and database availability before delegating.
- Existing success/failure guards, durable reset, cleanup order, and active-page toasts remain unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-history-reset-entry-bound.mjs (7/7).
- Strengthened adjacent replay: d02-history-reset-lifecycle-bound.mjs (7/7); failure-disposal replay remains 5/5.
- Full Desktop Replay: REPLAY_FILES=359 PASSED=359 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 13.121 seconds; default in 55.438 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
