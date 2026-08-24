# Evidence: Note zero-page recovery disposal bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `NotePage.loadPages()` used the legacy/corrupt zero-page branch only after `getPages()` returned no rows.
- `await pageRepo.addPage()` crosses an asynchronous persistence boundary.
- The assigned result was published immediately without checking disposal or the captured load generation, although a combined guard existed only after both publication branches.

## Change

- Added a joint `editorDisposed || loadGeneration !== this.pageLoadGeneration` check immediately after recovery `addPage()` completes.
- Stale continuations now return before publishing `[assignedPage]`; the already persisted recovery row remains durable and is not duplicated by the stale continuation.
- Normal-loaded publication, the existing post-publication guard, background loading, catch handling, and in-flight cleanup remain unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-note-page-load-lifecycle-bound.mjs (4/4).
- Strengthened adjacent replay: docs/migration/replays/d02-editor-load-disposal-race-bound.mjs (4/4) now asserts await → guard → publication ordering.
* Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 12.534 seconds; default in 56.575 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
