# Evidence: WebDAV test failures disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- The success continuation after `client.testConnection()` already required the captured lifecycle generation.
- Both failure continuations logged late exceptions and unconditionally published test state:
  - insecure HTTP confirmation rejection;
  - connection request rejection.
- A user could leave or trigger page replacement during either await, allowing stale failures to reach old UI.

## Change

- Each catch now logs first and reuses `isDisposed(lifecycleGeneration)` before publication.
- Stale failures return without touching `testSucceeded`, `testResult`, or `hasTestResult`.
- Active-page failure semantics and the outer `isTesting` cleanup remain unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-webdav-test-failures-disposal-bound.mjs (4/4).
- Adjacent replay: d02-webdav-settings-disposal-bound.mjs 9/9 (guard count strengthened to four and both catch orders locked).
- Full Desktop Replay: REPLAY_FILES=347 PASSED=347 FAILED_FILES=0 (actual repository count).
- Dual HAP static build succeeded: ohosTest in 9.281 seconds; default in 51.966 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
