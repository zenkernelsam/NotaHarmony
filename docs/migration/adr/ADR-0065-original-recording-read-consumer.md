# ADR-0065: Materialize visible Recording state before playback

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `gkb` exposes immutable recording start/end/asset metadata and three resolved LWW
  values: name, segments and zIndex. `tab.e()` supplies the original defaults when CREATE omits
  those values.
- Recording identity is the CREATE operation identity. `fkb` applies MODIFY_RECORDING to the three
  registers independently; deletion uses the shared entity visibility state.
- `yn2/ukb/wa0` keep recording times and segments as unsigned 64-bit values and require non-empty
  asset file name/MIME plus a positive uint32 file size.
- A persisted asset reference does not prove that audio bytes are local. The existing Harmony
  `note_asset` lifecycle already distinguishes pending/local/uploaded/downloaded/failed and stores a
  nullable local path.

## Decision

- Add `OriginalRecordingStore.listVisible(noteId)` as the production read boundary between the
  inbound CRDT tables and any future recording UI/player.
- Filter canonical deleted winners, read the resolved LWW columns, preserve uint64 values as
  canonical decimal strings, validate the exact eight-word original asset hash, and sort by unsigned
  zIndex then CREATE identity.
- Resolve both canonical 64-byte storage hash and the legacy word key. Expose explicit
  MISSING/PENDING/READY/FAILED states; metadata mismatch and `AssetStatus.FAILED` must never become
  playable. READY still means only that a non-empty local path is registered; byte/open/codec checks
  belong to the eventual player loader. ADR-0066 now supplies the open/regular-file/exact-size
  boundary; codec and playback remain later boundaries.
- Do not claim audio playback, recording capture, waveform, segment seeking or asset transport in
  this phase.

## Verification

- ArkTS tests cover precision-safe segment parsing, malformed/bounds rejection, eight uint64 hash
  words and zIndex/identity ordering.
- `d02-recording-consumer.mjs` covers tombstone filtering, resolved state ordering and static asset
  availability contracts. Device playback is deliberately not executed.
