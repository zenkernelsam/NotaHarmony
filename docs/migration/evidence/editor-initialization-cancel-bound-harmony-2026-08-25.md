# Evidence: Editor initialization cancel bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `NotePage.loadPages()` initialized the shared `'primary-editor'` toolbox after several awaits.
- The old ViewModel continuation had no disposal/generation cancellation and could bind loaded state, publish UI values, or perform durable default/toolbox writes after page teardown.
- Thumbnail renderer disposal was reviewed as Candidate A but is serialized by `thumbnailRefreshMutex`; it was recorded as a false positive.

## Change

- Added an optional lifecycle gate to `EditorViewModel.initialize()`.
- Checked the gate before repository binding and after every initialization await, including each durable missing/default/toolbox write boundary.
- Passed a joint `editorDisposed` plus `pageLoadGeneration` gate from `NotePage`.

## Verification

- Focused replay: docs/migration/replays/d02-editor-viewmodel-initialization-cancel-bound.mjs (7/7).
- Strengthened adjacent replays: editor initialization disposal 6/6 and NotePage load disposal 5/5.
- Full Desktop Replay: REPLAY_FILES=357 PASSED=357 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 14.553 seconds; default in 57.419 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
