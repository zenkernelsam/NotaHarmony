# Evidence: Math insert entry bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- The toolbar forwards insertion through `mathInsertSignal`, an asynchronous component prop/watch boundary.
- `startMathInsert()` checked editor visibility, busy state, loaded health, persistence, and a non-empty page ID, but did not check canvas disposal or page identity.
- At a navigation boundary, a late signal could deselect the target page, open the old Math overlay, and start validation against stale context.

## Change

- Added `lifecycleActive` and `loadedPageId === currentPage.pageId` to the insert entry gate.
- All existing checks remain before any selection reset, overlay publication, or draft validation.

## Verification

- Focused replay: docs/migration/replays/d02-math-insert-entry-bound.mjs (10/10).
- Strengthened adjacent replay: d02-local-math-insert.mjs now requires the full entry gate.
- Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 14.626 seconds; default in 58.359 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
