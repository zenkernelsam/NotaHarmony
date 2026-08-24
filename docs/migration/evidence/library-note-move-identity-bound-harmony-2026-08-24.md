# Evidence: Library note move identity bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: `note/src/main/ets/ui/library/LibraryPage.ets`
- Function: `moveNote()`
- Before: success guard checked only `lifecycleGeneration` and `pageActive`; it did not compare the captured ViewModel with the current instance.

## Change

- Success publication now also requires `this.viewModel === vm`.
- Stale durable moves return before ViewModel mutation, notes snapshot publication, or thumbnail refresh.
- Existing authoritative reload remains protected by `isCurrentNotesRequest`.

## Verification

- Focused replay: `docs/migration/replays/d02-library-note-move-identity-bound.mjs` (6/6).
- Existing contract replay: `d02-library-folder-mutations-lifecycle-bound.mjs` (5/5).
- No simulator, virtual machine, physical device, or Hypium execution.
- Full Desktop Replay: `REPLAY_FILES=313 PASSED=313 FAILED_FILES=0`.
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 13 s 398 ms; main BUILD SUCCESSFUL in 3 s 441 ms (19 seconds total).