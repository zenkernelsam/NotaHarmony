# Evidence: Photo ingress disposal bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- `startOriginalPhotoInsert()`: late pick/import failures could toast after disposal because guards omitted
  `lifecycleActive`.
- `startOriginalClipboardImagePaste()`: availability probes, permission interruption, import completion, and
  failure toasts used only page generation/page ID.
- Both paths reset the current component's busy flag in `finally`.

## Change

- Added one shared photo-context identity check requiring lifecycle activity plus current page context.
- Bound all user-visible photo-ingress effects and clipboard state writes behind that check.
- Kept stale durable successes authoritative per ADR-0321 and left busy cleanup unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-photo-ingress-disposal-bound.mjs (8/8).
- Adjacent stale-context replay remained green: d02-partial-erase-photo-stale-bound.mjs (9/9).
- Full Desktop Replay: `REPLAY_FILES=319 PASSED=319 FAILED_FILES=0`.
- Existing `d02-original-clipboard-image-ingress.mjs` was strengthened for the shared photo-context guard (29/29).
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 8 s 811 ms; main BUILD SUCCESSFUL in 52 s 237 ms.
- No simulator, virtual machine, physical device, or Hypium execution.
