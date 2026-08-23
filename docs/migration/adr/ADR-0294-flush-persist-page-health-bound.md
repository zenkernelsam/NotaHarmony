# ADR-0294: Bind Flush and Persist to Page Health

Date: 2026-08-23

## Context

flushCurrentPage() awaits persistence.flush() which can cross page navigation. Its success path checked only generation/pageId/currentPage without loaded/dataLoading/dataLoadFailed. persist() uses .then() on flush with the same gap in its success path.

## Decision

Replace 4 guards across flushCurrentPage (success saveFailed + catch reportSaveFailure) and persist (success saveFailed + catch reportSaveFailure) with isHistoryPageContextCurrent(). Stale results skip local state mutations and feedback.

## Consequences

Late flush results cannot corrupt a reloaded page or misreport save status.
