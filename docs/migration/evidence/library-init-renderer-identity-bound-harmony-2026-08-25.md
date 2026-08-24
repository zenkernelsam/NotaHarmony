# Evidence: Library initialization renderer identity bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `aboutToDisappear()` replaces the active thumbnail renderer while a best-effort retirement continues.
- The post-preferences continuation in initData checked only page activity and lifecycle generation.
- A stale continuation could initialize the database and later publish fresh repositories even though its captured renderer had been retired.

## Change

- Captured the current renderer at the start of try so ArkTS block scope is valid for the early guard.
- Added renderer identity to the post-preferences guard before database initialization.
- Preserved the existing post-render-initialization identity guard, repository publication guards, and failure-path lifecycle checks.

## Actual verification

- Focused replay: docs/migration/replays/d02-library-init-renderer-identity-bound.mjs (4/4).
- Adjacent replay: docs/migration/replays/d02-library-init-failure-disposal-bound.mjs (4/4).
- Full Desktop Replay: REPLAY_FILES=355 PASSED=355 FAILED_FILES=0 (actual repository count).
- Dual HAP static builds succeeded after clean: ohosTest in 12.171 seconds; default in 26.337 seconds after the scoped-declaration correction.
- No simulator, virtual machine, physical device, or Hypium execution.