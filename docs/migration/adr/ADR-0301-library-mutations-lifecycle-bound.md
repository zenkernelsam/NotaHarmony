# ADR-0301: Bind Library Folder Mutations to Page Lifecycle

Date: 2026-08-23

## Context

`onFolderDialogConfirm()`, `deleteFolder()`, `moveFolder()`, and `moveNote()` captured repositories before SQLite awaits but did not check page lifecycle afterward. A user could leave the Library while a mutation was in flight; the stale continuation then published folders or notes, reset current-folder selection, scheduled thumbnail work, or showed failure toasts against the disposed page.

## Decision

Capture `lifecycleGeneration` at each mutation entry. After durable completion, require the same generation, `pageActive`, and repository identity (where applicable) before publishing any state. Durable mutations remain committed; stale continuations skip all memory/UI publication. Failure toasts on disposed pages are also skipped.

## Consequences

Late folder create/rename/delete, folder reorder, note move, and their error feedback cannot mutate a departed Library page. The next activation starts a fresh lifecycle generation and loads authoritative data normally.
