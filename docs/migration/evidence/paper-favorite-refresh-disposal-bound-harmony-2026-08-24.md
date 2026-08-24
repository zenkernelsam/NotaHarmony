# Evidence: Paper favorite refresh disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- The favorite mutation continuation checked `panelDisposed` before refreshing the list.
- The second await, `store.listFavorites()`, assigned its result directly to state after returning.
- Closing the panel during that refresh could therefore publish a stale favorite list to the old component.

## Change

- Captured the refreshed favorites in a local variable.
- Added a second `panelDisposed` guard between the refresh await and publication.
- Preserved active-panel refresh semantics, failure feedback guards, and shared-busy cleanup.

## Actual verification

- Focused replay: docs/migration/replays/d02-paper-favorite-refresh-disposal-bound.mjs (4/4).
- Adjacent replay: docs/migration/replays/d02-paper-settings-disposal-bound.mjs (3/3), strengthened to require all three disposal gates in toggleFavorite.
- Full Desktop Replay: REPLAY_FILES=352 PASSED=352 FAILED_FILES=0 (actual repository count).
- Dual HAP static build succeeded after clean: ohosTest in 14.729 seconds; default in 68.646 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.