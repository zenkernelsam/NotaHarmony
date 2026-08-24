# ADR-0319: Original Group Paste stale context bound

- Date: 2026-08-24
- Status: Accepted
- Scope: Harmony editor Original Group Paste completion callback

## Context

`applyOriginalGroupClipboardPaste()` captured the page generation/id and awaited a durable paste transaction. The success callback checked page context before installing UI, but still unconditionally committed the clipboard paste sequence, pushed local undo history, changed history bookkeeping, and published an undo notification. A disposed or switched page could therefore receive stale editor/history mutations even though durable data remained valid.

## Decision

- Check `isHistoryPageContextCurrent(generation, pageId)` before all success-side editor effects.
- Stale successful transactions log that durable history remains available and return without clipboard commit, undo push, history-revision update, UI install, or notification.
- Keep failure publication and `.finally()` behavior unchanged: failures only publish on current context, and `historyBusy` always resets.

## Consequences

A late Group Paste can no longer mutate a removed or replaced editor. Durable transaction state remains authoritative; the next page load observes persisted content. Clipboard sequence ownership stays with the current editor context only.
