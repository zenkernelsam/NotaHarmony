# ADR-0053: Apply original mixed position modifications atomically

## Status

Accepted, 2026-08-11.

## Evidence

- Original `je8` payload type 24 contains a required non-empty vector of `ie8` modifications.
  Each modification has a required target, optional page plus origin pair, nullable rotation and
  scale setters, and an optional uint64 z-index.
- Original `v69` rejects repeated targets and resolves every target before reducing the payload.
  A single payload may contain Ink, Shape, Block and Group targets.
- Original reducers keep independent LWW identities for page/origin, rotation, scale and z-index.
  The operation identity, rather than vector order, decides each register winner.
- Operation root field 6 contains transient interaction metadata. Root field 3 is optional
  `audioTime`; it must not be interpreted as a boolean. Persisting field-6 preview operations into
  the durable Harmony page model would create state that the original does not commit.

## Decision

- Strictly decode all type 24 modifications before writing. Reject an empty vector, duplicate target,
  unpaired page/origin, non-finite geometry, malformed nullable setters, lossy uint64 values and
  unknown fields.
- Classify every target before applying any modification. Reuse the existing Ink reducer for strokes
  and the Block reducer for TEXT/IMAGE/MATH so their register guards, archived-page handling,
  element-order materialization and persisted-state checks stay identical to standalone operations.
- Wrap the complete mixed payload in one SQLite savepoint. A deferred child reducer or exception
  rolls back all earlier child writes; a payload must never be reported as partly applied.
- Delay page revision and search invalidation in `OriginalPageMutationBatch`. Multiple Ink/Block
  modifications touching the same page advance `content_revision` once and merge Ink/Text search
  invalidation after every child reducer succeeds.
- Route type 24 through both standalone and NOTE_BUNDLE paths. NOTE_BUNDLE preflight validates every
  destination page and binds archived destination pages before bootstrap insertion.
- Reject all transient standalone and NOTE_BUNDLE operations before durable mutation. This is a
  conservative boundary until a separate ephemeral interaction model exists.
- Shape and Group position modification remains deferred as a whole. Their durable entity reducers
  are not yet available, so mixed payloads containing either kind must not partially apply supported
  Ink or Block entries.

## Verification

- ArkTS fixtures cover the two-target FlatBuffer, paired page/origin, nullable clear setters,
  maximum uint64 z-index, duplicate target, unpaired geometry and same-page revision batching.
- `d02-modify-positions.mjs` covers mixed Ink/Block replay, one revision per page, z-order, nullable
  clear, retry, stale/tie LWW, preflight zero-write, child-deferred savepoint rollback, exception
  rollback, transient zero-write, NOTE_BUNDLE routing and archived-page binding.
- All desktop replays pass with `TOTAL=62 FAILED=0`. After `hvigor clean`, both `note@ohosTest` and
  `note@default` HAP builds complete successfully.

## Remaining Boundary

This closes durable type 24 replay for Ink and TEXT/IMAGE/MATH Block targets. Shape/Group support
requires their own verified entity state and reducers. Transient operations require a non-durable
interaction layer and must not be redirected into the persisted model. ADR-0056 supersedes this
ADR's earlier incorrect field-3 identification and adds the shared field-6 guard plus type-26 cleanup
boundary.
