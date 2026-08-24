# Evidence: Delete page flush identity bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- Page deletion captured its target and successor before awaiting `historyBridge.flushCurrentPage()`.
- The flush can await the canvas load promise, so a pending page switch could complete during the wait.
- The old continuation then snapshotted whatever became current, deleted the originally selected durable row, and published a stale remaining-page list to switched UI.

## Change

- Added an identity gate after flush: deletion continues only when the parent's current page is still the originally selected page.
- Kept the precomputed `selectedAfter` value and applied it after publishing the remaining list.
- Preserved disposal guards, delete rollback/cancellation, history metadata, and durable semantics.

## Verification

* Focused replay: docs/migration/replays/d02-page-operation-disposal-bound.mjs (11/11), now asserting flush → identity gate → snapshot ordering plus captured-successor selection.
* Adjacent failure-bound replay: d02-page-operation-failure-disposal-bound.mjs (3/3).
* Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.610 seconds; default in 48.402 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
