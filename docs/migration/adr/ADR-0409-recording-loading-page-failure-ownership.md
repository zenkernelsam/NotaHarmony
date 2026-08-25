# ADR-0409: Recording loading page-failure ownership

## Status

Accepted (2026-08-25)

## Context

ADR-0408 advanced the recording generation when a current-generation page load failed, preventing a stale recording continuation from overwriting the failure projection. The same generation guard also controlled `recordingsLoading` cleanup in the old request's `finally`. After invalidation, that cleanup was skipped even though the page-failure path had not cleared the flag.

## Decision

The page-failure path explicitly clears `recordingsLoading` immediately after advancing the recording generation and before applying the failed editor projection. A stale recording request therefore has no state to publish or clean up; only requests started after page recovery may set loading again.

## Consequences

Same-generation loading cleanup remains authoritative inside `loadRecordings()`, while invalidated loads become inert. Page failure owns the loading handoff exactly once and cannot resurrect an old continuation.
