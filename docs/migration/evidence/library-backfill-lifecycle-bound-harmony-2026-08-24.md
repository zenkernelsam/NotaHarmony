# Evidence: Library backfill lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/library/LibraryPage.ets`
- Function: `initData()` / `persistence.backfillSearchIndex().then()`
- Before: the backfill callback checked only active query/folder conditions, not lifecycle/view-model/renderer identity.

## Change

- Backfill success now checks the same lifecycle predicate used by initialization publication before doing any follow-up request.
- Disposed/replaced contexts cannot start `loadNotes()` or mutate `viewModel`, `notes`, or thumbnails.
- Follow-up refresh remains protected by `isCurrentNotesRequest`.

## Verification

- Focused replay: `docs/migration/replays/d02-library-backfill-lifecycle-bound.mjs`.
- No simulator, virtual machine, physical device, or Hypium execution.
- Full Desktop Replay: `REPLAY_FILES=312 PASSED=312 FAILED_FILES=0`.
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 15 s 224 ms; main BUILD SUCCESSFUL in 4 s 003 ms (22 seconds total).