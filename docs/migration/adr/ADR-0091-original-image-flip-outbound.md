# ADR-0091: Persist selection Flip as original per-Image MODIFY_BLOCK operations

## Status

Accepted, 2026-08-11. This supersedes the generic reflection behavior recorded by the early
selection reports and closes the Reflection/Flip boundary left by ADR-0088 through ADR-0090 for
the production command that actually exists in original 1.0.3.

## Original Evidence

- Original `dsc` ordinals 16/17 dispatch through `dhb` to `mub` with `tk4.HORIZONTAL` or
  `tk4.VERTICAL` and the selected entity set.
- JADX fallback for `mub.invokeSuspend` case 5 shows that it filters each target to `hp5` Image,
  toggles `hp5.R()` or `hp5.S()` independently, builds one singleton `u5j.o` operation per Image,
  and submits the resulting operation list atomically through `xsc.i`.
- For a cropped Image, the same branch mirrors the crop origin inside the intrinsic asset width or
  height and includes the resulting `p2d` crop setter in that Image's operation.
- `u5j.n` writes an 18-field `td8`: fields 12, 14 and 15 are crop, horizontal flip and vertical
  flip. The FlatBuffer builder's forced-default mode preserves an explicit `false` boolean.
- `td8.a()` groups crop and both flip fields as Image-specific, while `rl2.a()` rejects flipping a
  non-Image Block. Flip is therefore not a negative-scale type-24 position operation.

## Problem

Harmony's `flipSelected()` reflected the complete Stroke/Shape/Text/Image/Math selection around its
bounding-box center with a negative-determinant transform, then attempted generic persistence.
Phase 111 correctly rejects reflection in `MODIFY_POSITIONS`, so an original-aligned page fell into
the private snapshot path and lost original authoring eligibility. The UI also offered Flip for
targets that original 1.0.3 explicitly refuses.

Writing one common flip value for a multi-Image selection would still be wrong: original toggles
each Image independently, so Images that begin with different register values end with different
values. Ignoring crop reflection would also change the visible cropped region after the flip.

## Decision

- `OriginalModifyBlockPayloadEncoder` emits the original inline Block identity vector, optional
  `p2d` crop setter and present field-14/15 booleans, including explicit `false`.
- The snapshot classifier accepts only stable identity/order and canonical Image targets. Every
  changed target must alter exactly one common axis and, when cropped, the exact original reflected
  crop; all other serialized fields must remain byte-identical.
- Persistence allocates one operation identity and one singleton type-23 `MODIFY_BLOCK` per changed
  Image. Production reducers share `OriginalPageMutationBatch`, so the operation list advances the
  Harmony page revision once. Reducer state, upload-immediate operation rows, snapshot reconciliation
  and the history companion remain in the editor's single transaction and roll back together.
- `ORIGINAL_MODIFY_BLOCK` is a distinct local journal type. Both it and the previously omitted
  `ORIGINAL_MODIFY_POSITIONS` are transparent companions in persistent-history reconstruction.
- The editor toggles only unlocked, direct, pure-Image selections. Transform, bounds and rotation
  remain unchanged; crop is mirrored with float32 arithmetic. Flip menu entries are absent for
  Stroke, Shape, Text, Math, Group, mixed or locked selections, and the handler repeats the gate.
- Existing `TRANSFORM_ELEMENTS` history snapshots carry only before/after Images. Undo and Redo are
  classified again and emit the opposite original register values without inventing a reflection.

## Rejected Alternatives

- Encode Flip as negative scale in type 24: original uses Image-only type 23, and the position
  reducer correctly rejects negative determinant matrices.
- Emit one batched type-23 operation with a common final boolean: this fails mixed initial states and
  differs from the singleton operation list in `mub`.
- Toggle the Image flag without mirroring crop: original `mub` includes the reflected crop setter.
- Keep unavailable Flip commands visible and silently no-op: this advertises behavior that the
  original model rejects and weakens the handler's mutation boundary.

## Verification

- `d02-local-image-flip-outbound.mjs` locks original dispatch/writer/type gates, singleton operation
  emission, crop reflection, mixed initial values, one batched revision and transaction rollback.
- ArkTS tests cover FlatBuffer round-trip, explicit false presence, validation, horizontal/vertical
  classification, crop reflection, unrelated-field rejection and forward/reverse Undo/Redo values.
- Full replay and clean sequential HAP results are recorded in the Phase 114 report.

## Remaining Boundary

No emulator, VM, device or Hypium was run. Device verification still needs uncropped/cropped Images,
mixed initial flip values, repeated horizontal/vertical commands, restart, Undo/Redo, remote replay
and cross-device visual comparison. Crop editing UI and other MODIFY_BLOCK outbound fields remain
separate work.
