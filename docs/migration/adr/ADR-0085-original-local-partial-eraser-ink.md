# ADR-0085: Persist local partial eraser as original tool-5 Ink

## Status

Accepted, 2026-08-11.

## Original Evidence

- Original 1.0.3 `u16` declares `PARTIAL_ERASER((byte) 5)`.
- In `kt1`, the partial-eraser input branch selects `u16.PARTIAL_ERASER` and then calls
  `u5j.g(...)`, the same Ink creation path used by other persistent tools.
- The resulting entity is therefore a CREATE_INK whose tool field is 5. It is not a set of
  MODIFY_INK center-path replacements for every crossed Ink. MODIFY_INK field 8 remains a
  separate center-path register operation.

## Decision

- A local partial-eraser gesture consumes the same reserved canonical operation identity as a
  drawable Ink gesture and creates one fixed-width Ink with tool 5. Its path, z-order, audio time,
  local snapshot and original outbound row share that identity.
- Encode `RenderSpec.isPartialEraser` as CREATE_INK tool 5. The original reducer accepts tool 5 and
  materializes the flag; MODIFY_INK reconstruction and self-owned package validation preserve it.
- Render tool-5 Ink with `destination-out`, round caps and the Ink's own width. A single-point tap
  emits a zero-length line segment so the round cap is visible.
- Preserve original element ordering. Pages containing a tool-5 Ink render all ordered elements to
  a transparent offscreen content layer, then composite that layer over paper/PDF. This prevents
  destination-out from punching the page background transparent and still lets later Ink appear
  above an earlier eraser.
- Tool-5 Ink is not directly selectable and is ignored by whole/partial eraser hit testing. Its
  lifecycle is controlled through the gesture's ADD_STROKE history entry; Undo/Redo uses the
  existing canonical DELETE_ENTITIES delete/undelete path.
- If the current page cannot reserve original authoring identity, keep the legacy local mask
  fallback. Partial erasing must never delete an entire Shape, Text, Image or Math element; object
  deletion remains exclusive to whole eraser mode.
- On cancellation, discard the consumed identity and asynchronously reserve a fresh one for the
  same page/generation. On successful persistence, rearm only after the original transaction
  completes.

## Verification

- `OriginalCreateInkPayloadEncoder.test.ets` verifies tool 5 round-trip and reducer eligibility.
- `d02-local-partial-eraser-ink.mjs` locks the original tool evidence, encoder/reducer/renderer
  wiring, z-order, Undo/Redo visibility and paper-safe content-layer boundary.
- Full replay and clean sequential HAP results are recorded in the Phase 108 report.

## Remaining Boundary

This decision does not implement local MODIFY_INK center-path replacement or ADD_PATH_ELEMENTS
streaming. Device pixel comparison is still required for exact eraser width, caps, rapid gesture
sampling and performance. No emulator, VM or device was started.
