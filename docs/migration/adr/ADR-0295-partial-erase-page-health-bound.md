# ADR-0295: Bind Partial Erase to Page Health

Date: 2026-08-23

## Context

commitOriginalPartialErase() has async persistence with .then/.catch/.finally. Three guards used inline health checks instead of the shared predicate.

## Decision

Replace all 3 guards (success install, UI failure reload, transaction failure fallback) with isHistoryPageContextCurrent().

## Consequences

Late partial erase results cannot corrupt a reloaded page. Durable undo entries remain available for the correct page context.
