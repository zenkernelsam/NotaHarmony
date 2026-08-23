# ADR-0292: Bind Math Editor Lifecycle to Page Health

Date: 2026-08-23

## Context

Math insert/edit commits perform durable SQLite writes that can cross page navigation.
Success and failure paths used weak guards comparing only generation and page IDs.
Additionally, cancelMathEditing() early-returned during busy state, leaving the overlay
visible after page switch.

## Decision

1. Add detachMathEditorForNavigation() that unconditionally hides the editor, clears draft,
   preview, and editing references regardless of mathEditorBusy. Call it from
   cancelActiveInteraction() which fires on every page switch.

2. Replace all four guards in confirmMathEditing/confirmMathInsert with
   isHistoryPageContextCurrent(generation, pageId). Stale successes push durable undo history
   but skip local array/selection/render mutations and saveFailed reset. Stale failures log
   but do not set mathEditorFailed or call reportSaveFailure on the new page.

## Consequences

The Math overlay cannot persist across pages even when a commit is in-flight. Late results
cannot corrupt a freshly reloaded page. Durable undo entries remain available for the correct
page context. Device navigation stress testing is still required.
