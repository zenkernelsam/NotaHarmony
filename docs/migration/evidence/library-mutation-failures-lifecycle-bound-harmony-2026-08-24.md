# Evidence: Library mutation failures lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- Folder create/rename, folder delete, folder move, and note move success publication were already bound
  to lifecycle and repository/view-model identity.
- Their repository `catch` continuations called `promptAction.showToast()` without the same stale check,
  so a late failure could surface on a disposed page.
- Existing note create/delete catches already checked lifecycle, activity, and captured ViewModel.

## Change

- Added active-page/same-generation guards at the start of the four mutable-operation failure paths.
- Stale failures return the original result type without UI effects; busy cleanup remains in `finally`.
- No successful mutation or durable error handling contract changed.

## Verification

- Focused replay: docs/migration/replays/d02-library-mutation-failures-lifecycle-bound.mjs.
- Adjacent replays: d02-library-folder-mutations-lifecycle-bound.mjs (5/5) and
  d02-library-note-create-delete-lifecycle-bound.mjs (4/4).
- Full Desktop Replay: REPLAY_FILES=329 PASSED=329 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 9.778 seconds; default in 55.636 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
