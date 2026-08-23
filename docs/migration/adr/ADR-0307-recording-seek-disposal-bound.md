# ADR-0307: Bind Recording Timeline Seek to Editor Disposal

Date: 2026-08-23

## Context

`seekRecordingTimeline()` awaited `recordingController.load()` without checking whether the editor was still alive. A seek issued while the editor was being disposed could drive load on a released controller.

## Decision

Check `editorDisposed` at entry before locating the timeline target or touching the controller. The existing load await remains unchanged; disposal prevents any new seek or load.

## Consequences

A late seek cannot drive playback on a disposed editor. The released controller stays authoritative; a new editor instance starts with fresh state.
