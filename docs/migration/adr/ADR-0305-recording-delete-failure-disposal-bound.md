# ADR-0305: Bind Recording Delete Failure Feedback to Editor Disposal

Date: 2026-08-23

## Context

The recording delete controller's failure listener always showed a toast. If a deferred delete failed after the editor was disposed, the stale callback still displayed UI against the removed page.

## Decision

Check `editorDisposed` after logging the delete failure and before showing the toast. Durable delete retry state remains owned by the controller.

## Consequences

A late recording-delete failure can no longer show feedback on a disposed editor. The controller continues to own pending-delete state; the next editor instance observes it through normal listeners.
