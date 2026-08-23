# ADR-0290: Bind Original Text Commits to the Loaded Page

Date: 2026-08-23

## Context

Styled original Text editing awaits `previewOriginalTextEdit()`. That persistence preview performs a
flush and can therefore cross a same-ID page reload or navigation. The existing checks compare object
identity, page ID, and loaded page ID, but a reload of the same page can preserve both IDs while
advancing `pageLoadGeneration` or entering an unhealthy load state.

Without a generation guard, the stale result could replace a text block in the freshly loaded arrays
and push a visible REPLACE_ELEMENT entry into the new page's undo history.

## Decision

Capture `pageLoadGeneration` before starting the styled original Text preview. After a successful
preview, retain the existing editing-object checks and require `isHistoryPageContextCurrent()`:
lifecycle active, same generation, same loaded/current page ID, data loaded, and no loading/load
failure state.

Stale results return `false`, log that the edit was rejected after the page changed, and never call
`replaceTextBlock()` or push undo history. Synchronous local-only Text branches remain unchanged
because they contain no await boundary.

## Consequences

A stale CRDT preview remains a durable database operation but cannot mutate visible text or history on
a reloaded page. The editor reports no success to the caller for that stale commit. Real fast-reload
behavior still requires device-level fault and navigation validation.
