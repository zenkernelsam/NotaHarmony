# Evidence: Library preference and thumbnail lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- setSortMode(): a late menu action after teardown could still mutate ViewModel, start thumbnails, and flush the
  process-global sort preference.
- requestVisibleThumbnail(): its 50ms timer could fire after disposal; refreshThumbnails had internal guards but
  the stale timer could still enter the refresh pipeline.
## Change

- Added an active-page gate to sort mode entry.
- Captured lifecycle identity before the visible-thumbnail timer and rejected stale callbacks.
- Confirmed existing teardown timer cancellation and generation invalidation remain in place.

## Verification

- Focused replay: docs/migration/replays/d02-library-preference-thumbnail-bound.mjs (6/6).
- Full Desktop Replay: REPLAY_FILES=322 PASSED=322 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.296 seconds; default in 53.875 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
