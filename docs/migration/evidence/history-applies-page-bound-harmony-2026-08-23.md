# Evidence: Async History Application Page Boundary (2026-08-23)

## Original 1.0.3

- `v69.java` reducer case `20` treats Group as durable op state by installing the group entity and
  changed members; this confirms that a persisted history move is not merely transient UI state.
- `de2.java` owns `qd2()` and `ud2.java` receives the active page index; `qd2.java` names it
  `currentPageIndex`. Current-page UI therefore remains tied to an explicit active page context even
  though operation persistence is durable.

## Harmony Gap And Fix

- Before this phase, `historyBusy` blocked another history command but did not block
  `switchPageData()`. Async Undo/Redo paths could resume after generation changed and then install
  old arrays/groups, selection, layers, eligibility, asset refreshes, render frames, or global failure
  feedback onto the new page.
- `NoteCanvasView.ets` now records `pageLoadGeneration` before each deferred apply and checks
  `isHistoryPageContextCurrent(generation, action.pageId)`. This predicate requires lifecycle,
  matching generation/page/current page, loaded data, and absence of loading/load failure.
- Successful stale applies log that durable history remains available, advance/notify the already
  committed stack where applicable, and return before page-local installation.
- Stale failures keep hilog diagnostics but do not report save failure on the new page.
- Generic grouped history additionally checks after `flush()` before mutating snapshots, after
  `saveHistoryGroup()`, and gates rollback/image refresh/reporting to the originating page context.

## Verification

- New Replay:
  `docs/migration/replays/d02-deferred-history-moves-page-bound.mjs`
  asserts the five stale-success boundaries, the shared context predicate, pre-flush group refusal,
  and per-function guards for all four dedicated async history moves.
- Adjacent history/coalesce/group-paste/checkpoint/recovery Replays pass.
- Full Desktop Replay: `REPLAY_FILES=279 PASSED=279 FAILED=0`.
- ArkTS diagnostics for `NoteCanvasView.ets`: no errors; existing warnings/informational items only.
