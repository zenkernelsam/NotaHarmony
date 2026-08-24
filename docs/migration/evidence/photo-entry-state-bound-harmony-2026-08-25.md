# Evidence: Photo entry state bound

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `canStartOriginalPhotoInsert()` and `canUseOriginalClipboardImage()` checked loaded health, busy state, persistence, and a non-empty page ID.
- Neither entry checked canvas disposal or current-page identity, although both cross asynchronous UI boundaries.
- A stale signal could therefore open the photo picker, request clipboard read permission, or set `photoImportBusy` before later continuation guards ran.

## Change

- Added `lifecycleActive` to both startup predicates.
- Added `loadedPageId === currentPage.pageId` identity agreement.
- Preserved all existing continuation guards, durable insertion semantics, busy cleanup, and active-page feedback.

## Verification

- Focused replay: docs/migration/replays/d02-photo-entry-state-bound.mjs (15/15).
- Strengthened adjacent replay: d02-photo-ingress-disposal-bound.mjs now also requires full startup gates (8/8).
- Strengthened existing clipboard ingress replay assertions for lifecycle and current-page identity (29/29).
- Full Desktop Replay: REPLAY_FILES=360 PASSED=360 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 8.614 seconds; default in 51.137 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
