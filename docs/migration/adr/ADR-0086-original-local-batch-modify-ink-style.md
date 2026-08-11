# ADR-0086: Persist local batch Ink style edits as original MODIFY_INK

## Status

Accepted, 2026-08-11.

## Original Evidence

- Original 1.0.3 `zg9` is `OnBrushStyleClick`; `ti9` dispatches it through coroutine case 27.
- `zh9.u` partitions the current selected entity IDs, excludes Ink and Shape entities whose tool
  is `PENCIL`, and reports `No selected ids to modify` when both supported sets are empty.
- For all selected Ink IDs, `zh9.u` calls `u5j.q(..., null, null, l2f.a(style), 28670)` exactly
  once. `u5j.q` validates every Ink, resolves their common page/origin and delegates to `o0j.a`.
- The resulting 19-field `wd8` MODIFY_INK table contains field 0 target IDs and field 5 style.
  `u5j.q` also supplies an empty field 12 style-map vector whenever style is present. Its nullable
  color and width parameters map to fields 6 and 7, but this production call does not set them.

## Decision

- Expose the four original style options in the Selection tool tray. This command changes selected
  Ink only; it does not mutate the active drawing tool preset. Pencil and persistent partial-eraser
  Ink are ignored, matching the original selection behavior and current non-selectability rules.
- One user command replaces all eligible selected strokes in memory, clears their style maps, and
  records one `TRANSFORM_STROKES` before/after action. Undo and Redo replace the same identities and
  use the existing durable page-mutation history companion.
- Classify an original outbound style edit only when the page element identity/order is unchanged,
  every changed element is a canonical non-Pencil Ink, every target receives the same style, and
  encoding the old stroke with only `inkStyle` changed and `styleMap=[]` exactly equals the requested
  snapshot. Any path, transform, mask, tool, color, width, effect, timing or metadata change rejects
  the classifier and follows the persistent v59 guard fallback.
- Encode one type-17 MODIFY_INK operation for the whole target vector. Apply it through the existing
  LWW reducer, append an upload-immediate original outbound row, reconcile the requested snapshot,
  and append the Harmony history companion under the shared editor mutex and database transaction.
  Reducer defer, revision mismatch, append failure or reconciliation failure rolls everything back.
- The encoder supports nullable style/color/width because those are the proven `u5j.q` parameters
  and `wd8` fields. The current production selection command emits style only; color and width will
  not be exposed as selected-Ink authoring until a direct original call path is established.
- Preserve optional field presence, `isPartialEraser`, and `originalCreate` in stroke snapshots so a
  history/style clone cannot silently alter payload identity or tool semantics.

## Verification

- `OriginalCreateInkPayloadEncoder.test.ets` round-trips a two-target field 0/5/6/7/12 payload
  through the production MODIFY_INK decoder and verifies the required empty style-map vector.
- `d02-local-modify-ink-style.mjs` locks the original dispatch/writer evidence, production wiring,
  Pencil filter, single batch transaction, history transparency, rollback and snapshot identity.
- Full replay and clean sequential HAP results are recorded in the Phase 109 report.

## Remaining Boundary

This decision does not claim selected-Ink color/width UI, local center-path replacement,
ADD_PATH_ELEMENTS streaming, Shape style outbound, or private upload/ACK transport completion.
Exact dashed/dotted phase and variable-width rendering still require device comparison. No emulator,
VM or device was started.

## Phase 110 Correction

The Phase 109 `wd8` encoder and strict snapshot classifier were valid, but the reducer was passed
the payload child directly. Phase 110 wraps it in a complete local `uq9`, applies that operation,
and stores the identical complete bytes in `operation_log`. Thus the style production transaction
described above becomes effective only with Phase 110.
