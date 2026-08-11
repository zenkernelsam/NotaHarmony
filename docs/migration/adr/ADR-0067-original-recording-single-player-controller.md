# ADR-0067: Use one generation-guarded AVPlayer for Recording playback

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `vna` owns one lazily initialized ExoPlayer. `xpa/pna` consume player state,
  playback state, media transitions and errors; `uw7.E/F/G` implement play/pause and restart from
  time zero after the stopped/completed state.
- `uw7.B()` maps a cumulative note-audio time to a media item and an in-item offset. The original
  feeds a list of resolved recording URIs to ExoPlayer and explicitly warns if the media-item count
  diverges. Harmony AVPlayer has no equivalent playlist contract in the selected API surface, so
  cross-recording sequencing belongs above the single-player controller.
- Harmony AVPlayer accepts `fdSrc` only in `idle`, reports `initialized` asynchronously, permits
  `prepare()` only in `initialized`, and restricts play/pause/seek by state. `release()` is valid from
  every non-released state. ADR-0066 requires release before closing the descriptor lease.

## Decision

- Add `OriginalRecordingPlaybackController` as one AVPlayer/one Recording state machine. Setting
  `fdSrc` enters LOADING; the `initialized` callback prepares; `prepared` enters READY and optionally
  autoplays. playing/paused/completed/error and time/duration events publish immutable snapshots.
- Serialize load/play/pause/release mutations with the existing `AsyncMutex`. Every load and final
  release increments a generation; stale create/prepare/play and event callbacks cannot mutate the
  current snapshot. A superseded player is released before its asset lease is closed.
- Replaying from AVPlayer `completed` seeks to zero before play, matching original `uw7.G/D`.
  Seeks are accepted only in the SDK-supported states and clamped to a finite prepared duration.
- `release()` is terminal, unregisters callbacks, releases AVPlayer, then closes the FD lease. The
  NotePage integration must call it from page teardown before this feature becomes user-visible.
- Do not claim multi-recording automatic advance, cumulative timeline mapping, waveform/audio-ink
  sync, playback speed, codec success or UI in this phase.

## Verification

- ArkTS tests cover seek clamping and public state stability. Static replay locks callback
  registration, generation guards, completed restart, terminal release and player-before-FD order.
- Builds verify the Harmony media API contract. Audio decode and lifecycle behavior still require a
  device acceptance run.
