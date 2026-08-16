# ADR-0106: Persist representable single-element clipboard Paste as original CREATE

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `lg2.g()` recursively resolves selected Group descendants before copying. It calls
  `u5j.c()`, which delegates to the model copy authoring path and returns newly generated operations;
  copied entities do not reuse their source CREATE identity.
- `lg2.e()` later inspects the generated operation list, extracts `CREATE_GROUP` operations and
  removes nested child Groups from the top-level pasted selection. Group identity and hierarchy are
  therefore part of Paste, not merely a flat list of leaf snapshots.
- Original Ink, Shape and Block identities are their CREATE operation identities. A locally pasted
  entity must reserve a fresh operation identity and persist the matching type 17, 18 or 22 CREATE,
  followed by Text's type 8 initial INSERT where applicable.

## Decision

- Clipboard clones clear `originalCreate`. Source reservation metadata belongs only to the source
  operation and must never survive Copy or Cut.
- A single canonical Ink, Shape or non-empty unstyled Text may request a fresh original identity.
  Before reservation, run the production CREATE encoder against the clipboard snapshot. Missing
  Shape tool/style, unsupported geometry, masks/fills, invalid Block defaults, styles and other
  unrepresentable state reject the original path without consuming an identity.
- Assign the reserved `op:<timestamp>:<site>` ID and matching CREATE metadata only to the pasted
  clone. Persist with original authoring enabled so `StrokePersistence.singleReservedOriginalCreate`
  selects CREATE_INK, CREATE_SHAPE or CREATE_BLOCK plus initial INSERT_STRING.
- CREATE_INK and CREATE_SHAPE require page-space geometry with an identity transform. Clipboard
  offset is therefore materialized into Ink path/derived points and Shape semantic geometry before
  resetting the transform. Text keeps its representable affine placement because CREATE_BLOCK
  encodes origin, rotation and scale.
- Keep the existing single `ADD_ELEMENTS` history action. Undo and Redo persist as type-25 entity
  visibility operations against the same freshly created identity.

## Conservative Boundary

- Image, Math, empty Text, styled Text, Shape RichText, unrepresentable transformed Ink/Shape,
  multi-element Paste and any selection containing an original Group remain on the compatibility
  snapshot path.
- This is an explicit incomplete boundary, not an assertion that original Paste is flat. Full
  fidelity needs atomic leaf CREATE operations, nested-to-top-level CREATE_GROUP ordering, compound
  persistent history and rollback across the whole pasted graph.
- A page that cannot reserve an original identity continues to accept compatibility Paste rather
  than dropping the user's command. Canonical state is never mislabeled as original CREATE when its
  strict encoder rejects it.

## Verification

- `StrokeClipboard.test.ets` proves reservation removal, Group/style guards, deep candidate copies,
  partial-eraser flag retention and page-space offset materialization for Ink and Shape.
- `d02-original-single-clipboard-paste.mjs` locks the original `lg2/u5j` evidence, strict encoder
  wiring, fresh identity flow, type 17/18/22 CREATE, type-25 Undo/Redo and transaction rollback.
- Full replay and clean HAP build results are recorded in the Phase 129 report.

## Phase 262 correction

ADR-0106 originally inherited the compatibility clipboard's `20 * pasteSequence` placement. Direct evidence from
`w43/v49/t39/lg2.f()` now proves ordinary Paste uses the requested document position relative to the copied bounds center;
`cg2.a()`'s ten-percent/capped offset belongs to Duplicate. `StrokeClipboard` therefore uses target-center translation plus
page-edge clamp, and sequence only contributes to fresh identity.

Paste is now prepare/commit: a failed save enqueue does not consume sequence, and commit also checks the published clipboard
revision so a newer Copy invalidates an older asynchronous preparation. The explicit prepared-history enqueue replaces the old
follow-up `persist()` call. See ADR-0240 and the Phase 262 evidence/report.
