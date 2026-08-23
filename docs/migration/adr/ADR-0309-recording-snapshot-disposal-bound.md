# ADR-0309: Bind Recording Session Snapshot to Editor Disposal

Date: 2026-08-23

## Context

`onRecordingSessionSnapshot()` unconditionally published session state, failure dialogs, and timer rescheduling. A direct session event or a late 250 ms timer tick after editor disposal could still mutate disposed page state or show UI. The timer callback also rescheduled itself through this path, so disposal could leave one more tick alive.

## Decision

Check `editorDisposed` at snapshot entry and again inside the timer callback before reading the controller. Disposed paths return without publishing snapshots, showing failures, or rescheduling.

## Consequences

Direct events and deferred ticks cannot drive disposed recording UI. The timer loop cannot resurrect itself on a disposed page; the released controller remains authoritative.
