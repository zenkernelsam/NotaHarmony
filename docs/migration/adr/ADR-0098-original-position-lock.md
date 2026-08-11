# ADR-0098: Persist original Block and Shape position lock

## Status

Accepted, 2026-08-12. This supersedes ADR-0016's earlier assumption that a locked Block must be
excluded from the selection itself.

## Original Evidence

- Original 1.0.3 `dsc` defines distinct `LOCK` and `UNLOCK` actions at ordinals 18 and 19; `ux9`
  renders the matching strings and lock/unlock icons.
- `dhb` toggles a tapped Block through `u5j.n` and a tapped Shape through `u5j.x`. Its drawn/group
  selection branch uses `xsc.k`, which accepts Shape collections and chooses Unlock only when every
  selected Shape is already locked.
- `a1j.a` writes Shape `positionLocked` at type-19 field 14. `td8.u()` reads Block
  `positionLocked` from type-23 field 17. Both nullable registers distinguish an absent field from an
  explicitly present false value.
- Original `cz3 EntitySelectionData` retains `positionLocked`; selection must therefore preserve a
  locked entity long enough to offer Unlock, while transform/edit consumers still honor the flag.

## Decision

- Add strict type-19 field 14 and type-23 field 17 writers. Both true and false retain vtable
  presence. Shape/Text/Image/Math snapshot changes are accepted only when a byte-exact projection
  proves `positionLocked` is the sole changed field and every target has a canonical operation ID.
- Production preflight compares the before value with `original_shape_state.resolved_payload` or the
  effective CREATE/winning Block register. Missing pre-Phase-121 Shape JSON fields use the original
  FlatBuffer default false; malformed non-boolean values remain rejected.
- The selection overlay offers Lock/Unlock for one entity or a pure Shape selection, matching the
  original direct-Block and drawn-Shape branches. The command creates one `TRANSFORM_ELEMENTS`
  history action and keeps the selection active so a just-locked entity can immediately be unlocked.
- Locked Shape/Text/Image/Math entities remain rectangle/lasso selectable. Geometry consumers keep
  them immovable and object-eraser safe; Phase 121 also closes the previously missing Shape guards.

## Atomicity And History

- Shape and Block batches share one database transaction and one `OriginalPageMutationBatch`, so a
  mixed internal history step advances the page revision once even when it emits both payload types.
- Each emitted operation uses a full original envelope, the production reducer and an
  upload-immediate journal row. Snapshot reconciliation and the Harmony history companion commit in
  the same transaction. Any stale source, reducer defer, journal, reconciliation or history failure
  rolls back the entire command.
- Forward Lock, reverse Undo, Redo and explicit false Unlock all preflight against their actual
  before-state. Grouped history checks position lock before image flip/crop or position classifiers,
  preventing one register mutation from being misclassified as another.

## Verification

- ArkTS fixtures cover type-19/type-23 true and explicit false decoding, mixed Shape/Block
  classification, reverse source state, unrelated geometry rejection, locked selection and locked
  Shape transform/eraser protection.
- `d02-local-position-lock.mjs` locks original evidence, UI gates, source-state preflight,
  mixed-payload single-revision behavior, Undo/Redo and rollback. Full replay and clean build results
  are recorded in Phase 121.
- No emulator, VM, device or Hypium is used.

## Remaining Boundary

Device interaction acceptance remains pending. Local Group creation/modification, the remaining
Shape definition/tool/effect authoring registers, complete original package round-trip and private
authenticated transport/ACK remain subsequent Goal work.
