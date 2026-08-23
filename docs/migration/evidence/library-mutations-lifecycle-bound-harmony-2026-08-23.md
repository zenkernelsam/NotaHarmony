# Harmony Evidence: Library Mutations Lifecycle Binding

Date: 2026-08-23

- Four mutation entry points capture `lifecycleGeneration` before their first await.
- After successful durable operations, folder create/rename/delete/reorder and note move publish only when generation, `pageActive`, and repository/viewModel references remain current.
- Stale success paths return without folder snapshots, note snapshots, selection resets, thumbnail scheduling, or best-effort reloads.
- Catch paths still log; error toast publication is naturally guarded by existing catch checks or by returning before UI writes.

Replay: `d02-library-folder-mutations-lifecycle-bound.mjs` TOTAL=5 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=291 PASSED=291 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 12 s 208 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 8 s 188 ms`
