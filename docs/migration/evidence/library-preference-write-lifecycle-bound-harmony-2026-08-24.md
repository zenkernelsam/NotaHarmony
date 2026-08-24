# Evidence: Library preference write lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `setSortMode()` and `setThemeMode()` checked activity before starting preference acquisition, but their
  async success continuations wrote the sort or theme key unconditionally.
- Because both values are process-global/durable and restored on next launch, a stale continuation could
  overwrite newer state after page disposal or replacement.
- Phase 355/356 guarded synchronous effects and operation entry but not this post-acquisition write
  boundary.

## Change

- Captured lifecycle identity at each entry.
- Added a joint active-page/same-generation guard after `getPreferences()` and before `putSync()/flush()`.
- Stale continuations perform no preference mutation; failure logging remains unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-library-preference-write-lifecycle-bound.mjs.
- Adjacent replays: d02-library-preference-thumbnail-bound.mjs (6/6) and
  d02-library-theme-mode-lifecycle-bound.mjs (7/7).
- Adjacent replays: preference/thumbnail 6/6 and theme mode 7/7.
- Full Desktop Replay: REPLAY_FILES=328 PASSED=328 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.053 seconds; default in 50.069 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
