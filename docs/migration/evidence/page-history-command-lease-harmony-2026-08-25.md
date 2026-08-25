# Evidence: Page history command lease

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- Harmony cross-page undo/redo stores `pendingHistoryDirection`, then calls `onRequestPage()` and waits for
  the target page load.
- During that load, `PageManagerBar` prev/next callbacks checked only `pageLoading` and
  `pageOperationBusy`; a second navigation could start another page load before resume.
- `resumePendingHistory()` requires `loadedPageId === currentPage.pageId`. After an intervening navigation,
  the pending direction could either execute on the wrong loaded page or be cleared by the Phase 402
  invalid-context gate without executing.

## Reverse-engineering comparison

- Original 1.0.3 text history dispatch is serialized by the model op queue: `dd8.a()` returns unless its
  pending register is null and the queue is empty; only then does it invoke rollback (`pje` case 0).
- The queue therefore makes one command own the editor state until completion. Navigation must not replace
  the target while a queued/pending Harmony history move exists.

## Change

- Added an explicit page-level `historyPending` lease.
- Canvas notifies the page before setting a pending direction and requesting the action page, and releases
  the lease immediately after consuming the direction in `resumePendingHistory()`.
- Prev/next navigation now requires no loading, no page operation, and no held history lease.

## Verification

* New focused replay: docs/migration/replays/d02-page-history-command-lease-bound.mjs (9/9), covering all
  six cross-page branches, release-before-resume ordering, callback wiring, and both navigation gates.
* Adjacent replays: d02-pending-history-resume-context-bound.mjs (5/5),
  d02-note-page-navigation-busy-gate.mjs (6/6), d02-page-history-lifecycle-bound.mjs (12/12).
* ArkTS diagnostics for NoteCanvasView.ets and NotePage.ets contain no errors; only existing unused-symbol
  warnings and SDK deprecation notices remain.
* Full Desktop Replay passed 371/371. Clean plus dual static HAP builds succeeded:
  ohosTest in 8.438s and default in 51.858s. No emulator, VM, device, or Hypium was started.
