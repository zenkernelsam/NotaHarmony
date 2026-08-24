# Evidence: Add page selection context bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `NotePage.addPage()` awaited durable page creation, passed the existing disposal guard, then appended the assigned page.
- It set `currentPageIndex` to the last row before publishing the new page to the Canvas child component.
- The Canvas receives page selection through a watched prop and starts an async load on change; a user switch between publication frames could be overwritten by the stale add continuation selecting the last index again.

## Change

- After disposal authorization, locate the assigned page in the updated list and set the current index before mutating history action fields or publishing pages/history.
- Keep durable creation, action normalization, undo publication, and all disposal guards unchanged.

## Verification

* Focused replay: docs/migration/replays/d02-page-operation-disposal-bound.mjs (9/9), now asserting guard → assigned selection → action/history publication ordering.
* Adjacent failure-bound replay: d02-page-operation-failure-disposal-bound.mjs (3/3).
* Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
* Dual HAP static build succeeded: ohosTest in 8.688 seconds; default in 50.121 seconds.
* No simulator, virtual machine, physical device, or Hypium execution.
