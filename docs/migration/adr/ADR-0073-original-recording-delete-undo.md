# ADR-0073: Reproduce original Recording delete and Undo lifecycle

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `n05.a/c/d`, `uoa` and `hpa` expose one Recording mutation in the toolbox:
  Delete. A pending row is replaced in place by `Recording deleted` plus `Undo`; no rename string or
  rename action exists in this version, so adding one would not be an original-faithful feature.
- `npa.i()` adds the entity ID to `pendingDeleteRecordingIds`, owns one cancellable job per ID and
  removes the ID when Undo arrives. `kk9` case 12 waits exactly 10,000 ms, submits the one entity
  through `de8.a()`, then removes pending state. `npa.f()` submits all remaining IDs as one batch when
  the model is cleared.
- `de8.a()` forwards the ID list through the original edit pipeline. Existing D-02 evidence already
  proves Recording deletion is entity visibility type 25, with LWW winner state and derived
  `hasRecordings` refresh rather than destructive audio/metadata removal.

## Decision

- Add a pure `OriginalRecordingDeleteController` with the original 10-second window. Request hides
  the row immediately, Undo cancels only while its timer is live, timeout commits one target, and
  editor teardown flushes all still-scheduled targets in one batch. Commit failure removes the
  optimistic pending state so the unchanged Recording row becomes visible again.
- Keep pending rows in their original list positions and render `Recording deleted` plus Undo. Remove
  pending IDs from cumulative playback and AudioLinked segment timelines immediately. Unload an
  active player before its Recording can be committed.
- Encode the exact four-field DELETE_ENTITIES payload table with only `entityDeletes` populated.
  Deduplicate targets while preserving order and retain full uint32 timestamp/uint16 site values.
- Commit under the editor persistence mutex and one database transaction: verify every target is a
  current visible Recording, allocate one operation identity, run the existing original visibility
  reducer, refresh derived presence through that reducer, and append the same payload table as
  `ORIGINAL_DELETE_ENTITIES` to the operation log. Any reducer/log failure rolls back all writes.
- Do not claim private server transport completion. The local journal now carries an exact original
  payload table and stable identity, but the project still has no production `OperationSyncTransport`
  implementation to wrap/upload it to Notability's private service.

## Rejected Alternatives

- Delete the Recording row or audio file: original deletion is a reversible entity tombstone and
  must preserve metadata/assets for remote undelete and history.
- Commit immediately then issue an undelete for Undo: original delays the first edit, so Undo inside
  the window produces zero durable operations.
- Add rename UI because MODIFY_RECORDING supports a name register: wire capability is not evidence
  that the 1.0.3 Android toolbox exposes the command.
- Let page teardown discard timers: original `npa.f()` flushes pending IDs instead.

## Verification

- ArkTS tests cover exact payload round-trip including maximum identity values, the 10-second delay,
  zero-write Undo, timeout commit and teardown batching.
- `d02-recording-delete-undo.mjs` locks original UI/string evidence, production wiring, transaction/
  operation-log guards and a byte-level payload golden.
- Full replay and clean HAP results are recorded in the Phase 96 report. No device was started.

## Remaining Boundary

Private server upload/ACK, recording capture, Android/Harmony device playback behavior, audio focus
and output routing remain separate work. Waveform is not added without stronger 1.0.3 evidence.
