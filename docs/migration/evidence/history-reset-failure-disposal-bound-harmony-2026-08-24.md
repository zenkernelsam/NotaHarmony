# Evidence: History reset failure disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `resetPersistentHistory()` already guarded successful completion with `lifecycleActive`.
- The catch path logged the durable reset failure and then unconditionally showed a recovery toast.
- A late exception after confirming reset and leaving the editor could therefore toast a disposed Canvas.

## Change

- Added a `lifecycleActive` return guard after the failure log and before the toast.
- Busy cleanup remains authoritative in `finally`.
- Live-editor success/failure semantics and durable database behavior remain unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-history-reset-failure-disposal-bound.mjs (5/5).
- Adjacent replays: canvas load failure 5/5 and canvas load/switch disposal 5/5.
- Full Desktop Replay: REPLAY_FILES=338 PASSED=338 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 10.094 seconds; default in 58.302 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
