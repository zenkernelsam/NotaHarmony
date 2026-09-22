# Harmony evidence — original recording presence indicator

Phase 559, 2026-09-22.

## Original evidence

`rej.a(jubVar, modifier, ...)` in `decompiled_1.0.3` renders the editor's
recording-presence badge:

- When the `jub` presence model is non-null, `rej.a` mounts a top-centered
  chip (`f0f.java:626` mounts it under the note surface with 24dp top
  padding, `is1.K` top-center alignment).
- The label is `feature_note__presence_recording` — "Recording in progress"
  — unless a collaborating user name is present, in which case
  `presence_recording_by_user` ("%1$s is recording") is used.
- The badge lives for the duration of the active recording session — the
  `jub` model is emitted while capture runs (including paused states).

## Harmony landing

`note/src/main/ets/ui/editor/NotePage.ets`: a compact badge in the top
navigation row (after the title, before the Recordings button) gated on

```ts
isOriginalRecordingCaptureActive(this.recordingSessionSnapshot.captureState)
```

which covers STARTING, RECORDING, PAUSING, PAUSED, RESUMING, STOPPING —
matching the original's session-lifetime visibility. The badge is a red
dot + "Recording in progress" text with an `accessibilityText` carrying
the same label.

## Strings

`presence_recording`: "Recording in progress" / "正在录音" (EN verbatim).

## Adaptations registered

- `presence_recording_by_user` ("%1$s is recording") is a collaboration
  feature — Harmony has no shared-presence model, so only the plain
  variant is ported.
- Mount point is the navigation row rather than a floating top-center
  overlay (Harmony's editor column has no overlay scaffold at that layer).
- The badge is informational only; the original's is likewise
  non-interactive.

## Verification

`d02-original-recording-presence-indicator.mjs` — 8 assertions: string
values, capture-active gating, badge contents, predicate coverage of
RECORDING+PAUSED, and absence of the collaboration variant.
