# Evidence: Paper settings load disposal bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- Shared paper settings loading awaited database initialization and then created a repository, listed background data, and listed favorites.
- The first combined generation/disposal check occurred only after both list reads.
- A disposed panel or superseded reload could therefore publish stale shared settings/favorites and rebind the paper store.

## Change

- Added a joint `panelDisposed || generation !== sharedLoadGeneration` gate immediately after database initialization.
- Invalid continuations stop before creating the repository, issuing storage reads, publishing state, or rebinding the store.
- Preserved existing favorite-write guards, spacing-save guards, failure handling, and busy cleanup.

## Verification

* Strengthened focused replay: docs/migration/replays/d02-paper-settings-disposal-bound.mjs (4/4), asserting initialize → joint gate → repository creation ordering.
* Adjacent favorite-refresh replay: d02-paper-favorite-refresh-disposal-bound.mjs (3/3).
* Full Desktop Replay: REPLAY_FILES=362 PASSED=362 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.962 seconds; default in 50.730 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
