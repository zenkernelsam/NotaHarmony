# ADR-0302: Bind Library Note Create/Delete to Page Lifecycle

Date: 2026-08-23

## Context

`deleteNoteAndRefresh()` and `createAndOpen()` awaited durable note operations without checking page lifecycle afterward. If the user left the Library during SQLite work, stale continuations could still publish note snapshots, show failure toasts, schedule thumbnail refreshes, or navigate away from the disposed page to open a newly created note.

## Decision

Capture `lifecycleGeneration` at entry. After each await, require the same generation, `pageActive`, and matching viewModel before publishing state, showing UI, or navigating. Stale create/delete completions return immediately without touching memory state; the durable result remains authoritative.

## Consequences

Late note deletion cannot mutate a departed Library page or trigger thumbnail work. Late note creation cannot publish snapshots or push an editor route from a disposed page. The next activation loads authoritative data normally.
