# Evidence: Page operation failure disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- Successful page-operation continuations already checked editor disposal.
- The shared `runPageOperation()` catch logged the error and unconditionally showed a failure toast.
- A late exception after navigation could therefore surface on a disposed NotePage.

## Change

- Added an `editorDisposed` check after diagnostic logging and before the toast.
- Disposed failures return without UI publication; busy cleanup remains in `finally`.
- Durable operation failure semantics and success contracts are unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-page-operation-failure-disposal-bound.mjs (3/3).
- Adjacent replays: page operation success 8/8 and page history lifecycle 12/12.
- Full Desktop Replay: REPLAY_FILES=336 PASSED=336 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 13.922 seconds; default in 67.502 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
