# Evidence: Clipboard probe lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- The clipboard image availability continuation compared `systemClipboardImageProbeGeneration` and called
  `canProbeOriginalClipboardImage()` after its async await.
- The shared predicate omitted `lifecycleActive`; a stale system clipboard change could therefore create
  a new probe after disposal and publish availability to the old editor.
- Existing photo ingress work bound photo import and paste effects but did not cover this shared
  availability probe gate.

## Change

- Added lifecycle activity as the first condition of the shared probe predicate.
- Entry probing, stale-result rejection, generation invalidation, and paste suppression behavior remain
  unchanged.

## Verification

- Focused replay: docs/migration/replays/d02-clipboard-probe-lifecycle-bound.mjs.
- Adjacent replay: docs/migration/replays/d02-original-clipboard-image-ingress.mjs.
- Adjacent clipboard image ingress replay: 29/29.
- Full Desktop Replay: REPLAY_FILES=327 PASSED=327 FAILED_FILES=0.
- Dual HAP static build succeeded: ohosTest in 8.830 seconds; default in 50.447 seconds.
- No simulator, virtual machine, physical device, or Hypium execution.
