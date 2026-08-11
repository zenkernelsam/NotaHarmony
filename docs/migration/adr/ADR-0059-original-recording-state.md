# ADR-0059: Preserve original 1.0.3 Recording entities and independent registers

## Status

Accepted, 2026-08-11.

## Evidence

- Original payload types 5 and 6 are `CREATE_RECORDING` (`yn2`) and `MODIFY_RECORDING` (`ke8`).
  `v69` creates a `gkb` Recording whose identity is the create operation ID; `fsi.K` resolves modify
  operations to that identity.
- `akb/wa0` show that RecordingAsset wraps the same required SHA-512 asset metadata used elsewhere:
  64 hash bytes, non-empty file name and MIME type, and a positive unsigned 32-bit file size.
- Create stores immutable unsigned start/end times. `yn2.a` requires start <= end and rejects a
  segment whose end exceeds the recording end. If segmentation is absent, `tab.e` creates one
  `[start,end]` segment. Missing name becomes `Recording ID Id(site=..., timestamp=...)`; missing
  z-index becomes operation client time.
- `fkb.c` applies name, segmentation and z-index through three separate CRDT register builders.
  A modify with no optional field is valid. The outbound `u5j.w` path additionally requires modified
  segments to be ordered, within the recording bounds, and no longer than the recording duration.
- Recordings participate in the same entity delete/undelete target resolution as Ink, Shape, Block
  and Group. They are note-level entities rather than page snapshots. The original model retains the
  entity and uses its visibility winner; it does not archive a page element for a Recording.

## Decision

- Add strict type-5/type-6 FlatBuffer decoders with unknown-field rejection, bounded UTF-8 and
  segment vectors, precision-safe uint64 decimal values, nested RecordingAsset validation, create
  bounds and modify segment bounds.
- Add `original_recording_state` for immutable create fields plus independent name, segments and
  z-index values/winners. Add `original_recording_modification` so even a stale replay can be
  distinguished from reuse of the same operation identity with a different target or payload.
- Reuse the canonical asset-reference merger. Receiving Recording metadata creates or merges a
  PENDING note asset reference, but never claims that audio bytes are local or playable.
- Reuse `original_entity_visibility_winner` for delete-before-create, delete and undelete. Derive
  `note_meta.has_recordings` from visible Recording rows after create or visibility changes; the flag
  is a cache/consumer signal, not the Recording model itself.
- Route both payloads through standalone durable inbox replay and NOTE_BUNDLE preflight/apply. Bundle
  changes, asset references, modification journal and derived presence remain in the caller's one
  SQLite transaction.

## Verification

- ArkTS fixtures cover nested asset metadata, full uint64 values, create/modify segments, nullable
  fields, valid empty modify, missing target/asset, segment overflow, unknown fields and both router
  types.
- `d02-recording-state.mjs` executes v54 to v55 migration and rollback, create retry/conflict,
  independent LWW registers, stale/site ties, modify retry/conflict, missing target, delete/undelete,
  delete-before-create, derived presence, bundle rollback and note cascade.
- All desktop replays pass with `TOTAL=68 FAILED=0`. Clean HAP evidence is recorded in the Phase 81
  report.

## Remaining Boundary

This phase preserves the original Recording model and asset relationship. It does not claim audio
capture, remote byte arrival, waveform generation, playback, recording UI, or outbound operation
writing. NotaHarmony's current own-package exporter serializes resolved page snapshots rather than
the complete original note-level CRDT model; Recording state therefore needs a versioned package
extension before backup/import parity can be claimed. Exporting only the audio file now would create
an orphan asset and is intentionally not presented as a solution.
