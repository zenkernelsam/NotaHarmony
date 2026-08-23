# ADR-0316: Bind Recording Delete Request to Editor Disposal

Date: 2026-08-23

## Context

`requestRecordingDelete()` could enqueue a pending delete and unload playback, and `undoRecordingDelete()` could cancel it, without checking whether the editor was still alive. Late UI callbacks after disposal could mutate controller state against the removed page.

## Decision

Check `editorDisposed` at both entries; disposed paths return without touching the delete controller or playback controller.

## Consequences

Late delete requests and undo actions cannot mutate controller state on a disposed editor. Pending-delete state remains authoritative in the controller; the next editor instance observes it through normal listeners.
