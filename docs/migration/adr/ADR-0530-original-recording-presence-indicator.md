# ADR-0530 — Original recording presence indicator

- Status: accepted
- Date: 2026-09-22
- Phase: 559

## Context

The original editor surfaces a persistent "Recording in progress" badge
(`rej.a` / `feature_note__presence_recording`) for the whole capture
session — visible even when the recordings panel is closed. The Harmony
port tracked the same session state (`recordingSessionSnapshot`) but only
fed it to the `RecordingPanel`, leaving no ambient indicator.

## Decision

Add a nav-row badge gated on
`isOriginalRecordingCaptureActive(recordingSessionSnapshot.captureState)`
— a red dot + "Recording in progress" text — so the active session is
visible without opening the panel. The predicate's coverage
(STARTING/RECORDING/PAUSING/PAUSED/RESUMING/STOPPING) matches the
original's session-lifetime visibility.

## Consequences

- Capture state is ambient-visible during recording, matching original
  semantics.
- The collaboration variant (`presence_recording_by_user`) is not ported —
  no shared-presence model exists.
- Mount point differs (nav row vs floating top-center overlay) —
  registered layout adaptation.

## Verification

`d02-original-recording-presence-indicator.mjs` (8 assertions); full
Desktop Replay suite green; `note@default` and `note@ohosTest` builds
clean.
