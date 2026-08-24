# Evidence: Note background continuation bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `NotePage.loadPages()` guarded note loading, page publication, and zero-page recovery continuation.
- The next asynchronous boundary, `getNoteBackground()`, returned directly into `noteBackground`, followed by page-index reset and recording loading.
- A disposed page or an overlapping reload could therefore publish stale background state after the guarded pages publication.

## Change

- Stored the awaited background result in a local value.
- Added the joint disposal/load-generation check before publishing that result.
- Preserved durable background persistence, normal publication ordering, current-page initialization, failure rollback, and recording-list behavior.

## Verification

* Focused replay: docs/migration/replays/d02-note-page-load-note-disposal-bound.mjs (5/5), now asserting await → guard → background publication ordering.
* Adjacent replays: d02-note-page-load-lifecycle-bound.mjs (4/4) and d02-editor-load-disposal-race-bound.mjs (4/4).
* Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.693 seconds; default in 50.071 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
