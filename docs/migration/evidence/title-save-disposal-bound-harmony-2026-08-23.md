# Harmony Evidence: Title Save Disposal Binding

Date: 2026-08-23

- `aboutToDisappear()` sets `editorDisposed = true` before teardown work.
- `commitTitle()` checks `editorDisposed` after `updateNoteTitle()` and in catch; stale paths skip `noteTitle` writes, `titleDraft` publication, history mutation, and save-failure toast.
- Durable title results remain authoritative for the next editor instance.

Replay: `d02-title-save-disposal-bound.mjs` TOTAL=3 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=293 PASSED=293 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 12 s 829 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 8 s 207 ms`
