# ADR-0071: Preserve original operation audioTime only across successful application

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `uq9.j()` reads nullable uint64 `audioTime` from operation field 3. Field 6 is the
  unrelated nullable `sdf transientInteraction` table. `wq9` carries the same nullable audio time
  while constructing an operation.
- Original `q06` materializes a playable ink value with `audioTime` when present and falls back to
  the operation client time when absent. `op7` keeps modified time and effective audio time as
  separate uint64 values.
- Original `s1j.b()` compares playback time with an entity's audio range using unsigned ordering.
  Converting these values through JavaScript `number` would lose valid uint64 precision.
- Harmony already retains the complete raw `uq9`, but neither its decoded envelope nor a queryable
  materialized model exposed field 3. NOTE_BUNDLE decoding also still treated field 3 as a transient
  boolean despite the standalone correction in Phase 78.

## Decision

- Add nullable decimal-string `audioTime` to the original envelope and propagate it through incoming
  bundle decoding and stored operation application. Validate all eight field bytes and preserve the
  full unsigned range.
- Correct NOTE_BUNDLE children to read field 3 as audioTime and detect transient metadata by field-6
  table presence. A bundle containing actual transient metadata remains rejected as ephemeral state.
- Add database v58 table `original_applied_operation_time`. Store the operation identity, client
  time, nullable wire audio time and payload type only after its reducer succeeds, in the same
  transaction as entity materialization, cursor advancement and inbox APPLIED state.
- Materialize every successfully bootstrapped NOTE_BUNDLE child in the same bootstrap transaction.
  Exact retries are idempotent; an identity with different timing metadata is corruption.
- Backfill missing rows from historical APPLIED inbox raw bytes at database initialization, checking
  raw identity and metadata against the inbox row before insertion. Deferred, unknown and malformed
  operations cannot appear in the queryable timing model.
- Expose a note-scoped reader ordered by effective audio time. It returns both nullable wire
  `audioTime` and `effectiveAudioTime = audioTime ?? clientTime`, matching `q06` without erasing the
  distinction.

## Rejected Alternatives

- Reparse every raw BLOB for every playback update: correct but needlessly expensive and unsuitable
  for repeated renderer queries.
- Persist timing at receive time: filtering can hide deferred rows, but it weakens the invariant that
  queryable timing describes materialized operations and complicates NOTE_BUNDLE parity.
- Convert timestamps to `number`: values above 2^53 are valid original data and would alias.
- Automatically replay every historical NOTE_BUNDLE during migration: the deferred-bundle table has
  no durable applied marker, so startup replay could mutate notes whose bootstrap status is unknown.

## Verification

- ArkTS fixtures cover nullable and explicit audioTime, max-range uint64 parsing, incoming propagation
  and NOTE_BUNDLE field-3/field-6 separation.
- `d02-operation-audio-time.mjs` covers v57-v58 migration, exact uint64 text, client-time fallback,
  ordering, invalid values, identity conflict, transaction rollback, note cascade, static inbox
  backfill and NOTE_BUNDLE wiring.
- Full desktop replay and clean HAP build results are recorded in the Phase 94 report.

## Remaining Boundary

This decision establishes lossless data and query foundations. It does not claim playback-linked ink
rendering, waveform rendering or device visual validation. A NOTE_BUNDLE that was already materialized
before v58 gains timing rows when it is next validly bootstrapped; automatic migration cannot infer its
prior applied status from the current schema.

