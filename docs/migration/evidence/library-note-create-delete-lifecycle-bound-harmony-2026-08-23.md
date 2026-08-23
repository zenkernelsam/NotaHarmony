# Harmony Evidence: Library Note Create/Delete Lifecycle Binding

Date: 2026-08-23

- `deleteNoteAndRefresh()` checks generation/page/viewModel after delete and in its catch path before any state write or toast.
- `createAndOpen()` checks generation/page/viewModel after creation and in catch before snapshot publication, toast, reload scheduling, or editor navigation; guard resets `createBusy`.
- Stale paths skip all memory/UI publication and navigation while durable results remain authoritative.

Replay: `d02-library-note-create-delete-lifecycle-bound.mjs` TOTAL=4 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=292 PASSED=292 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 12 s 702 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 8 s 852 ms`
