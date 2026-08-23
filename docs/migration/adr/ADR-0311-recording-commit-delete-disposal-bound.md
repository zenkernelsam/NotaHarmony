# ADR-0311: Bind Recording Delete Commit to Editor Disposal

Date: 2026-08-23

## Context

`commitRecordingDeletes()` awaited `deleteVisible()` and then unconditionally refreshed recordings. If the editor was disposed while the delete transaction was in flight, the stale continuation could still drive `loadRecordings()` and publish snapshots against the disposed page.

## Decision

Check `editorDisposed` after the durable delete completes; skip the recording refresh for disposed editors. The durable deletion remains authoritative.

## Consequences

A late recording-delete commit cannot refresh a disposed editor's list or timeline. The next editor instance loads authoritative recordings normally.
