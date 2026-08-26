# Evidence: Library search lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Phase 511 increment (2026-08-26)

- Audit found that the search `onChange` entry published `searchText` and incremented the notes-request generation before any activation check. A late input event after disposal could pollute shared state even though the debounce callback was guarded.
- The input callback now rejects inactive pages before query publication, request-generation capture, and debounce scheduling. Debounce identity, lifecycle rejection, result publishing, thumbnails, and failure feedback are unchanged.
- Extended the existing library search lifecycle-bound replay to `TOTAL=8 FAILED=0`.

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
