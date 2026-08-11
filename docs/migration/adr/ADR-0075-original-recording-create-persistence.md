# ADR-0075: Persist original Recording creates atomically

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `re0` copies an incoming file through `assets/pending` while calculating SHA-512.
  `aa6` reads each eight-byte digest group as a little-endian unsigned long, and `ba6` writes those
  words back little-endian; the canonical asset file name is therefore the 128-character SHA-512
  hex string.
- `skb` rejects an empty completed recording, stores the bytes through the asset repository, then
  creates a Recording with the temporary file name, null segmentation and explicit zIndex zero.
  Its `finally` path deletes the completed temporary capture on both success and failure.
- Original `iaj` encodes CREATE_RECORDING as six fields: recording metadata, start time, end time,
  name, segmentation and zIndex. The recording identity is the enclosing operation identity.

## Decision

- Stream the completed capture into an owned pending file while calculating SHA-512, fsync it, and
  atomically rename it to `assets/final/<sha512>`. Reject empty, changed or metadata-mismatched input.
  If the canonical file already exists, compare every byte before reusing it.
- Convert the 64 digest bytes into the original eight little-endian unsigned uint64 decimal words.
  Encode a valid FlatBuffer CREATE_RECORDING table with the exact asset metadata, start/end times,
  temporary file name, absent segmentation and zIndex zero.
- Serialize asset mutation before editor persistence. In one database transaction allocate the
  operation identity, apply the production original Recording reducer, promote the canonical
  `note_asset` row to a local available asset, migrate any legacy hash-key row, and append the exact
  same payload to the operation journal for later upload.
- Roll back all database writes on failure. Remove a final file only when this attempt created it,
  always remove its pending file, and always consume the handed-off capture temporary file as the
  original does. Close both descriptors independently even when a peer open/close fails.
- Wire a non-UI persistence bridge into `NotePage` so this path is checked by the production ArkTS
  compiler. Runtime permission and visible recording controls remain disabled until the complete
  user interaction lifecycle is implemented.

## Rejected Alternatives

- Use the existing comma-separated word key as the final file name: that was an early Harmony
  compatibility key, while original byte serialization proves the canonical name is SHA-512 hex.
- Read the whole recording into memory: recordings can be large and the original hashes while
  copying, so a bounded streaming copy is both faithful and safer.
- Commit the reducer, asset row and operation log separately: a crash would expose an unjournaled
  Recording or a journal entry whose asset is unavailable.
- Delete any matching final file during compensation: a matching asset may predate this operation
  and be referenced by another note; only a file created by the current attempt is compensatable.

## Verification

- ArkTS tests verify digest word conversion and round-trip the hand-written payload through the
  production CREATE_RECORDING decoder. Importing persistence from the suite checks its ArkTS graph.
- `d02-recording-create-persistence.mjs` locks original evidence, exact writer fields, mutex/
  transaction/journal wiring, production-page integration, success persistence and injected-failure
  rollback with pending/final/temporary cleanup.
- Full replay and clean HAP results are recorded in the Phase 98 report. No device was started.

## Remaining Boundary

The next phase may request runtime microphone permission and expose Record, pause, resume and stop,
then pass a successful stop result through this persistence bridge with visible busy/error states.
Editor exit during active capture, audio focus/interruption, codec and microphone behavior still
require explicit implementation or device validation. Private operation upload/ACK is also separate.

## Phase 110 Correction

Phase 98 materialized CREATE_RECORDING from its valid child table, but journaled that child rather
than the complete original operation. Phase 110 wraps the payload before materialization and stores
the identical complete `uq9`, allowing later envelope readers and upload code to preserve operation
identity and nullable timing metadata.
