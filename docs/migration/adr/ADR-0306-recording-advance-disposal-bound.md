# ADR-0306: Bind Recording Completion Advance to Editor Disposal

Date: 2026-08-23

## Context

`advanceAfterRecordingCompletion()` awaited `recordingController.load()` without checking whether the editor was still alive. If the editor was disposed while a recording finished playing, the stale continuation could drive load on a released controller and leave `completionAdvanceInFlight` stuck.

## Decision

Check `editorDisposed` at entry and reset `completionAdvanceInFlight` before returning. After the load await, reset the flag so future completion events can advance normally. Disposal prevents any new controller load.

## Consequences

A late completion cannot drive playback on a disposed editor or permanently wedge the advance flag. The released controller remains authoritative; a new editor instance starts with fresh state.
