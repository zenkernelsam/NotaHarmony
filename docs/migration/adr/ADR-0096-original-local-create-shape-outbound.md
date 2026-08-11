# ADR-0096: Persist one locally recognized Shape as original CREATE_SHAPE

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `a5g` passes detected `ge3` page-relative origin, rotation, definition, InkTool,
  InkStyle, color, border width and average force to `u5j.j`. `u5j.j` delegates to `laj.a/m`.
- `laj.m` writes the 18-field `ao2` CREATE_SHAPE table. Fields 0/1 are page and origin, 2/3 are
  optional rotation/scale, 4/5 are the definition discriminator/table, 6/7 are tool/style, 9/10
  are color/border width, 11 is optional fill, 12 is optional z-index, 13/14 are smart-highlight
  and force, and 15/16/17 are lock/effects/tint.
- The hold-recognition call uses no fill, no explicit z-index, no smart-highlight, unlocked,
  zero effects and default tinted=true. Its optional force is the detector's average force.
- `ao2.a()` rejects variable-width style and transparent fill. `laj.m` maps LINE, POLYGON and
  NORMAL_SHAPE; the proven 1.0.3 NORMAL_SHAPE reader materializes ELLIPSE.

## Decision

- A single recognized Shape inherits the already reserved local operation identity and page/client
  metadata from its source stroke. It also stores the original tool, style and average valid input
  pressure. Multi-definition recognition never shares one identity, and variable-width recognition
  never claims original CREATE_SHAPE eligibility.
- Add a strict forward FlatBuffer encoder for type 18. It supports LINE endpoints/Bezier controls/
  arrow, closed POLYGON point vectors and rotated ELLIPSE. Ellipse center and local radii are converted
  to the original page-relative origin plus transform rotation so remote materialization is visually
  equivalent. Unsupported transforms, open/oversized polygons, illegal style/tool, fill, lock,
  rich text and non-finite values are rejected before the production route is selected.
- The reserved identity's client time remains the omitted z-index default. Existing reservation
  eligibility proves that value sorts after the current original page tail, matching the local append.
- Apply type 18 through `OriginalShapeGroupOperationApplier`, append an upload-immediate canonical
  operation, reconcile the requested snapshot, rebuild search without clearing handwriting, and append
  the Harmony history companion in one transaction and one page revision.
- Original delete/undelete classification now supports both Ink and Shape. Every target must have the
  matching `original_ink_state` or `original_shape_state` row before type 25 is emitted, preventing
  local `op:*` lookalikes from creating false delete-before-create state. Direct selection deletion,
  whole-object erasing and Undo/Redo all preserve this route for Ink/Shape-only mutations.
- Preserve original Shape style alongside tool in snapshots and legacy-state hydration. Type-19 render
  preflight now verifies both values against `resolved_payload`, so this metadata extension cannot
  regress Phase 118 color/width outbound.

## Rejected Alternatives

- Allocate a new identity inside persistence and silently rewrite the Shape ID: the live canvas and
  Undo stack would retain the temporary ID and diverge from stored state.
- Reuse one reserved identity for every item in a multi-definition recognition result: CREATE_SHAPE
  identity is the entity identity, so this would be an identity conflict rather than a batch create.
- Encode variable-width style as fixed width: original `ao2` explicitly rejects it; changing style is
  not fidelity. Such recognition remains on the established compatibility path.
- Infer page or z-index from current UI state after the fact: the reservation already carries the
  authoritative original page identity and operation time.

## Verification

- ArkTS fixtures round-trip type-18 LINE, POLYGON and rotated ELLIPSE through the production decoder,
  including tool/style, force and omitted client-time z-index, and reject variable-width style.
- Shape detector fixtures prove single-result metadata transfer and multi-result/style-0 stripping.
- `d02-local-create-shape.mjs` locks original call signatures, production wiring, state preflight,
  upload/history/revision behavior, Undo/Redo and rollback. Full desktop replay is
  `TOTAL=105 FAILED=0`.
- After `hvigor clean`, both `note@ohosTest` and `note@default` HAP builds succeed. No emulator, VM,
  device or Hypium is used.

## Remaining Boundary

Multi-definition local recognition still needs an explicit reservation pool or an atomic ID rewrite
contract; it deliberately remains on compatibility persistence today. Other Shape registers, local
Group authoring, full original package CRDT export/import, private authenticated upload/ACK and device
acceptance remain subsequent Goal work.
