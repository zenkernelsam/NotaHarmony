# Evidence: Library search lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: note/src/main/ets/ui/library/LibraryPage.ets
- Before: the 180ms search timer callback checked page activity and request identity but not the page lifecycle
  generation. After teardown it could still call setSearchQuery(); a late failure could show search_failed.
- isCurrentNotesRequest() already protected ViewModel/query/folder identity but inferred current lifecycle.

## Change

- Capture lifecycleGeneration when the debounce callback actually fires.
- Reject stale callbacks before starting a query.
- Pass that captured generation into both success and failure continuations through isCurrentNotesRequest().
- Existing request-generation and identity contracts remain unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-library-search-lifecycle-bound.mjs (7/7).
- Full Desktop Replay: `REPLAY_FILES=320 PASSED=320 FAILED_FILES=0`.
- Existing `d02-library-query-generation.mjs` now requires the captured lifecycle guard (8/8).
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 9 s 383 ms; main BUILD SUCCESSFUL in 49 s 676 ms.
- No simulator, virtual machine, physical device, or Hypium execution.
