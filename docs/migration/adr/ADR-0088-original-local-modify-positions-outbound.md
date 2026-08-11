# ADR-0088: Persist local selection transforms as original MODIFY_POSITIONS

## Status

Accepted, 2026-08-11.

## Original Evidence

- Original 1.0.3 `avc.l/o/p/q/t` converts one completed selection translation, rotation or scale
  gesture into a list of `ie8` ModifyPosition rows. `je8VarQ.j() > 0` is then appended as one
  durable `wq9`; the same completion also appends the interaction-ended operation.
- `w0j.e` writes six independent fields per row: required target, nullable page, nullable origin,
  nullable rotation setter, nullable scale setter and nullable uint64 zIndex. `x0j.m/n` wraps the
  rows as payload type 24. A field is absent when that register did not change.
- Translation writes page+origin. Rotation and scale around a pivot can also change origin; the
  writer includes only the registers produced by that gesture. The operation may mix Ink, Block
  and Shape targets and is rejected when the same target appears twice.
- `u5j.v` exposes the validated writer. By contrast, no production call to the available
  center-path replacement helper was found in 1.0.3, so that unsupported path is not used as the
  basis for this phase.

## Problem

Harmony already changed Ink, Shape, Text, Image and Math matrices during selection gestures and
stored a `TRANSFORM_ELEMENTS` history action, but `StrokePersistence` fell through to a private
page mutation. On an otherwise original-aligned page that also set the local authoring guard,
preventing the next stroke from reserving an original CREATE_INK identity. Undo/Redo likewise
materialized only the private snapshot. The incoming type-24 reducer from Phase 75 therefore had
no local production path.

Exact JSON matrix comparisons introduced a second failure. Original origin/rotation/scale fields
are float32, while Harmony gesture matrices use JavaScript numbers. After reconciliation, a later
valid transform could differ from the register-derived matrix only by float32 rounding and be
incorrectly rejected as divergent.

## Decision

- Add a type-24 encoder with the original six-field row layout, vector-of-tables root, nullable
  rotation/scale setters and precision-safe uint64 zIndex support. It rejects empty batches,
  duplicate targets, empty rows, invalid identities and non-finite geometry.
- Add a strict snapshot classifier. Identity and element order must be unchanged; every changed
  row must be a canonical original Ink, Text/Image/Math Block or Shape, and must differ only in its
  transform plus the model-derived bounds/rotation fields. The affine matrix must decompose into
  positive scale, rotation and origin with no shear, reflection or perspective. Mixed/local pages
  and any unrelated field change retain the existing private fallback.
- Emit only registers that changed. Local selection does not move between pages or change zIndex,
  so page identity is paired with origin only when translation changed, and zIndex remains absent.
- In the editor persistence mutex and one database transaction, allocate one identity, build a
  complete local `uq9`, apply it through the production type-24 reducer, append the same bytes as
  upload-immediate `ORIGINAL_MODIFY_POSITIONS`, reconcile the exact editor snapshot and append the
  Harmony history companion. Grouped Undo/Redo uses the same path for every step.
- Preserve `originalCreate` while copying a transformed Stroke. A transform containing only
  canonical original targets keeps the page eligible for later original authoring, including after
  Undo/Redo; mixed or local targets still invalidate that eligibility.
- Compare reducer matrices and Block-derived bounds using a relative epsilon appropriate for an
  original float32 wire boundary. This does not allow shear or arbitrary geometry; the outbound
  classifier remains strict and the source snapshot must otherwise match byte-for-byte.

## Rejected Alternatives

- Implement center-path replacement first: 1.0.3 contains decoder/writer support but no verified
  user-production call, whereas selection transforms have direct durable call sites.
- Store a type-24 child table without `uq9`: Phase 110 established that reducers, replay and upload
  require the complete operation envelope.
- Encode every matrix as page+rotation+scale regardless of change: that creates unnecessary LWW
  winners and differs from the original gesture writer's nullable field semantics.
- Treat reflection or shear as ordinary scale: the verified production calls do not prove that
  contract. Harmony Flip continues through the conservative private fallback.

## Verification

- ArkTS fixture round-trips a two-target payload through the production decoder, including page,
  origin, non-null and explicit-null setters, and maximum uint64 zIndex.
- `d02-local-modify-positions-outbound.mjs` locks the original `avc/u5j/x0j/w0j` evidence, writer,
  history and page-eligibility wiring; it checks decomposition rejection and simulates mixed-target
  LWW apply, upload journal metadata and injected transactional rollback.
- Full replay and clean sequential HAP results are recorded in the Phase 111 report.

## Remaining Boundary

This phase covers same-page positive-scale selection transforms. Cross-page moves, z-order gestures,
reflection/Flip parity, Group CREATE/MODIFY/ungroup outbound, transient collaboration preview,
authenticated upload/ACK and device interaction/pixel verification remain separate work. No
emulator, VM, device or Hypium run is part of this decision.
