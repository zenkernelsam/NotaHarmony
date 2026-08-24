# ADR-0323: Library note move identity bound

- Date: 2026-08-24
- Status: Accepted
- Scope: Harmony library note-to-folder move publication

## Context

`moveNote()` captured only lifecycle generation and page activity before publishing a durable note move. It did not verify that the captured view model was still the current instance. A replaced library instance could therefore receive state mutation from the previous context.

## Decision

- Keep the established folder-mutation guard shape and explicitly add ViewModel identity:
  `lifecycleGeneration`, `pageActive`, and `viewModel === vm` must all hold.
- The current renderer is always non-null in the component; no separate renderer comparison is added.
- Durable movement remains authoritative. Stale successes return without view-model mutation, notes publication, or thumbnail refresh.
- Existing authoritative reload and request-generation guards remain unchanged for the current context.

## Consequences

A late successful move can no longer mutate the wrong library view model while preserving the source contract asserted by existing folder-mutation replay.