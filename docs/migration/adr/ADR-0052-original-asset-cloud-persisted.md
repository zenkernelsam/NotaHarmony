# ADR-0052: Preserve original asset cloud availability separately from local file status

## Status

Accepted, 2026-08-11.

## Evidence

- Original `ra0` (`AssetCloudPersisted`) contains only required field 0, an inline `ua0`
  AssetHash of eight uint64 words (64 bytes total).
- Original `v69` handles payload type 2 by changing the matching `za0` availability to
  `qa0.AVAILABLE`. If the hash is absent it creates the state with an empty reference set.
- Later asset-reference merge in `v69.a(pa0, List)` preserves an existing availability,
  proving that the cloud event may arrive before its first page/background reference.
- `aa6.Z` consumes only assets whose availability is `AVAILABLE`; `yo7` independently counts
  `AWAITING_UPLOAD`. This state describes server persistence, not local file readability.
- Harmony `note_asset.status` combines local/download/upload lifecycle states. Mapping the
  original event to `UPLOADED` would overwrite `LOCAL` or `DOWNLOADED`, and could advertise a
  file that has not arrived locally.

## Decision

- Add database v52 table `original_asset_cloud_state`, keyed by `(note_id, asset_hash)` with
  note cascade. Row existence records the original monotonic cloud-persisted fact.
- Store the canonical 128-character hash produced directly from the original 64 inline bytes.
  This matches the byte order already used by `originalAssetStorageHash`; do not introduce a
  legacy colon-delimited key into new state.
- Decode the required inline struct strictly and defer missing, truncated or extended payloads
  before any write.
- Apply with `INSERT OR IGNORE`. Duplicate or reordered true events are idempotent and require no
  LWW register because the original operation has no false transition.
- Do not create or update `note_asset`. Asset metadata/reference arrival remains responsible for
  that row, so event-before-reference is retained without fabricating a local file.

## Verification

- The ArkTS fixture decodes all 64 bytes, rejects missing/truncated/extended tables, exercises
  duplicate application and asserts that the reducer SQL never targets `note_asset`.
- `d02-asset-cloud-persisted.mjs` covers v51-v52 migration, event-before-reference, duplicate
  idempotence, per-note state for a shared hash, note cascade, local-status independence and
  migration rollback.
- All desktop replays pass with `TOTAL=61 FAILED=0`. After `hvigor clean`, both
  `note@ohosTest` and `note@default` HAP builds complete successfully.

## Remaining Boundary

This closes payload type 2 model replay only. Actual asset upload/download scheduling remains a
separate transport concern and must consume this state only after its protocol is verified.
