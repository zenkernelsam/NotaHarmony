# Harmony Evidence: History Reset Lifecycle Binding

Date: 2026-08-23

- `resetPersistentHistory()` now checks `lifecycleActive` immediately after its durable SQLite reset succeeds.
- Disposed completions return before `undoRedo.clear()`, recovery flag mutation, notification, or toast presentation.
- The finally path still clears `historyBusy` and `historyRecoveryBusy`; failed durable resets retain their existing behavior.

Replay: `d02-history-reset-lifecycle-bound.mjs` TOTAL=6 FAILED=0. Existing history recovery and deferred history page-bound replays pass. No emulator, VM, device, or Hypium was started.

Full desktop replay after the fix: `REPLAY_FILES=287 PASSED=284 FAILED_FILES=3`; all three remaining failures were reproduced before this phase. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 21 s 343 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 8 s 836 ms`
