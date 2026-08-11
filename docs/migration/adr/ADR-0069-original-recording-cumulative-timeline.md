# ADR-0069: Reconstruct the original cumulative Recording timeline

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `hkb` computes each playable item's effective duration as `recordingEnd -
  recordingStart`; when segments are present it deliberately uses only the first segment's
  `end - start` instead. It still retains the complete resolved media URI.
- `vna.c(index)` sums all effective durations before `index`. `uw7.B(cumulativeTime)` selects the
  last index whose prefix duration is less than or equal to the requested time, then seeks that
  media item to `cumulativeTime - prefixDuration`. Exact boundaries therefore select the following
  item.
- `ni9` case 12 sums every item duration for the total. Case 13 builds `[0, d1, d1+d2, ..., total]`
  and drops the first and last values, proving that `boundaryTimes` contains internal transitions
  only.
- `vna.e` and `vna.e(...)` feed resolved media entries into one playlist. Failed URI conversion is
  omitted and explicitly logged as degraded seek accuracy, so unavailable Harmony assets must not
  contribute fabricated duration.

## Decision

- Add a pure `OriginalRecordingTimeline` projection over visible, locally READY recordings. Preserve
  source order, use only the first segment when present, expose internal cumulative boundaries and
  total duration, and skip entries whose uint64 duration cannot be represented safely by the player.
- Subtract decimal uint64 bounds digit by digit. Do not convert absolute timestamps to JavaScript
  numbers first, because values above `Number.MAX_SAFE_INTEGER` would lose duration precision.
- Resolve global seeks by scanning from the final entry backwards. This reproduces the original
  boundary rule, including duplicate zero-duration prefixes, and clamps the final total to the last
  item's end.
- Extend the single-player controller with a guarded initial local position. Apply it only after the
  AVPlayer reaches `prepared`, before optional autoplay, and convert synchronous seek failure into a
  FAILED snapshot rather than throwing from a media callback.
- Bind the editor slider and elapsed/total labels to cumulative values. A cross-item seek loads the
  located READY asset at its local offset and preserves whether playback was running. A completed
  non-final item loads and autoplays the next timeline entry; the final item remains completed.
- Route the visible Back control through the same `leaveEditor()` path as hardware Back so page/tool
  flushing and AVPlayer/FD release are not deferred solely to component teardown.

## Deferred

- Playback speed, recording capture, outbound delete/rename, waveform and audio-ink synchronization
  remain separate contracts. The cumulative boundary list is now available for audio-ink work, but
  this phase does not claim that consumer.
- Codec behavior, audio focus, output routing, completed-event timing and cross-item slider feel still
  require device acceptance.

## Verification

- ArkTS tests cover first-segment duration, internal boundaries, exact-boundary selection, final-end
  clamping and precision-preserving subtraction near uint64 max.
- Static replay covers cumulative UI wiring, prepared initial seek, cross-recording seek, automatic
  advance and the unified leave path.
