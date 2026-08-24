# ADR-0322: Library backfill lifecycle bound

- Date: 2026-08-24
- Status: Accepted
- Scope: Harmony library initial search-index backfill continuation

## Context

After the initial library load completed, `initData()` started a best-effort search index backfill. Its success callback checked whether a search query was active, but not whether the page was still active on the same lifecycle generation with the same view model and renderer. A disposed or replaced page could therefore begin another notes request or publish notes state after teardown.

## Decision

- Check `isCurrentLifecycle(expectedLifecycleGeneration, vm, renderer)` at the backfill success entry.
- Stale backfill results return before starting a follow-up search refresh or publishing state.
- Existing request-generation checks continue to guard the follow-up refresh and its errors.

## Consequences

A late search index backfill can no longer drive UI work for an inactive or replaced library instance. The next activation starts its own lifecycle generation and reloads current data.