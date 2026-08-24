# Evidence: Note load acquisition order bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `loadPages()` incremented `pageLoadGeneration` before checking disposal and in-flight state.
- A rejected duplicate call therefore invalidated the generation captured by the active load even though it never acquired execution.
- The active continuation could stop at the next guarded boundary while no replacement load was started, leaving startup work cancelled by a rejected caller.

## Change

- Moved the joint `editorDisposed || pageLoadInFlight` admission check ahead of the load-generation increment.
- Only an accepted load now creates a new generation and claims in-flight state.
- Preserved every post-await disposal/generation guard, failure rollback behavior, and finally cleanup semantics.

## Verification

* Focused replay: docs/migration/replays/d02-note-page-load-lifecycle-bound.mjs (5/5), now asserting gate → increment → claim ordering.
* Strengthened adjacent replay: docs/migration/replays/d02-editor-load-disposal-race-bound.mjs (5/5).
* Adjacent continuation replay: d02-note-page-load-note-disposal-bound.mjs (5/5).
* Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.972 seconds; default in 50.144 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
