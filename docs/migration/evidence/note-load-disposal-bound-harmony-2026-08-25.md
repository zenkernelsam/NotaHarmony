# Evidence: Note load disposal bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- The success continuation after fetching note metadata checked only the captured load generation.
- Later continuations in `loadPages()` and the failure path already checked both disposal and generation.
- A disposed page could therefore receive a stale title and continue publishing page state.

## Change

- Strengthened the post-getNote continuation to require both no disposal and the current load generation.
- Stale or disposed continuations return before assigning noteTitle, loading pages, refreshing background, or loading recordings.
- Active-page load semantics, generation replacement, failure publication guards, and finally cleanup remain unchanged.

## Actual verification

- Focused replay: docs/migration/replays/d02-note-page-load-note-disposal-bound.mjs (4/4).
- Adjacent replays strengthened: d02-note-page-load-lifecycle-bound.mjs (4/4) and d02-editor-initialization-disposal-bound.mjs (5/5).
- Full Desktop Replay: REPLAY_FILES=354 PASSED=354 FAILED_FILES=0 (actual repository count).
- Dual HAP static build succeeded after clean: ohosTest in 11.935 seconds; default in 61.648 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.