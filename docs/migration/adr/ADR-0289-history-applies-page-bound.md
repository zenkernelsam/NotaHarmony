# ADR-0289: Bind Deferred History Applies to the Originating Page

Date: 2026-08-23

## Context

Undo and Redo serialize through `historyBusy`, but page navigation is not blocked. An async history
apply can therefore cross `switchPageData()` while it awaits SQLite work. The affected paths are
original Group, clipboard Paste, partial erase, handwriting conversion, and generic grouped element
history.

A stale successful result could install arrays/groups, replace selection state, deselect, rebuild
layers, render, change original-ink eligibility, or refresh assets on the new page. A stale failure
could also raise global save-failure feedback there.

## Decision

Capture the page-load generation and originating page before the first await. Add one healthy-page
context predicate covering lifecycle, generation, loaded/current page identity, load success, and no
active loading/failure state.

Durable history remains note-global: a committed SQLite transaction still advances undo/redo and
notifies the stack. Page-local document/UI installation is suppressed when that context has changed.
Stale failures remain in hilog but do not call `reportSaveFailure()` or set `saveFailed`.

For generic groups, recheck after `flush()` before mutating local snapshots, after durable save, and
before rollback/render side effects. Rollback remains available for same-page failures only; a stale
failure never rolls back or installs into the new page.

## Consequences

The database operation remains authoritative without duplicating it across pages. Visible editor
state cannot be replaced by an older page context. Full behavioral proof still requires device-level
navigation and slow-I/O fault injection.
