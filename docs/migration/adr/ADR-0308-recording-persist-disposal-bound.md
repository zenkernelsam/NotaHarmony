# ADR-0308: Bind Recording Persist Refresh to Editor Disposal

Date: 2026-08-23

## Context

`persistCapturedRecording()` awaited the durable capture write and then unconditionally refreshed recordings. If the editor was disposed while the write was in flight, the stale continuation could still drive `loadRecordings()` and publish snapshots against the disposed page.

## Decision

Check `editorDisposed` after the durable persist completes; skip the recording refresh for disposed editors. The durable capture remains authoritative.

## Consequences

A late captured-recording save cannot refresh a disposed editor's list or timeline. The next editor instance loads authoritative recordings normally.
