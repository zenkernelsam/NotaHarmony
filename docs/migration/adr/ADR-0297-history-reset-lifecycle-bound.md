# ADR-0297: Bind Persistent History Reset to Editor Lifecycle

Date: 2026-08-23

## Context

`resetPersistentHistory()` awaited SQLite before clearing the in-memory undo/redo stack and showing a completion or failure toast. If the editor was disposed during the await, the late success could still clear state on the detached component.

## Decision

After durable reset succeeds, require `lifecycleActive` before mutating undo/redo, recovery flags, or presenting UI. A disposed completion keeps the authoritative durable reset and only records an informational log. The existing finally block continues to release both busy gates.

## Consequences

A late reset can no longer mutate disposed UI state or show stale feedback. Durable history remains reset and consistent; a future healthy editor starts from that committed boundary.
