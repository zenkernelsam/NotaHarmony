# ADR-0320: Original Math commit stale context bound

- Date: 2026-08-24
- Status: Accepted
- Scope: Harmony editor Original Math insert and LaTeX edit completion

## Context

Both `confirmMathInsert()` and the LaTeX-edit branch of `confirmMathEditing()` awaited durable persistence before applying success effects. The existing context guard only protected part of the UI update; success callbacks could still push local undo history, close or mutate Math editor state, clear ineligibility bookkeeping, and publish an undo notification after page disposal or replacement.

## Decision

- Immediately after a durable Math transaction succeeds, require `isHistoryPageContextCurrent(generation, pageId)` before any editor-side effect.
- Stale successful transactions log that durable history remains available and return without clipboard/undo mutation, Math editor teardown, element-array updates, rendering, or notification.
- Failure publication remains current-context only, and `finally` still unconditionally resets `mathEditorBusy` and `historyBusy`.

## Consequences

A late durable Math result can no longer install history into the wrong editor instance. Durable data remains authoritative for the next page load. Busy flags cannot leak to another context because their reset stays unconditional.