# ADR-0408: Recording list page-failure generation

## Status

Accepted (2026-08-25)

## Context

`loadRecordings()` owns a generation and guards both success publication and failure reset. `loadPages()` also calls `loadRecordings()` after loading note metadata, pages, and background. If that recording query rejects, control returns to the page-load catch. The page failure path then clears `pages`, sets `pageLoadFailed = true`, resets recordings, and rebuilds the timeline, but it did not invalidate the still-running recording generation.

If a second recording request starts before the first rejects, the older continuation can later pass its own guard against the unchanged `recordingLoadGeneration` and publish stale data over the page-failure projection.

## Decision

After the current-generation page-failure guard, increment `recordingLoadGeneration` before applying the failed editor projection. A stale or disposed page continuation still returns immediately; a current page failure invalidates every earlier recording load so only a request started afterward may publish.

## Consequences

Recording success/failure guards and same-generation loading cleanup remain authoritative. Page-failure recovery remains explicit, while late recording continuations can no longer overwrite it with stale snapshots.
