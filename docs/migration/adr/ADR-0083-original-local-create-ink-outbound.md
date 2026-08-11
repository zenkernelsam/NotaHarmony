# ADR-0083: Persist locally authored Ink as original CREATE_INK

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 maps CREATE_INK to payload type 15 in `haa`. `dm2` exposes the original
  20-field Ink table; `ys2.O()` writes page SeqId, origin, transform, tool/style/tape, RGBA,
  width, three encoded paths, fill/style map, z-index, audio duration, nib fields and effects.
- `kt1.d()` creates the transient Ink at touch-down through `u5j.g()`. The entity identity is
  the CREATE_INK operation `(timestamp, siteId)`, while the target page is the stable `cxc`
  sequence identity created by CREATE_PAGE.
- `faj/u5j/ldj.M2()` are the production path writer chain. Live paths use version 0 with
  BITS_32 coordinates. Center paths start with an attributed MOVE and retain endpoint
  width, force, altitude and azimuth attributes.
- Original Pencil rendering keeps its deterministic scatter seed in the 20-byte `yyd` style-map
  entry. Omitting it changes the rendered stroke after another client replays the operation.
- DELETE_ENTITIES fields 0 and 1 are entity delete/undelete vectors of operation identities.
  Recreating Ink with another CREATE_INK on Redo would produce a different entity.

## Decision

- Reserve an original operation identity only for a live page whose original page identity,
  visible element membership and z-order exactly match the Harmony snapshot. Touch-down consumes
  the reservation synchronously, so preview input remains synchronous and the stroke ID is already
  the canonical `op:<timestamp>:<site>` before it enters UI state or Undo history.
- Encode a complete local center path as one original CREATE_INK payload using BITS_32 coordinates.
  Preserve tool/style/color/width/tape/effects and write a one-entry style map for Pencil so its
  scatter seed matches the live preview. Recording `audioTime` remains the touch-time value supplied
  by the active recording clock; it is not replaced by persistence time.
- Recheck page eligibility in the shared editor mutex and SQLite transaction. Apply the existing
  original reducer first, reject every deferred result, append the original operation with
  `uploadImmediately=true`, reconcile its one materialized row, and append the Harmony page mutation
  only as the local persistent-history companion. Any failure rolls back reducer state, operation
  rows, page revision and history together.
- Encode ADD_STROKE Undo as entityDeletes and Redo as entityUndeletes. Both single-action and
  coalesced history groups call `OriginalDeleteEntitiesOperationApplier`, preserving the same Ink
  identity, z-order, archived payload and search invalidation.
- Treat ORIGINAL_CREATE_INK as a transparent outbound companion during persistent-history replay.
- Persist a v59 per-page authoring guard. The first non-original content mutation permanently blocks
  later local CREATE_INK on that page, including after restart. This prevents an unsynced transform,
  erase, text, shape, image or math change from being hidden behind apparently valid later Ink ops.
  Mixed/legacy pages continue using the existing Harmony snapshot path.
- Leave unused reservations as operation-clock gaps. Gaps are valid; reusing a reserved identity
  after cancellation or process death would risk an identity collision.
- Scope an in-flight reservation to its page-load generation and page ID. A page switch waits for
  the stale request to leave the serialized database section, then retries for the current page;
  the stale identity is never installed into the new page and cannot starve its reservation.

## Rejected Alternatives

- Allocate after touch-up and rewrite the ID during persistence: UI, layer cache and Undo could
  retain the random ID while SQLite and remote clients use the canonical operation ID.
- Emit CREATE_INK whenever a page merely has a page SeqId: untracked local elements make the
  original z-order incomplete and the reducer must defer.
- Apply the original reducer and then rewrite the whole snapshot: that would advance the page
  revision twice and can overwrite reducer-owned CRDT rows.
- Undo only through the Harmony page mutation: `original_element_z_index` would still expose the
  stroke, so the next CREATE_INK and remote replay would diverge.
- Omit Pencil styleMap: local preview and replayed Pencil splats would use different seeds.

## Verification

- `OriginalCreateInkPayloadEncoder.test.ets` covers dm2/path round-trip, Pencil styleMap,
  operation-ID parsing, and entity delete/undelete vectors.
- `d02-local-create-ink-outbound.mjs` locks the original evidence, production wiring, aligned-page
  gate, canonical identity, Undo/Redo visibility, persistent guard and transaction rollback.
- All desktop replays pass with `TOTAL=92 FAILED=0`. Clean sequential HAP results are recorded in
  the Phase 106 report.

## Remaining Boundary

Local ADD_PATH_ELEMENTS streaming, MODIFY_INK for transforms/style/partial erase, whole-eraser
multi-entity batching, original text/shape/image/math authoring, private transport ACK acceptance,
and device-level visual/input verification remain later work. No emulator, VM or device was started.
