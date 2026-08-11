# ADR-0063: Treat original Math as an editable positionable Block

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `u08` is the Math Block implementation and implements `be5`, the common
  positionable Block contract. It delegates bounds, transform, rotation, scale, z-index and lock
  state to the same `ry0` common block state used by the editor's positionable model.
- `fu1/xtc` perform selection over `be5` positionables before Group membership expansion. Math is
  therefore an ordinary selectable Group leaf, not a display-only import artifact.
- `u08.u()` implements the original copy contract and serializes the Math Block with its LaTeX,
  color and common position state. A Harmony clipboard path that silently omits Math is not
  compatible with that behavior.
- Math uses the same affine transform semantics as Text and Image Blocks. Position lock prevents
  direct or Group-derived editing; geometry consumers must use the transformed block quadrilateral,
  not only an unrotated local rectangle.

## Decision

- Add Math to `SelectionState`, rectangle/lasso hit testing and Group leaf availability. Locked Math
  remains excluded, while a valid Group containing Math now expands atomically with its other leaves.
- Apply drag, scale, rotation and flip by left-multiplying the existing affine transform, then
  recompute rotation and world bounds. Preserve pre-drag Math snapshots so cancellation restores the
  exact source state.
- Include Math in selection overlay bounds, eraser hit testing, delete/cut, element-order movement,
  copy/paste and fresh-ID collision checks. Eraser collision uses the transformed quadrilateral and
  finite segment distance with the eraser radius.
- Extend mixed ADD/DELETE/TRANSFORM/ERASE history actions with optional Math snapshots and indices.
  Optional fields keep previously persisted/in-memory action shapes compatible; all apply, undo,
  source-state validation, element-order validation and history-size paths consume Math.
- Deep-copy Math clipboard snapshots, offset the transform, recompute bounds and preserve relative
  z-order across Stroke, Shape, Text, Image and Math.

## Verification

- ArkTS tests cover Math transform/bounds and position lock, transformed eraser collision and lock,
  Group expansion to Math, Math z-order movement, deep-copy/fresh-ID clipboard behavior and mixed
  five-kind order preservation.
- `d02-math-editing-consumer.mjs` locks the original `u08/be5` evidence and the production selection,
  Group, geometry, history, order, clipboard and canvas wiring.
- Desktop replay and clean HAP build results are recorded in the Phase 85 report; no simulator,
  device or Hypium run is claimed.

## Remaining Boundary

This decision closes the existing Math Block's editor consumer lifecycle. ADR-0124 later completes
the LaTeX editing UI and original MODIFY_BLOCK field-10 writer. Original CREATE_BLOCK authoring, a
replacement for the original native formula layout engine, and device-level formula pixel
verification remain separate boundaries. Group
identity-preserving copy/paste still depends on separate Group writers rather than the leaf-only
clipboard completed here.
