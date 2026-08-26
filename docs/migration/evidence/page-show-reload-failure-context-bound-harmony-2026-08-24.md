# Evidence: Page show reload failure context bound

Date: 2026-08-24 (Asia/Shanghai)

## Phase 510 increment (2026-08-26)

- Audit found that the library settings navigation called the router without checking page activation; a stale menu action could start a route after disposal.
- `navigateToSettings()` now rejects inactive pages before routing. Menu structure, settings entry, return refreshes, and failure logging are unchanged.
- Extended the existing page-show reload failure context-bound replay to `TOTAL=5 FAILED=0`.

## Source review

- Successful onPageShow reload continuations checked lifecycle, ViewModel/renderer identity, and the current notes request.
- The rejection continuation published loading/error state and toasted before diagnostic logging.
- A late exception after navigation or recreation could therefore mutate a stale LibraryPage.

## Change

- Moved durable logging to the start of the rejection continuation.
- Reused the same combined lifecycle/request gate before UI publication and toast.
- Stale failures now return without publication.

## Verification

- Focused replay: docs/migration/replays/d02-page-show-reload-failure-context-bound.mjs (4/4).
- Adjacent replays: library initialization disposal 4/4 and folder selection lifecycle 7/7.
- Full Desktop Replay: REPLAY_FILES=344 PASSED=344 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.379 seconds; default in 53.679 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
