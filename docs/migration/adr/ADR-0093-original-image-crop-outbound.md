# ADR-0093: Preserve original Image Crop draft UI and composite MODIFY_BLOCK outbound

## Status

Accepted, 2026-08-11. This closes the local Image Crop editing boundary left after ADR-0091.

## Original Evidence

- Original 1.0.3 `dhb` case 14 accepts a singleton `itc`, resolves it to an `hp5` Image, enables crop
  mode through `fvb.e(true)`, derives the absolute block frame, seeds `tp2`, and publishes `lsc` UI
  state. Non-Image and non-singleton selections do not enter crop mode.
- `ls` case 16 replaces only the `lsc` crop frame when `fi3` changes. Dragging is draft state and does
  not submit an operation. `tp2.b()` clears both crop states; `tp2.c()` constrains a proposed frame.
- Original toolbar composition in `t7` is ordered Close, Reset, Confirm and uses the exact
  `feature_note__close`, `feature_note__reset`, and `feature_note__checkmark` vector assets.
- `ns.s` computes the intrinsic crop from the draft frame and current Image scale. Confirm submits one
  type-23 `MODIFY_BLOCK` containing page identity and new origin (fields 2/3), the preserved scale
  setter (field 5), the new block size (field 6), and the crop setter (field 12).
- For a rotated Image, the new page origin is the old origin plus the rotated draft-origin delta. The
  linear transform is preserved. Confirm then disables crop mode, clears `tp2`, restores normal UI
  state and focuses the resulting crop frame.

## Problem

Harmony could render an imported crop and could mirror its intrinsic crop rectangle during Flip, but
had no Crop command, draft controller, rotated overlay, Reset/Close semantics, or original outbound.
Treating crop as field 12 alone would leave the block origin and size inconsistent. Persisting every
handle move would also create history and operation traffic absent from the original.

Some existing Harmony/import fixtures contain legacy Image dimensions that cannot be represented by
the original crop model (effective intrinsic crop size differs from block size, or transform contains
shear/reflection/perspective). Sending original operations for those states would corrupt geometry.

## Decision

- Add a pure `OriginalImageCropGeometry` session. Persistent crop coordinates remain intrinsic Image
  coordinates; draft coordinates are current block-local coordinates and may expand to the full
  intrinsic domain. Close discards the session, Reset changes only the draft, and Confirm materializes
  one cloned Image.
- Preserve the original transform linear part. Moving the draft left/top changes page origin through
  that linear part, so rotation and positive non-uniform scale remain exact. Recompute world bounds
  from the resulting block rectangle and store crop coordinates as float32-compatible values.
- Gate Crop to one unlocked Image with finite positive intrinsic dimensions, a canonical
  rotation/positive-scale transform, a valid intrinsic crop, and block dimensions consistent with the
  effective crop. Unsupported legacy states remain selectable/renderable but do not expose Crop.
- Add a full-screen transparent overlay with four rotated edges, eight fixed 32 vp hit targets, and a
  stable Close/Reset/Confirm toolbar. Reuse the original vector paths and localized accessibility
  names. Screen drag deltas pass through viewport zoom and the inverse Image linear transform.
- Encode field 12 as a nullable setter table. Undo from a cropped Image to the original `cropRect=null`
  therefore preserves setter presence while omitting its value. Every Confirm operation also writes
  fields 2/3/5/6, matching `ns.s` rather than emitting a partial crop mutation.
- Add a strict single-Image snapshot classifier. Identity/order, asset domain, rotation, scale and all
  unrelated fields must remain unchanged; origin, dimensions, crop and derived bounds must equal the
  exact composite projection. Ordinary saves and grouped restart-safe Undo/Redo use the same type-23
  writer, reducer, upload-immediate journal, one-revision batch, snapshot reconciliation and history
  companion transaction.
- Confirm records the existing `TRANSFORM_ELEMENTS` history shape, restores the Image selection and
  persists once. Page changes, disappearance and history commands cancel an active draft without
  persistence.

## Rejected Alternatives

- Write only field 12: this omits the origin and size changes proven in `ns.s`.
- Persist handle moves: original `ls` case 16 only replaces draft UI state.
- Crop in axis-aligned world bounds: this fails rotated Images and changes the wrong origin axes.
- Silently normalize shear, reflection or inconsistent legacy dimensions: there is no original
  evidence for such conversion, and it could irreversibly change imported content.
- Clear crop by omitting field 12: omission means no register update, not nullable clear.

## Verification

- `d02-local-image-crop-outbound.mjs` locks original entry/draft/confirm/toolbar evidence, composite
  fields, rotated origin math, Close/Reset, nullable Undo clear, one type-23 operation, source-state
  validation, one revision and transaction rollback.
- ArkTS fixtures cover composite payload round-trip and clear presence, invalid geometry rejection,
  rotated/non-uniform-scale crop, full-domain Reset, input immutability, unsupported model rejection,
  forward/reverse/Reset classifiers and unrelated or multi-Image rejection.
- Full replay and clean sequential HAP results are recorded in the Phase 116 report.

## Remaining Boundary

No emulator, VM, device or Hypium was run. Device verification still needs handle ergonomics across
rotation/zoom, toolbar placement near viewport edges, dark theme vector tint, Close/Reset/Confirm,
restart Undo/Redo, imported crops and remote replay. Remaining entity outbound, format closure,
private authenticated upload/ACK and centralized device acceptance remain separate work.
