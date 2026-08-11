# ADR-0078: Bind locally drawn ink to the original recording clock

## Status

Accepted, 2026-08-11.

## Evidence

- Original 1.0.3 `kt1.d()` calls `vcj.b(ckb, "ink.create")` when the first ink input creates the
  transient CREATE_INK operation, then passes that same value through `wq9.audioTime` and keeps it
  for subsequent ADD_PATH operations.
- `vcj.b()` returns the current recorder time only while the recorder is active and not paused.
  For the main recorder it is `wr8.startWallTime + wr8.e()`, where `wr8.e()` uses monotonic uptime
  and subtracts paused intervals.
- CREATE_INK supports nullable uint32 `audioDuration`, but the live `kt1 -> u5j.g` construction path
  passes `null` for that final parameter. The original commits the transient stroke at touch-up; it
  does not synthesize a wall-clock duration in this path.

## Decision

- Expose a synchronous `getCurrentAudioTime()` from capture and session controllers. Return decimal
  epoch milliseconds only while the original clock is available; return null while paused,
  resuming, idle, failed or released. Distinguish STOPPING-from-recording from STOPPING-from-paused.
- Compute audio time from the capture wall-clock start plus monotonic elapsed time after removing
  pauses. Reject unsafe JavaScript integer results instead of persisting rounded uint64 text.
- Let `NoteCanvasView` read the controller directly at touch-down. Do not use the periodically
  refreshed UI snapshot, because its 100 ms cadence would shift ink relative to audio.
- Store the captured value in `StrokeSession` so preview, final stroke, undo/redo snapshots and page
  persistence all retain the same immutable start. Leave `audioDuration` absent for locally drawn
  ink, matching the verified original live path.

## Rejected Alternatives

- Use the touch event timestamp: it is an input uptime value, not the recording's absolute audio
  timeline, and cannot be matched to persisted Recording segments.
- Derive audio time from `recordingSessionSnapshot.elapsedMs`: that snapshot is refreshed for UI
  display and can be stale at touch-down.
- Attach a stroke while paused and freeze its time: original `vcj.b()` returns null when paused, so
  such a stroke is deliberately not AudioLinked.
- Fill `audioDuration` from touch-down/touch-up wall time: although the wire field exists, the
  original live creation call passes null. Inventing it would change playback reveal behavior.

## Verification

- ArkTS tests cover start, monotonic advance, pause suppression, pause exclusion after resume,
  stop cleanup, session delegation and preservation through preview/final stroke data.
- `d02-recording-ink-clock.mjs` locks the original clock guards and construction chain as well as
  production page/canvas wiring and the absent local duration.
- Full replay and clean HAP results are recorded in the Phase 101 report. No device was started.

## Remaining Boundary

Device testing must still validate real recorder timestamps against playback callbacks and visible
ink reveal. Private CREATE_INK outbound serialization remains separate; current page snapshots
preserve the timing locally, but this phase does not claim private synchronization upload/ACK.
