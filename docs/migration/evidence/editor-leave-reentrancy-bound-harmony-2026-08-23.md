# Harmony Evidence: Editor Leave Reentrancy Binding

Date: 2026-08-23

- `NotePage.leaveEditor()` now returns the existing `editorLeavePromise` on reentry.
- Only the first call starts `performLeaveEditor()`; title save waiting, history flush, tool-state flush, recording delete flush, session finish, player release, and `router.back()` remain in that order.
- Duplicate back button clicks and back-button/back-press concurrency share one teardown result instead of issuing multiple navigation pops.

Replay: `d02-editor-leave-reentrancy-bound.mjs` TOTAL=3 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=289 PASSED=289 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 12 s 10 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 8 s 632 ms`
