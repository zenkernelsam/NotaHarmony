# ADR-0056: Consume original transient interaction endings without durable model writes

## Status

Accepted, 2026-08-11.

## Evidence

- Original `uq9` field 3 is optional `audioTime`; field 6 is nullable `sdf transientInteraction`.
  `sdf` requires an inline `interactionId`; its optional timeout is currently rejected by the
  original validator as unused.
- `wq9` makes payload type 26 `TRANSIENT_INTERACTION_ENDED` transient by default and derives the
  root transient interaction ID from the payload. `tdf` field 0 is the required interaction ID and
  field 1 is nullable `replacedByOp`.
- The current original writer `oqi` writes only the required ID, but the generated reader and model
  equality retain `replacedByOp`; accepting and preserving a valid field 1 is therefore required.
- Original `v69` groups preview operations by root interaction ID. On type 26 it gathers affected
  entities, clears the two transient materialization caches, removes the interaction list and emits
  invalidation. It does not update durable CRDT/model state and does not read `replacedByOp` in this
  reducer branch.
- Harmony previously read root field 3 as a boolean transient flag. A normal durable operation with
  `audioTime` could consequently be deferred, while the actual field-6 metadata was not inspected.

## Decision

- Add a strict type-26 decoder. Require root field-6 metadata, reject the currently unused timeout,
  reject unknown root/metadata/payload fields, require both inline IDs, validate optional
  `replacedByOp`, and require the root and payload interaction IDs to match.
- Add a note-scoped `OriginalTransientInteractionStore`. It holds only interaction-to-preview
  operation IDs in memory. Ending an absent interaction is idempotent; note IDs are isolated; a
  process restart intentionally drops all preview state.
- Route a valid standalone/live type 26 as consumed: clear the in-memory interaction and let the
  durable inbox mark the operation applied so ordering, retry identity and sync cursor metadata can
  advance. Do not write a CRDT/entity/page row and do not add a database migration.
- Keep other root-field-6 preview operations deferred until their view-model preview reducers exist.
  The store exposes `recordPreview` for that layer, but this phase does not pretend that peer cursor,
  drag or ink preview rendering is implemented.
- Keep NOTE_BUNDLE transient rejection. A historical/bootstrap snapshot must not restore ephemeral
  interaction state.
- Replace both field-3 transient checks in the unified router and type-24 reducer with field-6
  presence checks. Field 3 remains legal `audioTime` and cannot control persistence.

## Verification

- ArkTS fixtures cover required and optional IDs, note isolation, duplicate end, missing metadata,
  metadata/payload mismatch, timeout, unknown payload field and a durable operation with audioTime.
- `d02-transient-interaction.mjs` covers the memory-only lifecycle, restart loss, a valid end followed
  by a durable inbox head, malformed blocking, source guards and the unchanged NOTE_BUNDLE boundary.
- All desktop replays pass with `TOTAL=65 FAILED=0`. Clean HAP build results are recorded in the
  Phase 78 report.

## Remaining Boundary

This closes production decoding, ordering and cleanup for payload type 26. Harmony still lacks the
original view-model reducers that render incoming transient previews and populate their affected
entity cache. Those previews remain explicitly deferred rather than being written into the durable
model or silently presented as native collaboration parity.
