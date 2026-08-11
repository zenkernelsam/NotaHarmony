# ADR-0115: Preserve Image blocks and asset references in original Group Paste

## Status

Accepted, 2026-08-12.

## Original Evidence

- Original 1.0.3 `baj.d()` writes Image through the same 21-field type-22 CREATE_BLOCK table: field
  10 is the required `dp5` ImageAsset, field 11 is crop, field 12 is web URL, fields 16/17 are the
  two flip flags, and field 20 is `positionLocked`.
- `iuh.c()` writes `dp5` as required AssetMetadata plus required intrinsic size. `k1j.c()` writes the
  eight-word SHA-512 AssetHash, file name, MIME type and unsigned 32-bit file size.
- Original CREATE_BLOCK only declares asset identity and metadata. Image bytes travel through the
  independent asset pipeline, so Paste must preserve an existing local file when present and may
  retain a pending cloud asset without inventing bytes or marking it local.

## Decision

- Add a strict local Image CREATE_BLOCK encoder. It preserves the eight uint64 hash words, UTF-8
  metadata, intrinsic and block sizes, transform, crop, URL, corner, wrap, caption, flips and lock.
  It rejects a non-canonical hash key, out-of-range file size, invalid UTF-8/length, invalid crop,
  illegal enum, degenerate matrix, shear or perspective.
- Image is now a normal Group Paste leaf. Preflight validates its complete type-22 payload before any
  write, and the transaction allocates its identity in page order and applies the payload through the
  production decoder/reducer in the shared page revision batch.
- Reuse the reducer's asset merge inside the Paste SQLite transaction. A matching LOCAL row keeps its
  status/path and gains the destination noteId; canonical/legacy keys merge; missing metadata creates
  PENDING; metadata or path conflict aborts the entire Image/Group/NCP1 action.
- Materialize the returned Image from the decoded wire payload so float32 transform, size and crop are
  identical in original state, page snapshot, NCP1 and the live UI.
- After a successful current-page commit, install and select the Image and restart the existing image
  loader generation. Existing local bytes render immediately; a PENDING asset remains subscribed to
  the established asset-arrival refresh path.

## Rejected Alternatives

- Copy or synthesize image bytes during CREATE_BLOCK: the original operation is metadata-only and this
  would conflate the block transaction with the independent SHA-512 asset transport.
- Require every copied image to be LOCAL: original documents may legitimately contain pending cloud
  assets, and rejecting those would lose a valid Group structure.
- Insert the Image after Groups commit: that could leave Group membership and history referencing a
  missing entity and would break one-action rollback.

## Verification

- ArkTS fixture round-trips hash words, file metadata, intrinsic size, crop, URL, non-uniform transform,
  caption, corner, wrap, flips and lock through the production decoder and rejects a divergent hash key.
- `d02-original-group-paste-image.mjs` locks original field evidence, nested encoder layout, asset
  reference preservation, canonical UI materialization and rollback at asset/Create/Group/NCP1 stages.
- Full desktop replay passes with `TOTAL=124 FAILED=0`. After `hvigorw clean`, both `note@ohosTest`
  and `note@default` HAP builds succeed. No emulator, VM, device or Hypium is used.

## Remaining Boundary

Styled and empty Text plus Shape RichText remain explicit Group Paste gates. The private authenticated
cloud download transport remains deferred as recorded by ADR-0035; this phase correctly preserves
PENDING references and uses the already implemented verified asset-arrival path.
