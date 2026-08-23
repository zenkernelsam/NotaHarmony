# ADR-0310: Bind Recording Playback Snapshot to Editor Disposal

Date: 2026-08-23

## Context

`onRecordingPlaybackSnapshot()` unconditionally published playback state and could trigger completion advancement. A direct controller event after editor disposal could still mutate disposed page state or start the completion-advance path.

## Decision

Check `editorDisposed` at callback entry; disposed paths return without publishing snapshots or starting advancement. The released controller remains authoritative.

## Consequences

Late playback events cannot drive disposed recording UI. Completion advance is never started on a disposed editor; a new instance starts with fresh state.
