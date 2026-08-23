# ADR-0288: Bind Deferred Editor Results To The Originating Page

## Status

Accepted (2026-08-23)

## Context

Phase 301–309 bounded clipboard probes, permission continuation, photo feedback, and Math save-clear
state to the page that started the work. A follow-up audit found four older deferred paths still
crossed page boundaries:

- generic persistence flushes cleared or reported `saveFailed` without capturing the load generation;
- selection delete/cut and ordinary Paste used only the persisted page id;
- Group/Ungroup promises could push history and replace current arrays after navigation;
- original Group Paste guarded UI installation but reported stale failures globally.

The original app persists `CREATE_GROUP` as op type 20 and exposes the active editor through a
current-page-index UI state. Therefore durable operations may survive navigation, but their local
history push, array replacement, rendering, and failure feedback must not leak into another page.

## Decision

Capture both `pageLoadGeneration` and the originating page id at every deferred editor boundary.
Success-side `saveFailed` clearing and failure-side reporting require the same generation/page and
the current loaded/current page context. Stale failures remain in hilog for diagnosis.

For Group/Ungroup, the SQLite transaction remains authoritative. When it finishes after a page
change, do not push into the visible undo stack or replace arrays; log that durable state and
persistent history remain available. Original Group Paste keeps its existing success guard but now
bounds failure feedback the same way.

`flushCurrentPage()` captures its context after text-commit enqueueing and before the awaited flush,
so an await crossing navigation cannot clear/report against the new page.

## Consequences

- New pages no longer inherit stale save failures or stale success clears.
- Stale Group/Ungroup results cannot corrupt the new page's arrays, selection, layer rebuild, or
  undo ordering.
- Durable writes and persistent history companions are unchanged; storage preflight/order checks
  continue to protect old pages.
- Runtime cross-page matrices still require device validation and are not claimed by this static
  change.
