# Evidence: Original Text Commit Page Boundary (2026-08-23)

## Harmony Gap

- `NoteCanvasView.onTextCommit()` used one branch for styled original Text updates. The branch awaited
  `StrokePersistence.previewOriginalTextEdit()`, whose implementation flushes pending page work before
  planning the mutation.
- After resuming, the code checked only `editingTextBlock`, `editingOriginalTextBlock`,
  `currentPage.pageId`, and `loadedPageId`. Those values can all match after a same-ID page reload,
  while `pageLoadGeneration`, loading state, lifecycle health, or load-failure state differ.
- Consequently, a late successful preview could call `replaceTextBlock()` and push
  `REPLACE_ELEMENT` history into newly installed page state.

## Fix

- Capture `generation = pageLoadGeneration` before the first await.
- Keep the two editing-reference checks after preview completion.
- Add the shared `isHistoryPageContextCurrent(generation, pageId)` check already proven by Phase 311.
- On stale context, emit `original Text edit rejected after page changed` and return `false`; do not
  replace the block, push undo state, clear editing draft state as success, or persist locally.
- Leave synchronous local Text creation/update branches unchanged because they have no await boundary.

## Verification

- New Replay:
  `docs/migration/replays/d02-original-text-commit-page-bound.mjs`
  asserts pre-await capture, healthy-context gating, stale rejection logging, and suppression before
  replacement/history installation.
- Adjacent local styled Text, deferred editor result, and deferred history Replays pass.
- ArkTS diagnostics for `NoteCanvasView.ets`: no errors beyond pre-existing warnings/informational
  items.
- Full Desktop Replay: `REPLAY_FILES=280 PASSED=280 FAILED=0`.
- Static unsigned packaging: `note@ohosTest` `BUILD SUCCESSFUL in 9 s 945 ms`; `note@default`
  `BUILD SUCCESSFUL in 16 s 639 ms`.
