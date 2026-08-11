# ADR-0095: Persist selected Shape color and width as original MODIFY_SHAPE

## Status

Accepted, 2026-08-12. This corrects the temporary Phase 117 type-23 boundary and extends its
Selection color/width command to original Shape entities.

## Original Evidence

- A full-method JADX recovery of original 1.0.3 `zn3` case 4 partitions Shape entities by
  `n5d.Y()` InkTool. Ordinary Shapes call `u5j.x` with an alpha-255 `hu1` color. Highlighter
  Shapes pass an alpha-107 `hu1` both as color and through `kgh.c(color)` as the nullable
  fill-color setter (default masks `15870` and `13822`).
- Recovered `ks0` case 4 groups Shapes by InkTool, clamps through `w4g.a`, and calls `u5j.x` with
  a `Float` at the border-width position (mask `15358`). Unlike Ink, this branch does not call
  `aa6.f0`; Shape border width is already in the stored coordinate domain.
- The non-default `u5j.r` signature orders `hu1 color`, `Float borderWidth`, then later
  `g2d fillColor`; it forwards those positions to `o0j.a`. `le8` names the resulting registers
  `color`, `borderWidth`, and `fillColor`, and explicitly requires a nullable setter to clear fill.
- The original payload discriminator is 19. `le8`/Harmony's proven decoder map fields 10, 11 and
  12 to color, border width and nullable fill color. Type 23 is `MODIFY_BLOCK` and cannot target
  Shape entities.

## Decision

- Preserve the resolved original InkTool on `ShapeElement.originalTool`. Existing snapshots remain
  readable; loading joins `original_shape_state.resolved_payload` to hydrate pre-Phase-118 rows,
  while each new Shape reducer materialization writes the field directly.
- Selection controls use the first eligible Ink or Shape. Shape width ranges follow its own tool:
  Pen/Highlighter `0.5..30`, Pencil `1..10`, Tape `2..64`. Shape values are clamped directly and
  never multiplied by page width. Local recognized Shapes retain their source stroke's tool.
- A color command writes alpha 107 to both border and fill for Highlighter Shape. Other Shape tools
  receive alpha 255 border color and preserve their current fill register. Shape style was outside
  this phase and is subsequently closed by ADR-0097.
- Color/width actions that include Shape use one `TRANSFORM_ELEMENTS` history entry containing both
  Ink and Shape before/after values. This gives Undo/Redo exact old tuple restoration without
  manufacturing a second user action.
- The strict render classifier accepts only byte-exact projections of Ink style/color/width and
  Shape color/borderWidth/fillColor. Identity, order, tool, definition, transform, geometry, rich
  text, lock state and unrelated fields cannot ride along. Production additionally verifies every
  Shape target exists in `original_shape_state`, its resolved payload has valid tool/style metadata,
  and both exactly match the snapshot target; otherwise the established snapshot fallback is used.
- Batch targets by the exact final register tuple. Type-17 and type-19 batches share one
  `OriginalPageMutationBatch`, one transaction and one revision flush. Every canonical operation is
  upload-immediate and transparent to persistent Harmony history reconstruction.

## Rejected Alternatives

- Encode Shape through type 23: that payload belongs to Block entities and the type-19 reducer is
  already the authoritative Shape LWW state.
- Scale Shape width by `pageWidth / 768`: only the Ink branch performs that conversion.
- Infer Highlighter permanently from alpha or fill presence: filled non-Highlighter Shapes exist;
  the original dispatch reads the Shape's InkTool register.
- Emit fill updates for every Shape color change: original ordinary Shapes preserve fill, whereas
  Highlighter Shapes explicitly set it to the new alpha-107 color.

## Verification

- `OriginalCreateInkPayloadEncoder.test.ets` round-trips type-19 batched color/width, populated fill
  setter, nullable fill clear and absent fill setter through the production decoder.
- `StrokePersistence.test.ets` covers tuple partitioning, Highlighter fill, direct width values,
  split-value reverse Undo, strict state-tool decoding and rejection of unrelated Shape geometry.
- `d02-local-modify-shape-color-width.mjs` locks original signatures, production wiring, type-19
  fields, mixed type-17/type-19 batching, one revision and transaction rollback. Its output is
  `localModifyShapeColorWidth=type19-tool-alpha-fill-direct-width-mixed-type17-tuple-batches-single-revision-undo-rollback`.
- No emulator, VM, device or Hypium is used. Device acceptance remains required for visual alpha,
  mixed selections, range switching, restart Undo/Redo and remote replay.

## Remaining Boundary

Other Shape registers except style, original local CREATE_SHAPE authoring, private authenticated upload/ACK,
format closure and concentrated device acceptance remain outside this phase and the Goal stays active.
