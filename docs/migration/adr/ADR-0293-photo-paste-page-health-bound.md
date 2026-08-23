# ADR-0293: Bind Photo Insert and Group Paste to Page Health

Date: 2026-08-23

## Context

insertOriginalPhotos() has a real await boundary via commitOriginalPhotoInsert(). Its success and catch paths used 2-line weak guards comparing only generation and page IDs without checking loaded, dataLoading, or dataLoadFailed. applyOriginalGroupClipboardPaste() had full health checks but as inline 3-line conditions instead of the shared predicate.

## Decision

Replace all five remaining weak guards with isHistoryPageContextCurrent(generation, pageId). Stale successes push durable undo history but skip local array/selection/render mutations and saveFailed reset. Stale failures log but do not call reportSaveFailure on the new page.

## Consequences

Late photo insert or group paste results cannot corrupt a freshly reloaded or unhealthy page. Durable undo entries remain available for the correct page context.
