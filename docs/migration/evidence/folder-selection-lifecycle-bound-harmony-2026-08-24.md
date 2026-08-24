# Evidence: Folder selection lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: note/src/main/ets/ui/library/LibraryPage.ets
- Function: selectFolder
- Before: success and failure continuations used isCurrentNotesRequest or a weaker inline tuple; the helper inferred
  the current lifecycle, so a rebuilt page could make a captured old request appear current.
## Change

- Captured lifecycleGeneration before starting folder selection.
- Passed it to all three continuation guards: post-query publication, post-thumbnail drawer close, and failure toast.
- Replaced the weaker inline catch tuple with the shared complete identity check.

## Verification

- Focused replay: docs/migration/replays/d02-library-folder-selection-lifecycle-bound.mjs (7/7).
- Full Desktop Replay: `REPLAY_FILES=321 PASSED=321 FAILED_FILES=0`.
- Existing `d02-library-query-generation.mjs` now requires the captured lifecycle identity across all three folder-selection guards (8/8).
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 9 s 174 ms; main BUILD SUCCESSFUL in 50 s 871 ms.
- No simulator, virtual machine, physical device, or Hypium execution.
