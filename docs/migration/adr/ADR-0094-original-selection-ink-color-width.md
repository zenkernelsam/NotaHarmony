# ADR-0094: Persist selected Ink color and width as original MODIFY_INK

## Status

Accepted, 2026-08-12. This extends ADR-0086 after establishing the original color and width call
paths and closes the selected-Ink render-register boundary left by Phase 109.

## Original Evidence

- Original 1.0.3 `wj9` case 11 dispatches selected color through `zn3`. Its recovered coroutine
  partitions Highlighter Ink from ordinary Ink, forces Highlighter alpha to `107/255`, forces
  ordinary Ink alpha to `255/255`, and calls `u5j.q` once per resulting color group. Pencil is not
  excluded from this color path. Shape color is submitted separately as type-23.
- `dhb`/`fsc` dispatch selected width through `ks0(..., case 4)`. Targets are partitioned by Ink tool
  type before `u5j.q` writes width. `w4g.a` proves the original tool ranges: Pen/Highlighter
  `0.5..30`, Pencil `1..10`, and Tape `2..64`.
- `aa6` converts the control value to persisted page units with `controlWidth * pageWidth / 768`.
- `u5j.q` delegates to `o0j.a`; its `wd8` fields are style 5, RGBA color 6 and width 7. It supplies
  an empty field-12 style-map vector only when style is present. Color-only and width-only updates
  must leave field 12 absent.
- Original Pencil rendering (`q06`/`p16`/`wg6`/`cfa`) materializes splats from the complete current
  center path, winning width, and first style-map seed/reference. A width register update therefore
  cannot retain old splats.

## Decision

- Reuse the existing toolbar color and width panels in Selection mode without modifying the active
  drawing-tool preset. The panel value follows the first eligible selected Ink. Its range follows
  that Ink's original tool range; mixed selections still clamp every target by its own tool range.
- One UI command clones every eligible selected Ink, records one `TRANSFORM_STROKES` history action,
  persists once, and redraws once. Partial-eraser Ink remains excluded. Style still excludes Pencil,
  while color and width include it as proven by their separate original paths.
- Normalize selected color alpha by target: Highlighter `107`, all other Ink `255`. Convert selected
  width through `pageWidth / 768`; clamp Tape, Pencil and other Ink to their original ranges.
- Add a pure original Pencil width materializer shared by Canvas and persistence classification. It
  reruns `PencilSplatGenerator` with the stored seed/reference and the new spacing. Bounds use the
  original control-point hull and `2.84` Pencil width multiplier. Because persisted cubics lose the
  original element tag, recover a quadratic's float32/half control point by checking neighboring
  float32 candidates against both original quadratic-to-cubic equations; otherwise consume the
  cubic controls. Custom/fill control hulls participate in the same union as the reducer.
- Extend the strict snapshot classifier from style to style/color/width. It compares the complete
  candidate payload, including rebuilt Pencil splats and bounds, and rejects identity/order, path,
  mask, transform, effect, timing, tool, partial-eraser or unrelated changes. Undo may restore
  different old register values, so targets are grouped by the exact resulting register tuple.
- Allocate one canonical operation identity per tuple and encode a complete type-17 envelope. Apply
  every tuple through `OriginalModifyInkOperationApplier.applyPositionPayload` with one shared
  `OriginalPageMutationBatch`, append each upload-immediate operation, then flush one page revision.
  Reducer defer, snapshot divergence, journal failure, history failure, or any later batch failure
  rolls back the whole command.

## Rejected Alternatives

- Preserve old Pencil splats after width changes: this diverges from the original renderer and from
  the production reducer's deterministic materialization.
- Adjust Pencil world bounds by subtracting old padding and adding new padding: mathematically
  equivalent but floating operation order changes serialized numbers for most transformed strokes.
- Always include an empty style map: original `u5j.q` does so for style, not color-only or width-only.
- Emit one operation per target: the original batches targets with the same effective register value
  and one user command must remain one revision/transaction.
- Treat selected Shape color/width as Ink: original Shape uses a separate type-23 path and remains a
  later outbound phase.

## Verification

- `d02-local-modify-ink-color-width.mjs` locks original dispatch, field presence, alpha, per-tool
  ranges, page scaling, Pencil rebuild, effective-value batching, one revision, split-value Undo and
  transaction rollback. Full desktop replay is `TOTAL=103 FAILED=0`.
- ArkTS fixtures round-trip color-only and width-only type-17 fields without style-map presence. The
  Pencil fixture verifies deterministic splats, rotated/non-uniform bounds, recovered quadratic
  control hulls and auxiliary-path union. The clean `note@ohosTest` HAP compiles these fixtures.
- After `hvigor clean`, sequential `note@ohosTest` and `note@default` HAP builds both complete with
  `BUILD SUCCESSFUL`. No emulator, VM, device or Hypium was started.

## Remaining Boundary

Selected Shape color/width and other Shape render registers still require their original type-23
outbound phase. Device acceptance still needs mixed Pen/Highlighter/Pencil/Tape selections, slider
range switching, alpha rendering, Pencil texture/bounds, restart Undo/Redo and remote replay. Private
authenticated upload/ACK and the wider remaining migration goal are not closed by this decision.
