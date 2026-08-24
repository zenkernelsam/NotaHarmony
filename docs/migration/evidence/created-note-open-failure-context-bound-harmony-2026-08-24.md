# Evidence: Created-note open failure context bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- Note creation success/failure continuations already required lifecycle generation, active page, and captured ViewModel identity.
- The subsequent `router.pushUrl()` rejection toasted unconditionally.
- Navigation could resolve after the user left or the library was recreated, allowing a stale toast.

## Change

- Logged the durable navigation failure first.
- Added the existing combined context gate before the open-failed toast.
- Stale failures return without UI publication; `finally` still clears `createBusy`.

## Verification

- Focused replay: docs/migration/replays/d02-created-note-open-failure-context-bound.mjs (4/4).
- Adjacent replay: library note create/delete lifecycle 5/5 (strengthened to lock the new navigation gate).
- Full Desktop Replay: REPLAY_FILES=345 PASSED=345 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.396 seconds; default in 53.657 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
