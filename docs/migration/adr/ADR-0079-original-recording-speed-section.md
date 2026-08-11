# ADR-0079: Keep the original recording playback-speed section visible

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `n05.a()` renders the Recording list and then unconditionally renders the
  `feature_note_toolbox__playback_speed` heading followed by `n05.b(kpa.b, ...)`.
- `n05.b()` iterates the complete `wna` enum. `wna` contains only 1.0x, 1.5x and 2.0x, and does
  not depend on a selected Recording.
- The current Harmony panel placed all three speed buttons inside
  `snapshot.recordingId !== null`. A newly opened panel therefore hid the session-level speed
  preference until playback had already selected a Recording, contradicting both `n05` and the
  controller's verified idle/prepared speed semantics.

## Decision

- Render a dedicated playback control section on every Recording panel state.
- Keep only the cumulative seek timeline conditional on a selected Recording. Seeking without a
  loaded Recording remains unavailable.
- Add the original `Playback speed` heading and keep the exact 1x/1.5x/2x segmented choices.
- Increase the fixed panel height by the new persistent section height so the change does not take
  list space away from the previous layout.

## Rejected Alternatives

- Disable or hide speed while no Recording is selected: the original renders it unconditionally,
  and `OriginalRecordingPlaybackController` deliberately preserves an idle selection for the next
  prepared player.
- Show the timeline with no Recording: there is no duration or seek target, and the original
  evidence only establishes unconditional speed controls.
- Add unsupported speed values: the original `wna` enum and Harmony media mapping both expose the
  same three accepted modes.

## Verification

- `RecordingPanel.test.ets` locks that timeline visibility alone depends on a selected Recording.
- `d02-recording-speed-section.mjs` locks the original unconditional render order, heading,
  three-mode enum and Harmony placement.
- Full replay and clean HAP results are recorded in the Phase 102 report. No device was started.

## Remaining Boundary

Exact panel sizing and narrow-screen typography still require device inspection. The separate local
CREATE_INK outbound path must not be added until local pages and strokes share preallocated original
sequence/operation identities; appending payload bytes alone would create a second unrelated entity.
