# ADR-0296: Bind Deferred Ink Refresh to Page Health

Date: 2026-08-23

## Context

Three deferred persistence continuations re-created the original ink reservation after only generation/pageId checks. Selection/CUT delete, partial erase `.finally()`, and ordinary paste flush could therefore run after lifecycle shutdown, a failed reload, or a same-page reload.

## Decision

Require `isHistoryPageContextCurrent()` before every deferred `refreshOriginalInkReservation()` call. Keep durable save state and history untouched; only skip the late UI-side reservation refresh when the originating page context is no longer healthy.

## Consequences

A stale flush cannot reserve original ink against a replaced page, failed load, or disposed canvas. Healthy completion still restores CREATE_INK eligibility normally.
