# ADR-0066: Validate and lease local Recording bytes before AVPlayer

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `hkb/f45/vna/uw7` resolve every visible Recording to a local `Uri`, build one
  media item per resolved recording, and seek on a cumulative recording timeline. A missing or
  malformed URI is skipped and causes an explicit media-item-count divergence warning.
- `hkb` uses the immutable start/end bounds when segments are empty. When segments exist it uses
  only the first segment start/end for the exposed effective duration. `vna` still gives ExoPlayer
  the recording URI itself. This is evidence for the original 1.0.3 boundary, not permission to
  invent multi-segment concatenation in Harmony.
- Harmony `media.AVPlayer.fdSrc` accepts an `AVFileDescriptor`; the caller remains responsible for
  closing its FD. The descriptor must stay valid while the player consumes it. `fdSrc` alone does
  not prove that the container or codec is supported.
- ADR-0065 READY means that matching metadata and a non-empty local path are present. It deliberately
  left actual file open and byte-size validation to the player-side loader.

## Decision

- Add `OriginalRecordingAssetLoader.open()` as the second availability boundary. Preserve
  MISSING/PENDING/FAILED without filesystem access; a READY row must open read-only, resolve to a
  regular file, be non-empty and exactly match the original asset byte count.
- Return an `OriginalRecordingAssetLease` containing `{fd, offset: 0, length}`. The lease owns the
  opened file and closes idempotently. A future AVPlayer controller must reset or release the player
  before closing this lease.
- Stat the opened FD rather than trusting a path-only stat, so the descriptor and validated bytes
  are the same file. Any open/stat/type/size failure becomes FAILED and never reaches AVPlayer.
- Do not reject MIME types beyond original metadata equality, claim codec support, concatenate
  segments, add speculative playback UI, or close the FD immediately after assigning `fdSrc`.

## Verification

- ArkTS tests cover non-ready short-circuiting, READY-without-path rejection, regular-file and exact
  byte-count rules.
- `d02-recording-asset-loader.mjs` locks the FD validation and ownership contract. Static builds
  verify the platform API surface; real decoding/playback remains a device acceptance item.
