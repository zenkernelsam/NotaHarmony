# ADR-0321: Partial erase and photo insert stale context bound

- Date: 2026-08-24
- Status: Accepted
- Scope: Harmony editor Original partial erase and batch photo insertion

## Context

`commitOriginalPartialErase()` and `insertOriginalPhotos()` awaited durable persistence before applying success effects. Their existing page-context guards only protected element installation. A late successful transaction could still push local undo history and publish undo notifications after the editor was disposed or the page had changed. Partial erase could also mutate preview bookkeeping on a stale context.

## Decision

- Require `isHistoryPageContextCurrent(generation, pageId)` immediately after each durable success before any editor-side effect.
- Stale partial-erase successes return without preview completion, undo push, UI installation, or notification.
- Stale photo successes return their committed count for ingress reporting without undo push, element-array mutation, rendering, or notification.
- Failure paths remain current-context-only for user-visible errors, while `finally` continues to reset busy/preview state unconditionally.

## Consequences

Late durable results can no longer install history into the wrong editor instance or notify stale observers. Durable data remains authoritative for the next page load. Ingress callers still observe how many durable images committed even when this editor context became stale.